// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DemoVaporServer",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(path: "../shared"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.0"),
    ],
    targets: [
        .executableTarget(
            name: "DemoVaporServer",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "GreetingFeature", package: "shared"),
                .product(name: "CoreService", package: "shared"),
            ]
        ),
        .testTarget(
            name: "DemoVaporServerTests",
            dependencies: [
                .target(name: "DemoVaporServer"),
                .product(name: "VaporTesting", package: "vapor"),
            ]
        ),
    ]
)
