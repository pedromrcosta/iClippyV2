// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iClippy",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "iClippy",
            targets: ["iClippy"])
    ],
    targets: [
        .executableTarget(
            name: "iClippy",
            dependencies: [],
            path: "Sources/iClippy"
        ),
        .testTarget(
            name: "iClippyTests",
            dependencies: ["iClippy"],
            path: "Tests/iClippyTests"
        )
    ]
)
