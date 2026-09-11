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
        openDirectoryWatch()

        // 2. Watch routes.json directly for modifications
        rearmFileWatch()

        // 3. Fallback heartbeat every 3 seconds to guarantee freshness
        if Thread.isMainThread {
            self.pollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
                self?.pollTick()
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.pollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
                    self?.pollTick()
                }
            }
        }
    }

    private func pollTick() {
        // If directory watch was not opened (e.g. folder did not exist yet), try to open it
        if dirSource == nil {
            openDirectoryWatch()
        }
        if fileSource == nil && FileManager.default.fileExists(atPath: routesFile.path) {
            rearmFileWatch()
        }
        onChange()
    }

    private func openDirectoryWatch() {
        guard dirSource == nil else { return }
        guard FileManager.default.fileExists(atPath: stateDir.path) else { return }

        let fd = open(stateDir.path, O_EVTONLY)
        guard fd >= 0 else { return }
        self.dirFd = fd

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .link, .rename, .revoke],
            queue: .main
        )
        src.setEventHandler { [weak self] in
            self?.scheduleTrigger()
            self?.rearmFileWatch()
        }
        src.setCancelHandler { [fd] in
            close(fd)
        }
        src.resume()
        self.dirSource = src
    }

    private func rearmFileWatch() {
        if let existing = fileSource {
            fileSource = nil
            existing.cancel() // cancel handler will close the associated fd
        }
        fileFd = -1

        guard FileManager.default.fileExists(atPath: routesFile.path) else { return }

        let fd = open(routesFile.path, O_EVTONLY)
        guard fd >= 0 else { return }
        self.fileFd = fd

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .extend, .attrib],
            queue: .main
        )
        src.setEventHandler { [weak self] in
            self?.scheduleTrigger()
        }
        src.setCancelHandler { [fd] in
            close(fd)
        }
        src.resume()
        self.fileSource = src
    }

    private func scheduleTrigger() {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            self?.onChange()
        }
    }

    public func stopWatching() {
        if Thread.isMainThread {
            debounceTimer?.invalidate()
            debounceTimer = nil
            pollTimer?.invalidate()
            pollTimer = nil
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.debounceTimer?.invalidate()
                self?.debounceTimer = nil
                self?.pollTimer?.invalidate()
                self?.pollTimer = nil
            }
        }

        if let d = dirSource {
            dirSource = nil
            d.cancel()
        }
        dirFd = -1

        if let f = fileSource {
            fileSource = nil
            f.cancel()
        }
        fileFd = -1
    }
}
