// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Synco",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "Synco", targets: ["SyncoApp"]),
        .library(name: "SyncoKit", targets: ["SyncoSync"]),
    ],
    targets: [
        .target(name: "SyncoCore"),
        .target(name: "SyncoCrypto", dependencies: ["SyncoCore"]),
        .target(name: "SyncoTransport", dependencies: ["SyncoCore", "SyncoCrypto"]),
        .target(name: "SyncoDiscovery", dependencies: ["SyncoCore"]),
        .target(name: "SyncoTransfer", dependencies: ["SyncoCore"]),
        .target(name: "SyncoClipboard", dependencies: ["SyncoCore", "SyncoTransfer"]),
        .target(name: "SyncoSettings", dependencies: ["SyncoCore", "SyncoCrypto"]),
        .target(name: "SyncoRemote", dependencies: ["SyncoCore"]),
        .target(name: "SyncoPower", dependencies: ["SyncoCore"]),
        .target(
            name: "SyncoSync",
            dependencies: [
                "SyncoCore",
                "SyncoCrypto",
                "SyncoTransport",
                "SyncoDiscovery",
                "SyncoClipboard",
                "SyncoTransfer",
                "SyncoSettings",
                "SyncoRemote",
            ]
        ),
        .target(name: "SyncoUI", dependencies: ["SyncoSync", "SyncoPower"]),
        .target(name: "SyncoRuntime", dependencies: ["SyncoCore", "SyncoSettings"]),
        .executableTarget(name: "SyncoApp", dependencies: ["SyncoUI", "SyncoRuntime"]),

        .testTarget(name: "SyncoCoreTests", dependencies: ["SyncoCore"]),
        .testTarget(name: "SyncoCryptoTests", dependencies: ["SyncoCrypto"]),
        .testTarget(name: "SyncoTransportTests", dependencies: ["SyncoTransport"]),
        .testTarget(name: "SyncoSyncTests", dependencies: ["SyncoSync"]),
        .testTarget(name: "SyncoUITests", dependencies: ["SyncoUI"]),
        .testTarget(name: "SyncoClipboardTests", dependencies: ["SyncoClipboard"]),
        .testTarget(name: "SyncoRuntimeTests", dependencies: ["SyncoRuntime"]),
        .testTarget(name: "SyncoRemoteTests", dependencies: ["SyncoRemote"]),
        .testTarget(name: "SyncoPowerTests", dependencies: ["SyncoPower"]),
    ],
    swiftLanguageModes: [.v6]
)
