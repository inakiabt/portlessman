import Foundation
import Combine
import AppKit

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
            Task { @MainActor in
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

    public func reload() {
        let entries = loadRawRouteEntries()
        let port = readProxyPort()
        let isTLS = readProxyTLS()
        let scheme = isTLS ? "https" : "http"

        let activePids = Set(entries.map(\.pid).filter { $0 > 0 })
        ProcessManager.shared.purgeStalePids(activePids)

        self.routes = entries.map { entry in
            let url: String
            if port == 443 || port == 80 {
                url = "\(scheme)://\(entry.hostname)"
            } else {
                url = "\(scheme)://\(entry.hostname):\(port)"
            }

            let cwd = ProcessManager.shared.resolveCwd(forPid: entry.pid)
            return PortlessRoute(
                hostname: entry.hostname,
                port: entry.port,
                pid: entry.pid,
                url: url,
                tailscaleUrl: entry.tailscaleUrl,
                ngrokUrl: entry.ngrokUrl,
                cwd: cwd
            )
        }.sorted { $0.hostname < $1.hostname }

        let pid = readProxyPid()
        let isAlive = pid != nil && ProcessManager.shared.isAlive(pid: pid!)

        self.proxyStatus = ProxyStatus(
            isRunning: isAlive,
            port: port,
            pid: pid,
            isTLS: isTLS,
            isLAN: FileManager.default.fileExists(atPath: proxyLanFile.path)
        )
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
                } else {
                    try await PortlessCLI.shared.startProxy()
                }
                try await Task.sleep(nanoseconds: 500_000_000)
                reload()
            } catch {
                statusMessage = "Proxy error: \(error.localizedDescription)"
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
            } catch {
                statusMessage = "Restart failed: \(error.localizedDescription)"
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
                statusMessage = msg.isEmpty ? "Pruned stale routes" : msg
            } catch {
                statusMessage = "Prune failed: \(error.localizedDescription)"
            }
        }
    }

    public func killProcess(for route: PortlessRoute) {
        guard route.pid > 0 else { return }
        let killed = ProcessManager.shared.killProcess(pid: route.pid)
        if killed {
            statusMessage = "Stopped process for \(route.hostname)"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.reload()
            }
        }
    }

    public func addAlias(name: String, port: Int) async throws {
        try await PortlessCLI.shared.addAlias(name: name, port: port)
        try await Task.sleep(nanoseconds: 300_000_000)
        reload()
    }

    public func removeAlias(name: String) async throws {
        try await PortlessCLI.shared.removeAlias(name: name)
        try await Task.sleep(nanoseconds: 300_000_000)
        reload()
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
