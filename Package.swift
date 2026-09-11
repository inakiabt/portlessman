// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PortlessApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Portless",
            targets: ["Portless"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Portless",
            dependencies: [],
            path: "Sources/Portless"
        )
    ]
)
