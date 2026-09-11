import SwiftUI

struct RouteListView: View {
    @ObservedObject var store: PortlessStore
    let onSelectRoute: (PortlessRoute) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Section Header
            HStack {
                Text("ACTIVE ROUTES (\(store.activeAppRoutes.count))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    store.pruneOrphans()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "trash")
                            .font(.system(size: 9))
                        Text("Prune")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .disabled(store.isBusy)
                .help("Kill orphaned dev servers from crashed sessions")
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)

            if store.activeAppRoutes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "network.slash")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary.opacity(0.6))

                    Text("No active routes")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text("Run portless <cmd> in any project directory")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                if store.activeAppRoutes.count <= 4 {
                    VStack(spacing: 4) {
                        ForEach(store.activeAppRoutes) { route in
                            RouteRowView(route: route, store: store) {
                                onSelectRoute(route)
                            }
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(store.activeAppRoutes) { route in
                                RouteRowView(route: route, store: store) {
                                    onSelectRoute(route)
                                }
                            }
                        }
                    }
                    .frame(height: 300)
                }
            }
        }
    }
}
