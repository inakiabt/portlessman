import Foundation

public struct ProxyStatus: Equatable, Sendable {
    public var isRunning: Bool
    public var port: Int
    public var pid: Int?
    public var isTLS: Bool
    public var isLAN: Bool
    public var lanIP: String?
    public var tld: String
    public var isServiceInstalled: Bool
    public var statusDescription: String {
        if !isRunning {
            return "Stopped"
        }
        var parts: [String] = ["\(port)"]
        if isTLS {
            parts.append("HTTPS")
        } else {
            parts.append("HTTP")
        }
        if isLAN {
            parts.append("LAN")
        }
        return parts.joined(separator: " • ")
    }

    public init(
        isRunning: Bool = false,
        port: Int = 443,
        pid: Int? = nil,
        isTLS: Bool = true,
        isLAN: Bool = false,
        lanIP: String? = nil,
        tld: String = "localhost",
        isServiceInstalled: Bool = false
    ) {
        self.isRunning = isRunning
        self.port = port
        self.pid = pid
        self.isTLS = isTLS
        self.isLAN = isLAN
        self.lanIP = lanIP
        self.tld = tld
        self.isServiceInstalled = isServiceInstalled
    }
}
