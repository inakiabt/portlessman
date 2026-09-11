// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Portlessman",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Portlessman",
            targets: ["Portlessman"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Portlessman",
            dependencies: [],
            path: "Sources/Portlessman"
        )
    ]
)
