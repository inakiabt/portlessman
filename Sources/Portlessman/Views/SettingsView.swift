import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: PortlessStore
    @ObservedObject private var editorManager = EditorManager.shared
    let onBack: () -> Void

    @State private var isServiceInstalled: Bool = false
    @State private var isLANMode: Bool = false
    @State private var isBusy: Bool = false
    @State private var feedbackMessage: String? = nil

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
                    .padding(.vertical, 4)
                    .padding(.trailing, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)

                Spacer()

                HStack(spacing: 5) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                    Text("Preferences")
                        .font(.system(size: 13, weight: .bold))
                }

                Spacer()

                // Balance space with invisible text
                Text("Back")
                    .font(.system(size: 12))
                    .opacity(0)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 4)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // Section: Editor
                    VStack(alignment: .leading, spacing: 5) {
                        Text("DEFAULT PROJECT EDITOR")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)

                        Picker("Editor", selection: $editorManager.defaultEditorBundleId) {
                            ForEach(editorManager.installedEditors) { editor in
                                Text(editor.name).tag(editor.bundleId)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)

                        Text("Clicking the editor button on a route opens this app.")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }

                    Divider()

                    // Section: Proxy Service
                    VStack(alignment: .leading, spacing: 6) {
                        Text("STARTUP & SERVICE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)

                        Toggle("Start proxy automatically on macOS boot", isOn: $isServiceInstalled)
                            .onChange(of: isServiceInstalled) { _, newValue in
                                toggleService(install: newValue)
                            }
                            .font(.system(size: 12))
                            .disabled(isBusy)

                        Text("Installs a LaunchDaemon in /Library/LaunchDaemons/sh.portless.proxy.plist")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }

                    Divider()

                    // Section: Network & Security
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NETWORK & SYSTEM")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)

                        Toggle("LAN Mode (mDNS .local for testing on mobile)", isOn: $isLANMode)
                            .onChange(of: isLANMode) { _, newValue in
                                toggleLAN(enabled: newValue)
                            }
                            .font(.system(size: 12))
                            .disabled(isBusy)

                        HStack(spacing: 8) {
                            Button("Sync /etc/hosts") {
                                runHostsSync()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(isBusy)
                            .help("Adds routes to /etc/hosts (fixes Safari resolution)")

                            Button("Trust Local CA") {
                                runTrustCA()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(isBusy)
                            .help("Adds local Portless CA to Keychain trust store")
                        }
                    }

                    if let msg = feedbackMessage {
                        Text(msg)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.blue)
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
            }
            .frame(height: 280)
        }
        .padding(.bottom, 10)
        .onAppear {
            self.isLANMode = store.proxyStatus.isLAN
            checkServiceStatus()
        }
    }

    private func checkServiceStatus() {
        Task {
            if let status = try? await PortlessCLI.shared.getServiceStatus() {
                self.isServiceInstalled = status.isInstalled
            }
        }
    }

    private func toggleService(install: Bool) {
        guard !isBusy else { return }
        isBusy = true
        Task {
            do {
                if install {
                    try await PortlessCLI.shared.installService(lan: isLANMode)
                    feedbackMessage = "Installed LaunchDaemon service"
                } else {
                    try await PortlessCLI.shared.uninstallService()
                    feedbackMessage = "Uninstalled LaunchDaemon service"
                }
            } catch {
                feedbackMessage = "Service error: \(error.localizedDescription)"
                // Revert state if failed
                self.isServiceInstalled = !install
            }
            isBusy = false
            checkServiceStatus()
        }
    }

    private func toggleLAN(enabled: Bool) {
        guard !isBusy else { return }
        isBusy = true
        Task {
            do {
                try await PortlessCLI.shared.restartProxy(lan: enabled)
                feedbackMessage = enabled ? "Restarted with LAN mode" : "Restarted without LAN mode"
                store.reload()
            } catch {
                feedbackMessage = "LAN error: \(error.localizedDescription)"
                self.isLANMode = !enabled
            }
            isBusy = false
        }
    }

    private func runHostsSync() {
        guard !isBusy else { return }
        isBusy = true
        Task {
            do {
                try await PortlessCLI.shared.syncHosts()
                feedbackMessage = "Synced /etc/hosts successfully"
            } catch {
                feedbackMessage = "Sync failed: \(error.localizedDescription)"
            }
            isBusy = false
        }
    }

    private func runTrustCA() {
        guard !isBusy else { return }
        isBusy = true
        Task {
            do {
                try await PortlessCLI.shared.trustCA()
                feedbackMessage = "Trust CA completed"
            } catch {
                feedbackMessage = "Trust failed: \(error.localizedDescription)"
            }
            isBusy = false
        }
    }
}
