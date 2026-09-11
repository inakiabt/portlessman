import SwiftUI
import AppKit

struct RouteRowView: View {
    let route: PortlessRoute
    @ObservedObject var store: PortlessStore
    let onSelect: () -> Void
    @State private var isHovered = false
    @State private var copiedFeedback = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Top Row: Status Dot, Hostname, and Drill-down Chevron
            HStack(spacing: 6) {
                Circle()
                    .fill(route.isAlive ? Color.green : Color.orange)
                    .frame(width: 7, height: 7)

                Text(route.hostname)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }

            // Bottom Row: Primary Actions (Open, Editor, Copy URL) + Clickable empty area
            HStack(spacing: 6) {
                // Open in Browser
                Button {
                    if let url = URL(string: route.url) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "globe")
                            .font(.system(size: 10))
                        Text("Open")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Color.primary.opacity(0.06))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Open in default browser")

                // Open in Editor (Split Button: 1-click default, arrow for picker)
                if let cwd = route.cwd, !cwd.isEmpty {
                    OpenInEditorMenu(path: cwd)
                }

                // Copy URL
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(route.url, forType: .string)
                    copiedFeedback = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        copiedFeedback = false
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: copiedFeedback ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 10))
                            .foregroundStyle(copiedFeedback ? Color.green : Color.primary)
                        Text(copiedFeedback ? "Copied" : "URL")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Color.primary.opacity(0.06))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Copy URL to clipboard")

                // Empty space in button bar also opens the detail
                Spacer(minLength: 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect()
                    }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(isHovered ? Color.primary.opacity(0.05) : Color.primary.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal, 14)
        .padding(.vertical, 2)
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("View Details") {
                onSelect()
            }
            Divider()
            Button("Open in Browser") {
                if let url = URL(string: route.url) {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Copy URL") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(route.url, forType: .string)
            }
            Button("Copy Hostname") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(route.hostname, forType: .string)
            }
            if let cwd = route.cwd, !cwd.isEmpty {
                Divider()
                Button("Reveal in Finder") {
                    EditorManager.shared.openFolder(path: cwd, with: EditorApp.knownEditors.first)
                }
                Button("Copy Path") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(cwd, forType: .string)
                }
            }
            if route.pid > 0 {
                Divider()
                Button("Terminate Process (PID \(route.pid))", role: .destructive) {
                    store.killProcess(for: route)
                }
            }
        }
    }
}
