import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: PortlessStore
    @ObservedObject private var editorManager = EditorManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isServiceInstalled: Bool = false
    @State private var isLANMode: Bool = false
    @State private var isBusy: Bool = false
    @State private var feedbackMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Settings", systemImage: "gearshape")
                    .font(.headline)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                // Section: Editor
                VStack(alignment: .leading, spacing: 4) {
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

                    Text("Clicking the editor button on a route will open the project in this app.")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }

                Divider()

                // Section: Proxy Service
                VStack(alignment: .leading, spacing: 8) {
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
                        .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .frame(width: 360)
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
            }
            isBusy = false
            checkServiceStatus()
        }
    }

    private func toggleLAN(enabled: Bool) {
        isBusy = true
        Task {
            do {
                try await PortlessCLI.shared.restartProxy(lan: enabled)
                feedbackMessage = enabled ? "Restarted with LAN mode" : "Restarted without LAN mode"
                store.reload()
            } catch {
                feedbackMessage = "LAN error: \(error.localizedDescription)"
            }
            isBusy = false
        }
    }

    private func runHostsSync() {
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
