import SwiftUI
import AppKit

enum ActiveTab: Equatable {
    case main
    case doctor
    case logs
    case settings
    case routeDetail(PortlessRoute)
}

struct MenuContentView: View {
    @ObservedObject var store = PortlessStore.shared
    @State private var activeTab: ActiveTab = .main

    var body: some View {
        Group {
            switch activeTab {
            case .main:
                mainView
                    .frame(width: 360)
            case .doctor:
                DoctorModalView(onBack: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        activeTab = .main
                    }
                })
                .frame(width: 360)
            case .logs:
                LogsModalView(store: store, onBack: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        activeTab = .main
                    }
                })
                .frame(width: 360)
            case .settings:
                SettingsView(store: store, onBack: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        activeTab = .main
                    }
                })
                .frame(width: 360)
            case .routeDetail(let route):
                RouteDetailView(route: route, store: store, onBack: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        activeTab = .main
                    }
                })
                .frame(width: 380)
            }
        }
        .background(
            Group {
                Button("") {
                    store.reload()
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("") {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        activeTab = (activeTab == .settings) ? .main : .settings
                    }
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            .opacity(0)
        )
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            activeTab = .main
        }
    }

    private var mainView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HeaderView(store: store) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    activeTab = .settings
                }
            }

            // Status feedback banner (if any)
            if let msg = store.statusMessage {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.blue)
                    Text(msg)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.08))
                .transition(.opacity)
            }

            Divider()

            // Active Routes (with tap to drill down into detail)
            RouteListView(store: store) { selectedRoute in
                withAnimation(.easeInOut(duration: 0.15)) {
                    activeTab = .routeDetail(selectedRoute)
                }
            }

            Divider()
                .padding(.horizontal, 14)
                .padding(.top, 4)

            // Static Aliases
            AliasSectionView(store: store)

            Divider()
                .padding(.top, 6)

            // Navigation & Footer
            VStack(alignment: .leading, spacing: 1) {
                // Doctor Button
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        activeTab = .doctor
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "stethoscope")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text("Health Check (Doctor)")
                            .font(.system(size: 12))
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Proxy Logs Button
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        activeTab = .logs
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.plaintext")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text("View Proxy Logs")
                            .font(.system(size: 12))
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.vertical, 2)

                // Preferences & Quit
                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            activeTab = .settings
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 11))
                            Text("Preferences...")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Text("Quit")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
            }
            .padding(.top, 2)
            .background(Color.primary.opacity(0.02))
        }
    }
}
