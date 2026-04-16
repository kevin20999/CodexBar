// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CodexBar",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log", from: "1.9.1"),
        .package(url: "https://github.com/steipete/SweetCookieKit", revision: "4d5b71ffbb296937dc5ee8472f64721bca771cf0"),
    ],
    targets: [
        .target(
            name: "CodexBarCore",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SweetCookieKit", package: "SweetCookieKit"),
            ],
            path: "Sources/CodexBarCore/TokenCore",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "CodexDailyKit",
            dependencies: [
                "CodexBarCore",
            ],
            path: "Sources/CodexDailyBoardShared",
            resources: [
                .process("Resources"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .executableTarget(
            name: "CodexBar",
            dependencies: [
                "CodexBarCore",
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "Sources/CodexBar/TokenApp",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .executableTarget(
            name: "CodexDaily",
            dependencies: [
                "CodexBarCore",
                "CodexDailyKit",
            ],
            path: "Sources/CodexDailyBoardApp",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .testTarget(
            name: "CodexBarTests",
            dependencies: [
                "CodexBar",
                "CodexBarCore",
                "CodexDailyKit",
            ],
            path: "Tests/TokenTests",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
    ])
