import SwiftUI
import AppKit

struct RouteRowView: View {
    let route: PortlessRoute
    @ObservedObject var store: PortlessStore
    @State private var isHovered = false
    @State private var copiedFeedback = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Title and Status
            HStack(spacing: 6) {
                Circle()
                    .fill(route.isAlive ? Color.green : Color.orange)
                    .frame(width: 7, height: 7)

                Text(route.hostname)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                if let tailscale = route.tailscaleUrl, !tailscale.isEmpty {
                    Text("Tailscale")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.blue.opacity(0.15))
                        .foregroundStyle(Color.blue)
                        .cornerRadius(3)
                }

                if let ngrok = route.ngrokUrl, !ngrok.isEmpty {
                    Text("ngrok")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.purple.opacity(0.15))
                        .foregroundStyle(Color.purple)
                        .cornerRadius(3)
                }
            }

            // Target Port & PID
            HStack(spacing: 6) {
                Text("localhost:\(String(route.port))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)

                if route.pid > 0 {
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)

                    Text("PID \(route.pid)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            // Folder path (if detected)
            if !route.displayCwd.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "folder")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)

                    Text(route.displayCwd)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            // Action Buttons
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
                    .padding(.vertical, 3)
                    .background(Color.primary.opacity(0.06))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Open in default browser")

                // Open in Editor (if directory exists)
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
                    .padding(.vertical, 3)
                    .background(Color.primary.opacity(0.06))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Copy URL to clipboard")

                Spacer()

                // Kill process
                if route.pid > 0 {
                    Button {
                        store.killProcess(for: route)
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "stop.circle")
                                .font(.system(size: 10))
                            Text("Kill")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.red.opacity(0.08))
                        .foregroundStyle(Color.red)
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .help("Terminate process (PID \(route.pid))")
                }
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.primary.opacity(0.04) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
        .onHover { isHovered = $0 }
        .contextMenu {
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
