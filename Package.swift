// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "EyeBreak",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "AudioSafe",
            path: "Sources/AudioSafe",
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedFramework("AVFoundation")
            ]
        ),
        .executableTarget(
            name: "EyeBreak",
            dependencies: ["AudioSafe"],
            path: "Sources/EyeBreak",
            linkerSettings: [
                .linkedFramework("CoreMediaIO"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("UserNotifications"),
                .linkedFramework("StoreKit"),
                .linkedFramework("HealthKit"),
            ]
        )
    ]
)
