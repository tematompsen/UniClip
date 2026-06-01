// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "UniClipMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "uniclip-mac", targets: ["UniClipMac"])
    ],
    targets: [
        .executableTarget(
            name: "UniClipMac"
        )
    ]
)
