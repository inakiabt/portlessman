import Foundation
import AppKit

public final class EditorManager: ObservableObject, @unchecked Sendable {
    public static let shared = EditorManager()

    private let defaultEditorKey = "portless.defaultEditorBundleId"

    @Published public private(set) var installedEditors: [EditorApp] = []
    @Published public var defaultEditorBundleId: String {
        didSet {
            UserDefaults.standard.set(defaultEditorBundleId, forKey: defaultEditorKey)
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: defaultEditorKey)
        self.defaultEditorBundleId = saved ?? "com.jetbrains.WebStorm"
        self.refreshInstalledEditors()

        // Fallback if the saved one is not installed
        if !installedEditors.contains(where: { $0.bundleId == self.defaultEditorBundleId }) {
            if let firstNonFinder = installedEditors.first(where: { $0.bundleId != "com.apple.finder" && !$0.isTerminal }) {
                self.defaultEditorBundleId = firstNonFinder.bundleId
            } else if let first = installedEditors.first {
                self.defaultEditorBundleId = first.bundleId
            }
        }
    }

    public func refreshInstalledEditors() {
        var detected: [EditorApp] = []
        for editor in EditorApp.knownEditors {
            if NSWorkspace.shared.urlForApplication(withBundleIdentifier: editor.bundleId) != nil {
                detected.append(editor)
            }
        }
        self.installedEditors = detected
    }

    public var defaultEditor: EditorApp? {
        installedEditors.first { $0.bundleId == defaultEditorBundleId } ?? installedEditors.first
    }

    public func openFolder(path: String, with editor: EditorApp? = nil) {
        guard !path.isEmpty else { return }
        let targetEditor = editor ?? defaultEditor
        let folderUrl = URL(fileURLWithPath: path)

        guard let targetEditor = targetEditor else {
            NSWorkspace.shared.open(folderUrl)
            return
        }

        if targetEditor.bundleId == "com.apple.finder" {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: folderUrl.path)
            return
        }

        guard let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: targetEditor.bundleId) else {
            NSWorkspace.shared.open(folderUrl)
            return
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.open([folderUrl], withApplicationAt: appUrl, configuration: config) { _, error in
            if let error = error {
                print("Failed to open \(path) with \(targetEditor.name): \(error.localizedDescription)")
                // Fallback to generic open
                NSWorkspace.shared.open(folderUrl)
            }
        }
    }
}
