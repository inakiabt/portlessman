import SwiftUI

struct HeaderView: View {
    @ObservedObject var store: PortlessStore
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(store.proxyStatus.isRunning ? Color.yellow : Color.secondary)

                    Text("Portlessman")
                        .font(.system(size: 15, weight: .bold))
                }

                Spacer()

                Button {
                    onOpenSettings()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                }
                .buttonStyle(HeaderIconButtonStyle())
                .help("Preferences...")
            }

            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(store.proxyStatus.isRunning ? Color.green : Color.secondary.opacity(0.6))
                        .frame(width: 8, height: 8)

                    Text("Proxy: \(store.proxyStatus.isRunning ? "Running (\(store.proxyStatus.statusDescription))" : "Stopped")")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    store.toggleProxy()
                } label: {
                    if store.isBusy {
                        ProgressView()
                            .controlSize(.mini)
                            .frame(width: 44)
                    } else {
                        Text(store.proxyStatus.isRunning ? "Stop" : "Start")
                            .font(.system(size: 11, weight: .medium))
                            .frame(minWidth: 44)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(store.isBusy)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
