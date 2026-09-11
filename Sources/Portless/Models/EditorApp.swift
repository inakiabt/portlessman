import Foundation
import AppKit

public struct EditorApp: Identifiable, Hashable, Sendable {
    public var id: String { bundleId }
    public let bundleId: String
    public let name: String
    public let iconSystemName: String
    public let isTerminal: Bool

    public static let knownEditors: [EditorApp] = [
        EditorApp(bundleId: "com.apple.finder", name: "Finder", iconSystemName: "folder", isTerminal: false),
        EditorApp(bundleId: "com.jetbrains.WebStorm", name: "WebStorm", iconSystemName: "brain.head.profile", isTerminal: false),
        EditorApp(bundleId: "com.microsoft.VSCode", name: "Visual Studio Code", iconSystemName: "chevron.left.forwardslash.chevron.right", isTerminal: false),
        EditorApp(bundleId: "com.microsoft.VSCodeInsiders", name: "VS Code Insiders", iconSystemName: "chevron.left.forwardslash.chevron.right", isTerminal: false),
        EditorApp(bundleId: "com.todesktop.230313mzl4w4u92", name: "Cursor", iconSystemName: "cursorarrow.rays", isTerminal: false),
        EditorApp(bundleId: "dev.zed.Zed", name: "Zed", iconSystemName: "character.cursor.ibeam", isTerminal: false),
        EditorApp(bundleId: "com.sublimetext.4", name: "Sublime Text", iconSystemName: "command", isTerminal: false),
        EditorApp(bundleId: "com.jetbrains.intellij", name: "IntelliJ IDEA", iconSystemName: "cube", isTerminal: false),
        EditorApp(bundleId: "com.jetbrains.intellij.ce", name: "IntelliJ IDEA CE", iconSystemName: "cube", isTerminal: false),
        EditorApp(bundleId: "com.mitchellh.ghostty", name: "Ghostty", iconSystemName: "terminal", isTerminal: true),
        EditorApp(bundleId: "com.googlecode.iterm2", name: "iTerm2", iconSystemName: "terminal", isTerminal: true),
        EditorApp(bundleId: "dev.warp.Warp-Stable", name: "Warp", iconSystemName: "terminal", isTerminal: true),
        EditorApp(bundleId: "com.apple.Terminal", name: "Terminal", iconSystemName: "terminal", isTerminal: true)
    ]
}
