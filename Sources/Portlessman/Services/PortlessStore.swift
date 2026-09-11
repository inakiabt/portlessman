import Foundation
import Combine
import AppKit
import Darwin

@MainActor
public final class PortlessStore: ObservableObject {
    public static let shared = PortlessStore()

    @Published public var routes: [PortlessRoute] = []
    @Published public var proxyStatus: ProxyStatus = ProxyStatus()
    @Published public var searchQuery: String = ""
    @Published public var isBusy: Bool = false
    @Published public var statusMessage: String? = nil

    private let stateDir: URL
    private let routesFile: URL
    private let proxyPidFile: URL
    private let proxyPortFile: URL
    private let proxyTlsFile: URL
    private let proxyLanFile: URL
    private let proxyLogFile: URL

    private var watcher: PortlessWatcher?
    private var statusMessageTimer: Timer?

    public init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.stateDir = home.appendingPathComponent(".portless")
        self.routesFile = stateDir.appendingPathComponent("routes.json")
        self.proxyPidFile = stateDir.appendingPathComponent("proxy.pid")
        self.proxyPortFile = stateDir.appendingPathComponent("proxy.port")
        self.proxyTlsFile = stateDir.appendingPathComponent("proxy.tls")
        self.proxyLanFile = stateDir.appendingPathComponent("proxy.lan")
        self.proxyLogFile = stateDir.appendingPathComponent("proxy.log")

        self.reload()

        self.watcher = PortlessWatcher { [weak self] in
            Task { @MainActor [weak self] in
                self?.reload()
            }
        }
    }

    public var filteredRoutes: [PortlessRoute] {
        if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            return routes
        }
        let query = searchQuery.lowercased()
        return routes.filter {
            $0.hostname.lowercased().contains(query) ||
            $0.projectName.lowercased().contains(query) ||
            String($0.port).contains(query) ||
            ($0.cwd?.lowercased().contains(query) ?? false)
        }
    }

    public var activeAppRoutes: [PortlessRoute] {
        filteredRoutes.filter { !$0.isStaticAlias }
    }

    public var staticAliases: [PortlessRoute] {
        filteredRoutes.filter { $0.isStaticAlias }
    }

    public func setStatus(_ msg: String) {
        statusMessage = msg
        statusMessageTimer?.invalidate()
        statusMessageTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.statusMessage = nil
            }
        }
    }

    public func reload() {
        let entries = loadRawRouteEntries()
        let port = readProxyPort()
        let isTLS = readProxyTLS()
        let scheme = isTLS ? "https" : "http"

        let activePids = Set(entries.map(\.pid).filter { $0 > 0 })
        ProcessManager.shared.purgeStalePids(activePids)

        // 1. Initial mapping using cached cwds
        var initialRoutes: [PortlessRoute] = []
        var pidsToResolve: [Int] = []

        for entry in entries {
            let url: String
            if port == 443 || port == 80 {
                url = "\(scheme)://\(entry.hostname)"
            } else {
                url = "\(scheme)://\(entry.hostname):\(port)"
            }

            let cachedCwd = ProcessManager.shared.resolveCwd(forPid: entry.pid)
            if cachedCwd == nil && entry.pid > 0 {
                pidsToResolve.append(entry.pid)
            }

            initialRoutes.append(
                PortlessRoute(
                    hostname: entry.hostname,
                    port: entry.port,
                    pid: entry.pid,
                    url: url,
                    tailscaleUrl: entry.tailscaleUrl,
                    ngrokUrl: entry.ngrokUrl,
                    cwd: cachedCwd
                )
            )
        }

        self.routes = initialRoutes.sorted { $0.hostname < $1.hostname }

        // 2. Check proxy state via PID and socket
        let pid = readProxyPid()
        let isPidAlive = pid != nil && ProcessManager.shared.isAlive(pid: pid!)
        let isPortAlive = checkPortResponding(port: port)
        let isProxyRunning = isPortAlive || isPidAlive

        self.proxyStatus = ProxyStatus(
            isRunning: isProxyRunning,
            port: port,
            pid: pid,
            isTLS: isTLS,
            isLAN: FileManager.default.fileExists(atPath: proxyLanFile.path)
        )

        // 3. Resolve any uncached cwds in the background
        if !pidsToResolve.isEmpty {
            ProcessManager.shared.resolveCwdAsync(forPids: pidsToResolve) { [weak self] resolvedMap in
                Task { @MainActor [weak self] in
                    guard let self = self, !resolvedMap.isEmpty else { return }
                    self.routes = self.routes.map { r in
                        if let newCwd = resolvedMap[r.pid] {
                            var updated = r
                            updated.cwd = newCwd
                            updated.projectName = URL(fileURLWithPath: newCwd).lastPathComponent
                            return updated
                        }
                        return r
                    }
                }
            }
        }
    }

    private func checkPortResponding(port: Int, host: String = "127.0.0.1") -> Bool {
        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_STREAM
        var res: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, "\(port)", &hints, &res) == 0, let info = res else { return false }
        defer { freeaddrinfo(res) }

        let sock = socket(info.pointee.ai_family, info.pointee.ai_socktype, info.pointee.ai_protocol)
        guard sock >= 0 else { return false }
        defer { close(sock) }

        // Set non-blocking socket
        let flags = fcntl(sock, F_GETFL, 0)
        _ = fcntl(sock, F_SETFL, flags | O_NONBLOCK)

        let connRes = connect(sock, info.pointee.ai_addr, info.pointee.ai_addrlen)
        if connRes == 0 {
            return true
        }

        if errno == EINPROGRESS {
            var pollFd = pollfd(fd: sock, events: Int16(POLLOUT), revents: 0)
            let pollRes = poll(&pollFd, 1, 60) // 60ms timeout maximum
            if pollRes > 0 && (pollFd.revents & Int16(POLLOUT)) != 0 {
                var err: Int32 = 0
                var errLen = socklen_t(MemoryLayout<Int32>.size)
                if getsockopt(sock, SOL_SOCKET, SO_ERROR, &err, &errLen) == 0 && err == 0 {
                    return true
                }
            }
        }

        return false
    }

    private func loadRawRouteEntries() -> [RouteEntry] {
        guard let data = try? Data(contentsOf: routesFile),
              let entries = try? JSONDecoder().decode([RouteEntry].self, from: data)
        else { return [] }
        return entries
    }

    private func readProxyPid() -> Int? {
        guard let str = try? String(contentsOf: proxyPidFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
              let pid = Int(str)
        else { return nil }
        return pid
    }

    private func readProxyPort() -> Int {
        guard let str = try? String(contentsOf: proxyPortFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
              let port = Int(str)
        else { return 443 }
        return port
    }

    private func readProxyTLS() -> Bool {
        if FileManager.default.fileExists(atPath: proxyTlsFile.path) {
            let str = (try? String(contentsOf: proxyTlsFile, encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines)
            return str == "1"
        }
        return true
    }

    // MARK: - Proxy Actions

    public func toggleProxy() {
        Task {
            isBusy = true
            defer { isBusy = false }

            do {
                if proxyStatus.isRunning {
                    try await PortlessCLI.shared.stopProxy()
                    setStatus("Stopped Portless proxy")
                } else {
                    try await PortlessCLI.shared.startProxy()
                    setStatus("Started Portless proxy")
                }
                try await Task.sleep(nanoseconds: 600_000_000)
                reload()
            } catch {
                setStatus("Proxy error: \(error.localizedDescription)")
            }
        }
    }

    public func restartProxy() {
        Task {
            isBusy = true
            defer { isBusy = false }
            do {
                try await PortlessCLI.shared.restartProxy()
                reload()
                setStatus("Restarted proxy")
            } catch {
                setStatus("Restart failed: \(error.localizedDescription)")
            }
        }
    }

    public func pruneOrphans() {
        Task {
            isBusy = true
            defer { isBusy = false }
            do {
                let msg = try await PortlessCLI.shared.pruneOrphans()
                reload()
                setStatus(msg.isEmpty ? "Pruned stale routes" : msg)
            } catch {
                setStatus("Prune failed: \(error.localizedDescription)")
            }
        }
    }

    public func killProcess(for route: PortlessRoute) {
        guard route.pid > 0 else { return }
        let killed = ProcessManager.shared.killProcess(pid: route.pid)
        if killed {
            setStatus("Stopped process for \(route.hostname)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.reload()
            }
        } else {
            setStatus("Could not kill PID \(route.pidString) (Permission denied)")
        }
    }

    public func addAlias(name: String, port: Int) async throws {
        try await PortlessCLI.shared.addAlias(name: name, port: port)
        try await Task.sleep(nanoseconds: 300_000_000)
        reload()
        setStatus("Added alias \(name) -> :\(port)")
    }

    public func removeAlias(name: String) async throws {
        try await PortlessCLI.shared.removeAlias(name: name)
        try await Task.sleep(nanoseconds: 300_000_000)
        reload()
        setStatus("Removed alias \(name)")
    }

    public func getProxyLogs(maxLines: Int = 150) -> String {
        guard let data = try? Data(contentsOf: proxyLogFile),
              let fullText = String(data: data, encoding: .utf8)
        else { return "No logs found at \(proxyLogFile.path)" }

        let lines = fullText.components(separatedBy: "\n")
        let slice = lines.suffix(maxLines)
        return slice.joined(separator: "\n")
    }
}
