import Foundation

public struct DoctorItem: Identifiable, Hashable, Sendable {
    public enum Level: String, Sendable {
        case ok
        case warn
        case fail
        case info
    }

    public var id: String { message }
    public let level: Level
    public let message: String

    public init(level: Level, message: String) {
        self.level = level
        self.message = message
    }
}

public struct DoctorReport: Sendable {
    public let version: String?
    public let nodeVersion: String?
    public let platform: String?
    public let stateDir: String?
    public let proxyTarget: String?
    public let mode: String?
    public let items: [DoctorItem]
    public let summary: String?

    public init(
        version: String? = nil,
        nodeVersion: String? = nil,
        platform: String? = nil,
        stateDir: String? = nil,
        proxyTarget: String? = nil,
        mode: String? = nil,
        items: [DoctorItem] = [],
        summary: String? = nil
    ) {
        self.version = version
        self.nodeVersion = nodeVersion
        self.platform = platform
        self.stateDir = stateDir
        self.proxyTarget = proxyTarget
        self.mode = mode
        self.items = items
        self.summary = summary
    }
}
