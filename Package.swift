// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LinkedInWidget",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "LinkedInWidget",
            path: "Sources"
        )
    ]
)
