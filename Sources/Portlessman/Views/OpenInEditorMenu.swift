import SwiftUI
import AppKit

struct OpenInEditorMenu: View {
    let path: String
    @ObservedObject private var editorManager = EditorManager.shared
    @State private var isButtonHovered = false
    @State private var isMenuHovered = false

    private var currentEditor: EditorApp? {
        editorManager.defaultEditor
    }

    var body: some View {
        HStack(spacing: 0) {
            // 1. Direct Single-Click Action: Open in Default Editor
            Button {
                if let editor = currentEditor {
                    editorManager.openFolder(path: path, with: editor)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: currentEditor?.iconSystemName ?? "folder")
                        .font(.system(size: 10))
                    Text(currentEditor?.name ?? "Editor")
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3.5)
                .background(isButtonHovered ? Color.primary.opacity(0.10) : Color.clear)
            }
            .buttonStyle(.plain)
            .onHover { isButtonHovered = $0 }
            .help("Open in \(currentEditor?.name ?? "default editor")")

            // Subtle vertical separator
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(width: 1, height: 13)

            // 2. Attached Dropdown Selector: Choose Editor or Change Default
            Menu {
                Section("Open With") {
                    ForEach(editorManager.installedEditors) { editor in
                        Button {
                            editorManager.openFolder(path: path, with: editor)
                        } label: {
                            HStack {
                                Text(editor.name)
                                if editor.bundleId == currentEditor?.bundleId {
                                    Text("✓ (Default)")
                                }
                            }
                        }
                    }
                }

                Divider()

                Menu("Set Default Editor") {
                    ForEach(editorManager.installedEditors.filter { !$0.isTerminal }) { editor in
                        Button(editor.name) {
                            editorManager.defaultEditorBundleId = editor.bundleId
                        }
                    }
                }

                Divider()

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(path, forType: .string)
                } label: {
                    Label("Copy Folder Path", systemImage: "doc.on.doc")
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 4.5)
                    .background(isMenuHovered ? Color.primary.opacity(0.10) : Color.clear)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .onHover { isMenuHovered = $0 }
            .help("Choose editor or change default")
        }
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}
