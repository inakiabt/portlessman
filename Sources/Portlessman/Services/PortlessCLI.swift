import Foundation
import AppKit

public final class PortlessCLI: @unchecked Sendable {
    public static let shared = PortlessCLI()

    private var cachedBinaryPath: String?

    private init() {}

    public func binaryPath() -> String {
        if let cached = cachedBinaryPath, FileManager.default.isExecutableFile(atPath: cached) {
            return cached
        }

        let home = FileManager.default.homeDirectoryForCurrentUser.path

        // 1. Check known candidate paths directly via filesystem (instant, 0.001ms)
        let candidatePaths = [
            "/opt/homebrew/bin/portless",
            "/usr/local/bin/portless",
            "\(home)/.nvm/versions/node/v24.12.0/bin/portless"
        ]

        for path in candidatePaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                cachedBinaryPath = path
                return path
            }
        }

        // 2. Check dynamically in ~/.nvm/versions/node/*/bin/portless
        let nvmNodeDir = "\(home)/.nvm/versions/node"
        if let versions = try? FileManager.default.contentsOfDirectory(atPath: nvmNodeDir) {
            for v in versions.sorted().reversed() {
                let candidate = "\(nvmNodeDir)/\(v)/bin/portless"
                if FileManager.default.isExecutableFile(atPath: candidate) {
                    cachedBinaryPath = candidate
                    return candidate
                }
            }
        }

        // 3. Fallback: try finding via user's login shell
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

    @discardableResult
    public func executePrivileged(command: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let escapedCmd = command.replacingOccurrences(of: "\\", with: "\\\\")
                                        .replacingOccurrences(of: "\"", with: "\\\"")
                let scriptSource = "do shell script \"\(escapedCmd)\" with administrator privileges"

                var errorInfo: NSDictionary?
                if let script = NSAppleScript(source: scriptSource) {
                    let descriptor = script.executeAndReturnError(&errorInfo)
                    if let error = errorInfo {
                        let msg = error[NSAppleScript.errorMessage] as? String ?? "Authentication cancelled or failed"
                        continuation.resume(throwing: NSError(domain: "PrivilegedCommand", code: 1, userInfo: [NSLocalizedDescriptionKey: msg]))
                    } else {
                        continuation.resume(returning: descriptor.stringValue ?? "")
                    }
                } else {
                    continuation.resume(throwing: NSError(domain: "PrivilegedCommand", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize AppleScript"]))
                }
            }
        }
    }

    public func startProxy(lan: Bool = false, wildcard: Bool = false) async throws {
        var cmd = "\"\(binaryPath())\" proxy start"
        if lan { cmd += " --lan" }
        if wildcard { cmd += " --wildcard" }
        _ = try await execute(command: cmd)
    }

    public func stopProxy() async throws {
        let cmd = "\"\(binaryPath())\" proxy stop"
        _ = try await execute(command: cmd)
    }

    public func restartProxy(lan: Bool = false, wildcard: Bool = false) async throws {
        _ = try? await stopProxy()
        try await Task.sleep(nanoseconds: 500_000_000)
        try await startProxy(lan: lan, wildcard: wildcard)
    }

    public func addAlias(name: String, port: Int) async throws {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cmd = "\"\(binaryPath())\" alias \(cleanName) \(port)"
        let result = try await execute(command: cmd)
        if result.exitCode != 0 {
            throw NSError(domain: "PortlessCLI", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: result.stderr.isEmpty ? result.stdout : result.stderr])
        }
    }

    public func removeAlias(name: String) async throws {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cmd = "\"\(binaryPath())\" alias --remove \(cleanName)"
        let result = try await execute(command: cmd)
        if result.exitCode != 0 {
            throw NSError(domain: "PortlessCLI", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: result.stderr.isEmpty ? result.stdout : result.stderr])
        }
    }

    public func pruneOrphans() async throws -> String {
        let cmd = "\"\(binaryPath())\" prune"
        let result = try await execute(command: cmd)
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func syncHosts() async throws {
        let bin = binaryPath()
        do {
            let res = try await execute(command: "\"\(bin)\" hosts sync")
            if res.exitCode != 0 {
                // Try privileged
                _ = try await executePrivileged(command: "\(bin) hosts sync")
            }
        } catch {
            _ = try await executePrivileged(command: "\(bin) hosts sync")
        }
    }

    public func trustCA() async throws {
        let bin = binaryPath()
        do {
            let res = try await execute(command: "\"\(bin)\" trust")
            if res.exitCode != 0 {
                // Try privileged
                _ = try await executePrivileged(command: "\(bin) trust")
            }
        } catch {
            _ = try await executePrivileged(command: "\(bin) trust")
        }
    }

    public func runDoctor() async throws -> DoctorReport {
        let cmd = "\"\(binaryPath())\" doctor"
        let result = try await execute(command: cmd)
        return parseDoctorOutput(result.stdout)
    }

    public func getServiceStatus() async throws -> (isInstalled: Bool, output: String) {
        let cmd = "\"\(binaryPath())\" service status"
        let result = try await execute(command: cmd)
        let text = result.stdout
        let installed = text.contains("Installed: yes") || text.contains("Manager state: running")
        return (installed, text)
    }

    public func installService(lan: Bool = false, wildcard: Bool = false) async throws {
        var subArgs = "service install"
        if lan { subArgs += " --lan" }
        if wildcard { subArgs += " --wildcard" }
        let bin = binaryPath()

        // Service installation writes to /Library/LaunchDaemons, requiring root elevation
        _ = try await executePrivileged(command: "\(bin) \(subArgs)")
    }

    public func uninstallService() async throws {
        let bin = binaryPath()
        _ = try await executePrivileged(command: "\(bin) service uninstall")
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
