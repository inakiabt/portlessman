import XCTest
@testable import Portlessman

final class RouteTests: XCTestCase {
    func testRoutePidStringWithoutSeparators() {
        let route = PortlessRoute(
            hostname: "test.localhost",
            port: 3000,
            pid: 51397,
            url: "https://test.localhost"
        )
        XCTAssertEqual(route.pidString, "51397")
        XCTAssertFalse(route.pidString.contains("."))
        XCTAssertFalse(route.pidString.contains(","))
    }

    func testRouteEntryDecoding() throws {
        let json = """
        {
            "hostname": "api.localhost",
            "port": 8080,
            "pid": 12345,
            "tailscaleUrl": "https://api.ts.net",
            "ngrokUrl": "https://api.ngrok.app"
        }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(RouteEntry.self, from: json)
        XCTAssertEqual(entry.hostname, "api.localhost")
        XCTAssertEqual(entry.port, 8080)
        XCTAssertEqual(entry.pid, 12345)
        XCTAssertEqual(entry.tailscaleUrl, "https://api.ts.net")
        XCTAssertEqual(entry.ngrokUrl, "https://api.ngrok.app")
    }

    func testEditorAppList() {
        XCTAssertFalse(EditorApp.knownEditors.isEmpty)
        let finder = EditorApp.knownEditors.first(where: { $0.bundleId == "com.apple.finder" })
        XCTAssertNotNil(finder)
        XCTAssertEqual(finder?.name, "Finder")
    }
}
