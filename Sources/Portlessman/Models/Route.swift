import Foundation

public struct RouteEntry: Codable, Sendable {
    public let hostname: String
    public let port: Int
    public let pid: Int
    public let tailscaleUrl: String?
    public let ngrokUrl: String?

    public init(hostname: String, port: Int, pid: Int, tailscaleUrl: String? = nil, ngrokUrl: String? = nil) {
        self.hostname = hostname
        self.port = port
        self.pid = pid
        self.tailscaleUrl = tailscaleUrl
        self.ngrokUrl = ngrokUrl
    }
}

public struct PortlessRoute: Identifiable, Hashable, Sendable {
    public var id: String { hostname }
    public let hostname: String
    public let port: Int
    public let pid: Int
    public let url: String
    public let tailscaleUrl: String?
    public let ngrokUrl: String?
    public var cwd: String?
    public var projectName: String

    public var isAlive: Bool {
        guard pid > 0 else { return false }
        return ProcessManager.shared.isAlive(pid: pid)
    }

    public var isStaticAlias: Bool {
        pid <= 0
    }

    public var displayCwd: String {
        guard let cwd = cwd, !cwd.isEmpty else { return "" }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if cwd.hasPrefix(home) {
            return "~" + cwd.dropFirst(home.count)
        }
        return cwd
    }

    public init(
        hostname: String,
        port: Int,
        pid: Int,
        url: String,
        tailscaleUrl: String? = nil,
        ngrokUrl: String? = nil,
        cwd: String? = nil,
        projectName: String? = nil
    ) {
        self.hostname = hostname
        self.port = port
        self.pid = pid
        self.url = url
        self.tailscaleUrl = tailscaleUrl
        self.ngrokUrl = ngrokUrl
        self.cwd = cwd
        if let projectName = projectName, !projectName.isEmpty {
            self.projectName = projectName
        } else if let cwd = cwd, !cwd.isEmpty {
            self.projectName = URL(fileURLWithPath: cwd).lastPathComponent
        } else {
            self.projectName = hostname.components(separatedBy: ".").first ?? hostname
        }
    }
}
