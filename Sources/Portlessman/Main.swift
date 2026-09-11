import SwiftUI
import AppKit

@main
struct PortlessmanApp: App {
    @StateObject private var store = PortlessStore.shared

    init() {
        if CommandLine.arguments.contains("--render-screenshots") {
            ScreenshotRenderer.renderAll()
            exit(0)
        }
    }

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
