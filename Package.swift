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
    ],
    targets: [
        .executableTarget(
            name: "TelegramHarvester",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
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
