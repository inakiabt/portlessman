import SwiftUI
import AppKit

@MainActor
public struct ScreenshotRenderer {
    public static func renderAll() {
        let store = PortlessStore.shared
        store.reload()

        // Wait for async route loading and lsof cwd resolution
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 1.0))

        let outputDir = URL(fileURLWithPath: "/Users/inakiabt/src/personal/portless-app/docs/screenshots")
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        print("Total loaded routes for screenshots:", store.routes.count)

        // 1. Main View (with routes list)
        let mainView = MenuContentView()
            .preferredColorScheme(.dark)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .padding(12)

        renderViewToPng(
            view: mainView,
            fixedWidth: 384,
            waitSec: 0.2,
            file: outputDir.appendingPathComponent("main_view.png")
        )

        // 2. Route Detail View
        let targetRoute = store.routes.first(where: { $0.hostname == "admin-portal.localhost" }) ?? store.routes.first
        if let route = targetRoute {
            let detailView = RouteDetailView(route: route, store: store, onBack: {})
                .preferredColorScheme(.dark)
                .background(Color(nsColor: .windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .padding(12)

            renderViewToPng(
                view: detailView,
                fixedWidth: 404,
                waitSec: 0.2,
                file: outputDir.appendingPathComponent("route_detail.png")
            )
        }

        // 3. Settings View
        let settingsView = SettingsView(store: store, onBack: {})
            .preferredColorScheme(.dark)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .padding(12)

        renderViewToPng(
            view: settingsView,
            fixedWidth: 384,
            waitSec: 0.2,
            file: outputDir.appendingPathComponent("settings_view.png")
        )

        // 4. Doctor View (wait 2 seconds for CLI check to complete)
        let doctorView = DoctorModalView(onBack: {})
            .preferredColorScheme(.dark)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .padding(12)

        renderViewToPng(
            view: doctorView,
            fixedWidth: 384,
            waitSec: 2.0,
            file: outputDir.appendingPathComponent("doctor_view.png")
        )

        print("✅ Screenshots rendered successfully to docs/screenshots/")
    }

    private static func renderViewToPng<V: View>(view: V, fixedWidth: CGFloat, waitSec: Double, file: URL) {
        let hosting = NSHostingView(rootView: view)
        hosting.appearance = NSAppearance(named: .darkAqua)

        let fitting = hosting.fittingSize
        let width = max(fixedWidth, fitting.width)
        let height = max(120, fitting.height)

        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: width, height: height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.appearance = NSAppearance(named: .darkAqua)
        window.isOpaque = false
        window.backgroundColor = .clear
        hosting.frame = NSRect(x: 0, y: 0, width: width, height: height)
        window.contentView = hosting
        window.orderFront(window)

        RunLoop.current.run(until: Date(timeIntervalSinceNow: waitSec))
        hosting.layoutSubtreeIfNeeded()

        guard let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else {
            window.orderOut(window)
            return
        }
        hosting.cacheDisplay(in: hosting.bounds, to: rep)

        if let pngData = rep.representation(using: .png, properties: [:]) {
            try? pngData.write(to: file)
            print("Captured:", file.lastPathComponent, "size:", hosting.bounds.size)
        }
        window.orderOut(window)
    }
}
