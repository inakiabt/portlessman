import SwiftUI
import AppKit

@main
struct PortlessApp: App {
    @StateObject private var store = PortlessStore.shared

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
        } label: {
            HStack(spacing: 3) {
                Image(systemName: store.proxyStatus.isRunning ? "bolt.fill" : "bolt.slash.fill")
                    .symbolRenderingMode(.hierarchical)

                if store.activeAppRoutes.count > 0 {
                    Text("\(store.activeAppRoutes.count)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
            }
            .foregroundStyle(store.proxyStatus.isRunning ? .primary : .secondary)
        }
        .menuBarExtraStyle(.window)
    }
}
