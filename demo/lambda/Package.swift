// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DemoGreetingLambda",
    platforms: [
        .macOS(.v15),
    ],
    dependencies: [
        .package(path: "../shared"),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", from: "2.0.0"),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-events.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "DemoGreetingLambda",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-events"),
                .product(name: "GreetingFeature", package: "shared"),
                .product(name: "CoreService", package: "shared"),
            ]
        ),
        .testTarget(
            name: "DemoGreetingLambdaTests",
            dependencies: [
                .target(name: "DemoGreetingLambda"),
            ]
        ),
    ]
)
