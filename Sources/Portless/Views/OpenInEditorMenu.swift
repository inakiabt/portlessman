import SwiftUI
import AppKit

struct OpenInEditorMenu: View {
    let path: String
    @ObservedObject private var editorManager = EditorManager.shared

    var body: some View {
        Menu {
            if let defaultEditor = editorManager.defaultEditor {
                Button {
                    editorManager.openFolder(path: path, with: defaultEditor)
                } label: {
                    Label("Open in \(defaultEditor.name) (Default)", systemImage: defaultEditor.iconSystemName)
                }

                Divider()
            }

            ForEach(editorManager.installedEditors) { editor in
                if editor.bundleId != editorManager.defaultEditor?.bundleId {
                    Button {
                        editorManager.openFolder(path: path, with: editor)
                    } label: {
                        Label(editor.name, systemImage: editor.iconSystemName)
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
            HStack(spacing: 3) {
                Image(systemName: "folder")
                    .font(.system(size: 10))
                Text(editorManager.defaultEditor?.name ?? "Editor")
                    .font(.system(size: 11, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.primary.opacity(0.06))
            .cornerRadius(4)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Open project folder in editor")
    }
}
