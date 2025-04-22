// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "TelegramHarvester",
    platforms: [
        .macOS(.v15) // Match the starter from ######
    ],
    dependencies: [
        // 💧 Vapor web framework
        .package(url: "https://github.com/vapor/vapor.git", from: "4.113.2"), // Match the starter from ######
        
        // 🔵 SwiftNIO for lower-level async I/O and timer handling
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),

        .package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.7.0"),

        // 📦 TDLibKit for Telegram API Solution #2
        .package(
            url: "https://github.com/Swiftgram/TDLibKit.git",
            .exact("1.5.2-tdlib-1.8.47-f1b75003")
        )
    ],
    targets: [
        .executableTarget(
            name: "TelegramHarvester",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "TDLibKit", package: "TDLibKit")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "TelegramHarvesterTests",
            dependencies: [
                .target(name: "TelegramHarvester"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
