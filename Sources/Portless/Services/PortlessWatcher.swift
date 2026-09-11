import Foundation

public final class PortlessWatcher: @unchecked Sendable {
    private let stateDir: URL
    private let routesFile: URL
    private var dirSource: DispatchSourceFileSystemObject?
    private var fileSource: DispatchSourceFileSystemObject?
    private var dirFd: Int32 = -1
    private var fileFd: Int32 = -1
    private var debounceTimer: Timer?
    private var pollTimer: Timer?
    private let onChange: @Sendable () -> Void

    public init(onChange: @escaping @Sendable () -> Void) {
        self.onChange = onChange
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.stateDir = home.appendingPathComponent(".portless")
        self.routesFile = stateDir.appendingPathComponent("routes.json")
        startWatching()
    }

    deinit {
        stopWatching()
    }

    public func startWatching() {
        stopWatching()

        // 1. Watch directory for file creations/deletions/renames
        dirFd = open(stateDir.path, O_EVTONLY)
        if dirFd >= 0 {
            let src = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: dirFd,
                eventMask: [.write, .link, .rename, .revoke],
                queue: .main
            )
            src.setEventHandler { [weak self] in
                self?.scheduleTrigger()
                // Re-arm file watch if needed
                self?.rearmFileWatch()
            }
            src.resume()
            self.dirSource = src
        }

        // 2. Watch routes.json directly for modifications
        rearmFileWatch()

        // 3. Fallback heartbeat every 3 seconds to guarantee freshness
        DispatchQueue.main.async { [weak self] in
            self?.pollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                self?.onChange()
            }
        }
    }

    private func rearmFileWatch() {
        fileSource?.cancel()
        if fileFd >= 0 {
            close(fileFd)
            fileFd = -1
        }

        if FileManager.default.fileExists(atPath: routesFile.path) {
            fileFd = open(routesFile.path, O_EVTONLY)
            if fileFd >= 0 {
                let src = DispatchSource.makeFileSystemObjectSource(
                    fileDescriptor: fileFd,
                    eventMask: [.write, .delete, .rename, .extend, .attrib],
                    queue: .main
                )
                src.setEventHandler { [weak self] in
                    self?.scheduleTrigger()
                }
                src.setCancelHandler { [weak self] in
                    if let fd = self?.fileFd, fd >= 0 {
                        close(fd)
                        self?.fileFd = -1
                    }
                }
                src.resume()
                self.fileSource = src
            }
        }
    }

    private func scheduleTrigger() {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            self?.onChange()
        }
    }

    public func stopWatching() {
        dirSource?.cancel()
        fileSource?.cancel()
        if dirFd >= 0 { close(dirFd); dirFd = -1 }
        if fileFd >= 0 { close(fileFd); fileFd = -1 }
        debounceTimer?.invalidate()
        pollTimer?.invalidate()
    }
}
