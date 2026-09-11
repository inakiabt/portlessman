import SwiftUI
import AppKit

struct MenuContentView: View {
    @ObservedObject var store = PortlessStore.shared
    @State private var showingDoctor = false
    @State private var showingLogs = false
    @State private var showingSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HeaderView(store: store) {
                showingSettings = true
            }

            Divider()

            // Scrollable Content
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // Active Routes Section
                    RouteListView(store: store)

                    Divider()
                        .padding(.horizontal, 14)

                    // Static Aliases Section
                    AliasSectionView(store: store)
                }
                .padding(.vertical, 6)
            }
            .frame(maxHeight: 380)

            Divider()

            // Footer Actions
            VStack(alignment: .leading, spacing: 3) {
                // Doctor Button
                Button {
                    showingDoctor = true
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
                    .padding(.vertical, 5)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Proxy Logs Button
                Button {
                    showingLogs = true
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
                    .padding(.vertical, 5)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.vertical, 2)

                // Preferences and Quit
                HStack {
                    Button {
                        showingSettings = true
                    } label: {
                        HStack(spacing: 5) {
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
            .padding(.top, 4)
            .background(Color.primary.opacity(0.02))
        }
        .frame(width: 360)
        .sheet(isPresented: $showingDoctor) {
            DoctorModalView()
        }
        .sheet(isPresented: $showingLogs) {
            LogsModalView(store: store)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(store: store)
        }
    }
}
