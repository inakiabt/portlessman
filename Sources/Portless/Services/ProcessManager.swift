import Foundation
import Darwin

public final class ProcessManager: @unchecked Sendable {
    public static let shared = ProcessManager()
    private var cwdCache: [Int: String] = [:]
    private let queue = DispatchQueue(label: "sh.portless.process-manager", qos: .userInitiated)

    private init() {}

    public func resolveCwd(forPid pid: Int) -> String? {
        guard pid > 0 else { return nil }
        
        return queue.sync {
            if let cached = cwdCache[pid] {
                return cached
            }

            let path = queryLsof(pid: pid)
            if let path = path {
                cwdCache[pid] = path
            }
            return path
        }
    }

    public func resolveCwdAsync(forPids pids: [Int], completion: @escaping @Sendable ([Int: String]) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            var results: [Int: String] = [:]
            for pid in pids where pid > 0 {
                if let cached = self.cwdCache[pid] {
                    results[pid] = cached
                } else if let resolved = self.queryLsof(pid: pid) {
                    self.cwdCache[pid] = resolved
                    results[pid] = resolved
                }
            }
            completion(results)
        }
    }

    private func queryLsof(pid: Int) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        task.arguments = ["-a", "-p", "\(pid)", "-d", "cwd", "-Fn"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return nil }

            for line in output.components(separatedBy: "\n") {
                if line.hasPrefix("n/") {
                    return String(line.dropFirst())
                }
            }
        } catch {
            return nil
        }
        return nil
    }

    public func purgeStalePids(_ activePids: Set<Int>) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.cwdCache = self.cwdCache.filter { activePids.contains($0.key) }
        }
    }

    public func killProcess(pid: Int, force: Bool = false) -> Bool {
        guard pid > 0 else { return false }
        let signal = force ? SIGKILL : SIGTERM
        let res = kill(Int32(pid), signal)
        if res == 0 || errno == EPERM {
            queue.async { [weak self] in
                self?.cwdCache.removeValue(forKey: pid)
            }
            return true
        }
        return false
    }

    public func isAlive(pid: Int) -> Bool {
        guard pid > 0 else { return false }
        let ret = kill(Int32(pid), 0)
        if ret == 0 { return true }
        return errno == EPERM
    }
}
