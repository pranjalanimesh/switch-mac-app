// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Switch",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "Switch", path: "Sources/Switch")
    ]
)
