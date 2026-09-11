import SwiftUI
import AppKit

struct RouteDetailView: View {
    let route: PortlessRoute
    @ObservedObject var store: PortlessStore
    @ObservedObject private var editorManager = EditorManager.shared
    let onBack: () -> Void

    @State private var copiedUrlFeedback: Bool = false
    @State private var copiedPathFeedback: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Navigation Bar
            HStack {
                Button {
                    onBack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)

                Spacer()

                Text("Route Details")
                    .font(.system(size: 13, weight: .bold))

                Spacer()

                Text("Back")
                    .font(.system(size: 12))
                    .opacity(0)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 2)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header Card: Hostname & URL
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top, spacing: 6) {
                            Circle()
                                .fill(route.isAlive ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)
                                .padding(.top, 3)

                            Text(route.hostname)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer()

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
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.accentColor.opacity(0.12))
                                .foregroundStyle(Color.accentColor)
                                .cornerRadius(5)
                            }
                            .buttonStyle(.plain)
                        }

                        HStack {
                            Text(route.url)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)

                            Spacer()

                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(route.url, forType: .string)
                                copiedUrlFeedback = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                    copiedUrlFeedback = false
                                }
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: copiedUrlFeedback ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 9))
                                    Text(copiedUrlFeedback ? "Copied" : "Copy")
                                        .font(.system(size: 10))
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.primary.opacity(0.06))
                                .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(8)

                    // Server & Process Info
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SERVER & PROCESS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)

                        VStack(spacing: 4) {
                            detailRow(label: "Target Port", value: "localhost:\(route.port)")

                            if route.pid > 0 {
                                detailRow(label: "Process PID", value: "\(route.pid) (\(route.isAlive ? "Running" : "Stale"))")
                            }

                            detailRow(label: "Protocol", value: "HTTP/2 over TLS (HTTPS)")

                            if let ts = route.tailscaleUrl, !ts.isEmpty {
                                detailRow(label: "Tailscale", value: ts)
                            }
                            if let ng = route.ngrokUrl, !ng.isEmpty {
                                detailRow(label: "ngrok", value: ng)
                            }
                        }
                    }

                    // Project Location (Folder)
                    if let cwd = route.cwd, !cwd.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("PROJECT LOCATION")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Button {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(cwd, forType: .string)
                                    copiedPathFeedback = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        copiedPathFeedback = false
                                    }
                                } label: {
                                    HStack(spacing: 3) {
                                        Image(systemName: copiedPathFeedback ? "checkmark" : "doc.on.doc")
                                            .font(.system(size: 9))
                                        Text(copiedPathFeedback ? "Copied" : "Copy Path")
                                            .font(.system(size: 10))
                                    }
                                    .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }

                            Text(cwd)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.primary)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.primary.opacity(0.04))
                                .cornerRadius(6)
                                .textSelection(.enabled)

                            // Quick Editor Buttons
                            HStack(spacing: 6) {
                                ForEach(editorManager.installedEditors.prefix(4)) { editor in
                                    Button {
                                        editorManager.openFolder(path: cwd, with: editor)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: editor.iconSystemName)
                                                .font(.system(size: 10))
                                            Text(editor.name)
                                                .font(.system(size: 11))
                                        }
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(Color.primary.opacity(0.06))
                                        .cornerRadius(4)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Process Actions (Kill Server)
                    if route.pid > 0 {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("PROCESS ACTIONS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.secondary)

                            Button {
                                store.killProcess(for: route)
                                onBack()
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "stop.circle.fill")
                                        .font(.system(size: 11))
                                    Text("Terminate Process (PID \(route.pid))")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.09))
                                .foregroundStyle(Color.red)
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
            }
        }
        .padding(.bottom, 6)
        .frame(width: 380, height: route.cwd != nil ? 490 : 360)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.primary.opacity(0.02))
        .cornerRadius(4)
    }
}
