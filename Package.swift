// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "hypertile",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "hypertile",
            dependencies: [],
            path: "Sources"
        )
    ]
)
