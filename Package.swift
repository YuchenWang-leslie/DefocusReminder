// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DefocusReminder",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "DefocusReminder", targets: ["DefocusReminder"]),
    ],
    targets: [
        .target(
            name: "DefocusReminderCore",
            path: "Sources/DefocusReminder"
        ),
        .executableTarget(
            name: "DefocusReminder",
            dependencies: ["DefocusReminderCore"],
            path: "Sources/DefocusReminderApp",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "DefocusReminderTests",
            dependencies: ["DefocusReminderCore"],
            path: "Tests/DefocusReminderTests"
        ),
    ]
)
