// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DemoShared",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "Uniflow", targets: ["Uniflow"]),
        .library(name: "GreetingClientSDK", targets: ["GreetingClientSDK"]),
        .library(name: "CoreService", targets: ["CoreService"]),
        .library(name: "GreetingFeature", targets: ["GreetingFeature"]),
    ],
    targets: [
        // SDKs layer — stateless Sendable building blocks
        .target(
            name: "Uniflow",
            path: "Sources/Uniflow"
        ),
        .target(
            name: "GreetingClientSDK",
            path: "Sources/GreetingClientSDK"
        ),

        // Services layer — shared models and configuration
        .target(
            name: "CoreService",
            path: "Sources/CoreService"
        ),

        // Features layer — use cases that orchestrate SDK and service calls
        .target(
            name: "GreetingFeature",
            dependencies: ["Uniflow", "GreetingClientSDK", "CoreService"],
            path: "Sources/GreetingFeature"
        ),

        // Tests
        .testTarget(
            name: "CoreServiceTests",
            dependencies: ["CoreService"],
            path: "Tests/CoreServiceTests"
        ),
        .testTarget(
            name: "GreetingFeatureTests",
            dependencies: ["GreetingFeature", "CoreService", "GreetingClientSDK"],
            path: "Tests/GreetingFeatureTests"
        ),
    ]
)
