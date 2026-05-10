# Demo Application

A multi-target Swift monorepo that exemplifies the architecture documented in `plugin/skills/`. The same `GreetingFeature` use case is consumed from three different entry points:

- **iOS app** (`ios/`) — SwiftUI + `@Observable` model that streams use case state
- **Vapor server** (`vapor-server/`) — HTTP endpoint that runs the use case per request
- **AWS Lambda** (`lambda/`) — API Gateway handler that runs the same use case

All three apps share a single `shared/` Swift package containing the SDK, Service, and Feature layers.

## Layout

```
demo/
├── shared/                          ← cross-target Swift package
│   ├── Package.swift
│   └── Sources/
│       ├── Uniflow/                 ← SDK: UseCase / StreamingUseCase protocols
│       ├── GreetingClientSDK/       ← SDK: stateless TimeOfDayClient
│       ├── CoreService/             ← Service: Greeting + GreetingConfig models
│       └── GreetingFeature/         ← Feature: GreetingUseCase orchestrates SDK + service
├── ios/                             ← iOS app sources (no .xcodeproj checked in)
│   ├── DemoApp/                     ← App: composition root, @Observable model, views
│   ├── DemoAppTests/                ← unit tests for the iOS model
│   └── DemoAppUITests/              ← UI tests driving the app via XCTest
├── vapor-server/                    ← Vapor HTTP server (separate Swift package)
│   ├── Package.swift
│   ├── Sources/DemoVaporServer/     ← App: server entry point + routes
│   └── Tests/DemoVaporServerTests/  ← integration tests via VaporTesting
├── lambda/                          ← AWS Lambda function (separate Swift package)
│   ├── Package.swift
│   ├── Sources/DemoGreetingLambda/  ← App: Lambda entry point + handler
│   └── Tests/DemoGreetingLambdaTests/
├── project.yml                      ← XcodeGen spec for the iOS app
└── .gitignore                       ← ignores generated .xcodeproj, .build/, etc.
```

> The Vapor server directory is `vapor-server/` rather than `vapor/` to avoid colliding with the `vapor` Swift package identity (SwiftPM derives identity from the directory's last path component).

## Layer mapping

The shared package follows the 4-layer architecture verbatim:

| Layer | Module | Responsibility |
|-------|--------|----------------|
| Apps | `ios/DemoApp/`, `vapor-server/Sources/DemoVaporServer/`, `lambda/Sources/DemoGreetingLambda/` | Entry points and platform I/O. Only `@Observable` lives here (iOS). |
| Features | `shared/Sources/GreetingFeature/` | `GreetingUseCase` (`StreamingUseCase`) orchestrates SDK + service into a 3-step stream. |
| Services | `shared/Sources/CoreService/` | `Greeting`, `GreetingConfig` — shared `Sendable` models. |
| SDKs | `shared/Sources/Uniflow/`, `shared/Sources/GreetingClientSDK/` | Stateless `Sendable` structs. No business concepts. |

Dependencies flow downward only: every app imports `GreetingFeature`; the feature imports `CoreService` and `GreetingClientSDK`; nothing imports apps.

## Prerequisites

- Xcode 17+ (Swift 6.0+)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Building & running

### iOS app

```bash
cd demo
xcodegen generate
xcodebuild -scheme DemoApp -destination 'generic/platform=iOS Simulator' build
open DemoApp.xcodeproj
```

Run unit tests (Swift Testing):

```bash
xcodebuild test -scheme DemoApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:DemoAppTests
```

Run UI tests (XCTest):

```bash
xcodebuild test -scheme DemoApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:DemoAppUITests
```

### Shared package

```bash
cd demo/shared
swift test
```

### Vapor server

```bash
cd demo/vapor-server
swift run DemoVaporServer
# in another shell
curl 'http://127.0.0.1:8080/greet?name=Bill'
```

### AWS Lambda

```bash
cd demo/lambda
swift build
```

For deployment, the `AWSLambdaPackager` plugin packages the binary for Linux. See the [swift-aws-lambda-runtime deployment docs](https://github.com/swift-server/swift-aws-lambda-runtime).

## Testing conventions

Each test type is demonstrated in a different target so that AI agents reviewing the code have a concrete example for each:

- **Unit tests (Swift Testing).** `shared/Tests/*` and `ios/DemoAppTests/` — `@Test`, `#expect`, `#require`, `@Suite`, parameterized arguments. Drives individual functions or single-actor objects in isolation.
- **Integration tests (Swift Testing + VaporTesting).** `vapor-server/Tests/DemoVaporServerTests/` — exercises an in-process `Application` end-to-end, including routing, content decoding, and abort handling.
- **UI tests (XCTest).** `ios/DemoAppUITests/` — XCUITest is still required for UI tests in Xcode 17. Drives the app from outside the process. Mixing XCTest UI tests with Swift Testing unit tests in the same scheme is supported.

## AI-assisted bootstrap

This demo is intentionally minimal so that an AI agent can scaffold a new app on top of it. Paste this prompt into your agent of choice:

> ```
> Use the `swift-app-architecture` plugin's `swift-architecture` and `swift-swiftui` skills as the source of truth.
> Starting from the `demo/` directory in this repo as the reference layout, scaffold a new app that does <DESCRIBE FEATURE>.
>
> Requirements:
> 1. Add the SDK layer first — stateless Sendable structs in `demo/shared/Sources/<Name>SDK/`.
> 2. Add any shared models to `demo/shared/Sources/CoreService/` (or a new service module).
> 3. Add a feature module in `demo/shared/Sources/<Name>Feature/` exposing a `UseCase` or `StreamingUseCase`.
> 4. Consume the use case from at least one entry point:
>    - iOS: add an `@Observable` model in `ios/DemoApp/Models/` and a view in `ios/DemoApp/Views/`.
>    - Vapor: add a route in `vapor-server/Sources/DemoVaporServer/`.
>    - Lambda: add a handler in `lambda/Sources/DemoGreetingLambda/` (or a new lambda target).
> 5. Add tests for each new layer using Swift Testing (`@Test`, `#expect`).
> 6. Deploy target — describe how to deploy to <TARGET, e.g. App Store / Fly.io / AWS Lambda>.
>
> Constraints:
> - `@Observable` only at the Apps layer.
> - Features never depend on other features.
> - SDKs are stateless `Sendable` structs.
> - Dependencies flow downward: Apps → Features → Services → SDKs.
> - No `.xcodeproj` checked in — only `project.yml`. Regenerate with `xcodegen generate`.
> ```

Adjust `<DESCRIBE FEATURE>` and `<TARGET>` for your needs.
