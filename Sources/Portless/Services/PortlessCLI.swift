import Foundation

public final class PortlessCLI: @unchecked Sendable {
    public static let shared = PortlessCLI()

    private var cachedBinaryPath: String?

    private init() {}

    public func binaryPath() -> String {
        if let cached = cachedBinaryPath, FileManager.default.isExecutableFile(atPath: cached) {
            return cached
        }

        // 1. Try finding via user's login shell
        let shellTask = Process()
        shellTask.executableURL = URL(fileURLWithPath: "/bin/zsh")
        shellTask.arguments = ["-l", "-c", "which portless"]
        let pipe = Pipe()
        shellTask.standardOutput = pipe
        shellTask.standardError = FileHandle.nullDevice

        if (try? shellTask.run()) != nil {
            shellTask.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !output.isEmpty,
               FileManager.default.isExecutableFile(atPath: output) {
                cachedBinaryPath = output
                return output
            }
        }

        // 2. Check standard locations
        let candidatePaths = [
            "/opt/homebrew/bin/portless",
            "/usr/local/bin/portless",
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".nvm/versions/node/v24.12.0/bin/portless").path
        ]

        for path in candidatePaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                cachedBinaryPath = path
                return path
            }
        }

        return "portless"
    }

    @discardableResult
    public func execute(command: String) async throws -> (stdout: String, stderr: String, exitCode: Int32) {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/bin/zsh")
                task.arguments = ["-l", "-c", command]

                let outPipe = Pipe()
                let errPipe = Pipe()
                task.standardOutput = outPipe
                task.standardError = errPipe

                do {
                    try task.run()
                    task.waitUntilExit()

                    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
                    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()

                    let stdout = String(data: outData, encoding: .utf8) ?? ""
                    let stderr = String(data: errData, encoding: .utf8) ?? ""

                    continuation.resume(returning: (stdout, stderr, task.terminationStatus))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func startProxy(lan: Bool = false, wildcard: Bool = false) async throws {
        var cmd = "\(binaryPath()) proxy start"
        if lan { cmd += " --lan" }
        if wildcard { cmd += " --wildcard" }
        _ = try await execute(command: cmd)
    }

    public func stopProxy() async throws {
        let cmd = "\(binaryPath()) proxy stop"
        _ = try await execute(command: cmd)
    }

    public func restartProxy(lan: Bool = false, wildcard: Bool = false) async throws {
        _ = try? await stopProxy()
        try await Task.sleep(nanoseconds: 500_000_000)
        try await startProxy(lan: lan, wildcard: wildcard)
    }

    public func addAlias(name: String, port: Int) async throws {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cmd = "\(binaryPath()) alias \(cleanName) \(port)"
        let result = try await execute(command: cmd)
        if result.exitCode != 0 {
            throw NSError(domain: "PortlessCLI", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: result.stderr.isEmpty ? result.stdout : result.stderr])
        }
    }

    public func removeAlias(name: String) async throws {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cmd = "\(binaryPath()) alias --remove \(cleanName)"
        let result = try await execute(command: cmd)
        if result.exitCode != 0 {
            throw NSError(domain: "PortlessCLI", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: result.stderr.isEmpty ? result.stdout : result.stderr])
        }
    }

    public func pruneOrphans() async throws -> String {
        let cmd = "\(binaryPath()) prune"
        let result = try await execute(command: cmd)
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func syncHosts() async throws {
        let cmd = "\(binaryPath()) hosts sync"
        _ = try await execute(command: cmd)
    }

    public func trustCA() async throws {
        let cmd = "\(binaryPath()) trust"
        _ = try await execute(command: cmd)
    }

    public func runDoctor() async throws -> DoctorReport {
        let cmd = "\(binaryPath()) doctor"
        let result = try await execute(command: cmd)
        return parseDoctorOutput(result.stdout)
    }

    public func getServiceStatus() async throws -> (isInstalled: Bool, output: String) {
        let cmd = "\(binaryPath()) service status"
        let result = try await execute(command: cmd)
        let text = result.stdout
        let installed = text.contains("Installed: yes") || text.contains("Manager state: running")
        return (installed, text)
    }

    public func installService(lan: Bool = false, wildcard: Bool = false) async throws {
        var cmd = "\(binaryPath()) service install"
        if lan { cmd += " --lan" }
        if wildcard { cmd += " --wildcard" }
        _ = try await execute(command: cmd)
    }

    public func uninstallService() async throws {
        let cmd = "\(binaryPath()) service uninstall"
        _ = try await execute(command: cmd)
    }

    private func parseDoctorOutput(_ output: String) -> DoctorReport {
        var version: String?
        var nodeVersion: String?
        var platform: String?
        var stateDir: String?
        var proxyTarget: String?
        var mode: String?
        var items: [DoctorItem] = []
        var summary: String?

        let lines = output.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            if trimmed.hasPrefix("Version: ") {
                version = String(trimmed.dropFirst("Version: ".count))
            } else if trimmed.hasPrefix("Node.js: ") {
                nodeVersion = String(trimmed.dropFirst("Node.js: ".count))
            } else if trimmed.hasPrefix("Platform: ") {
                platform = String(trimmed.dropFirst("Platform: ".count))
            } else if trimmed.hasPrefix("State dir: ") {
                stateDir = String(trimmed.dropFirst("State dir: ".count))
            } else if trimmed.hasPrefix("Proxy target: ") {
                proxyTarget = String(trimmed.dropFirst("Proxy target: ".count))
            } else if trimmed.hasPrefix("Mode: ") {
                mode = String(trimmed.dropFirst("Mode: ".count))
            } else if trimmed.hasPrefix("ok ") {
                let msg = String(trimmed.dropFirst("ok ".count)).trimmingCharacters(in: .whitespaces)
                items.append(DoctorItem(level: .ok, message: msg))
            } else if trimmed.hasPrefix("warn ") {
                let msg = String(trimmed.dropFirst("warn ".count)).trimmingCharacters(in: .whitespaces)
                items.append(DoctorItem(level: .warn, message: msg))
            } else if trimmed.hasPrefix("fail ") {
                let msg = String(trimmed.dropFirst("fail ".count)).trimmingCharacters(in: .whitespaces)
                items.append(DoctorItem(level: .fail, message: msg))
            } else if trimmed.hasPrefix("Summary: ") {
                summary = trimmed
            }
        }

        return DoctorReport(
            version: version,
            nodeVersion: nodeVersion,
            platform: platform,
            stateDir: stateDir,
            proxyTarget: proxyTarget,
            mode: mode,
            items: items,
            summary: summary
        )
    }
}
