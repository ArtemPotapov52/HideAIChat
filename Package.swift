// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TransparentNotion",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "TransparentNotion",
            path: "Sources/TransparentNotion",
            resources: [.process("Resources")]
        )
    ]
)
