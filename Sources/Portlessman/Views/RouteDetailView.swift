import SwiftUI
import AppKit

struct RouteDetailView: View {
    let route: PortlessRoute
    @ObservedObject var store: PortlessStore
    let onBack: () -> Void

    @ObservedObject private var editorManager = EditorManager.shared
    @State private var copiedUrlFeedback = false
    @State private var copiedPathFeedback = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header bar
            HStack(spacing: 8) {
                Button {
                    onBack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Route Details")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()

                // Spacer to balance the back button
                Color.clear
                    .frame(width: 44, height: 16)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // Content Container with ScrollView to prevent any window clipping
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    // Header Card: Hostname & URL Actions
                    VStack(alignment: .leading, spacing: 8) {
                        // Row 1: Status dot + Full width Hostname
                        HStack(alignment: .center, spacing: 7) {
                            Circle()
                                .fill(route.isAlive ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)

                            Text(route.hostname)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .textSelection(.enabled)

                            Spacer(minLength: 0)
                        }

                        // Row 2: Monospaced URL + Action Buttons (Copy & Open)
                        HStack(spacing: 8) {
                            Text(route.url)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .textSelection(.enabled)

                            Spacer(minLength: 4)

                            HStack(spacing: 4) {
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
                                    .padding(.vertical, 3)
                                    .background(Color.primary.opacity(0.06))
                                    .cornerRadius(4)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    if let url = URL(string: route.url) {
                                        NSWorkspace.shared.open(url)
                                    }
                                } label: {
                                    HStack(spacing: 3) {
                                        Image(systemName: "globe")
                                            .font(.system(size: 10))
                                        Text("Open")
                                            .font(.system(size: 10, weight: .semibold))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.blue)
                                    .foregroundStyle(.white)
                                    .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                            }
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
                                detailRow(label: "Process PID", value: "\(route.pidString) (\(route.isAlive ? "Running" : "Stale"))")
                            }

                            detailRow(label: "Protocol", value: "HTTPS (HTTP/2)")

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

                            // Full-width path box
                            Text(cwd)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .textSelection(.enabled)
                                .help(cwd)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.primary.opacity(0.04))
                                .cornerRadius(6)

                            // Editor Selector Button on its own line below path
                            HStack {
                                OpenInEditorMenu(path: cwd)
                                Spacer()
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
                                    Text("Terminate Process (PID \(route.pidString))")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
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
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 520)
        }
        .padding(.bottom, 6)
        .frame(width: 390)
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
