# Feature Structure Guide

This document describes how to structure features and create new ones within the layered architecture.

## Architecture Overview

Features are **use case modules** — they contain `UseCase` / `StreamingUseCase` conformers that orchestrate multi-step operations. Features do not contain UI or CLI code; those live in the **Apps layer** as separate entry points.

```
Sources/
├── apps/                      # Entry points (Mac app, CLI, server)
│   ├── MyMacApp/              # @Observable models + SwiftUI views
│   └── MyCLIApp/              # ArgumentParser commands
├── features/                  # Use case modules
│   ├── ImportFeature/         # Import use cases
│   └── ExportFeature/         # Export use cases
├── services/                  # Shared models, config, utilities
│   └── CoreService/
└── sdks/                      # Stateless, reusable clients
    ├── APIClientSDK/
    └── Uniflow/               # UseCase protocol definitions
```

## Feature Structure Pattern

Each feature is a module containing use cases and feature-specific types. The internal structure is the same regardless of implementation strategy:

```
features/ImportFeature/
├── usecases/
│   ├── ImportUseCase.swift          # StreamingUseCase conformer
│   ├── ValidateUseCase.swift        # UseCase conformer
│   └── CompositeImportUseCase.swift # Composes child use cases
└── services/
    ├── ImportMapper.swift           # Feature-specific helpers
    └── ImportTypes.swift            # Feature-specific models
```

> The exact nesting (e.g., whether there's a `Sources/ImportFeature/` wrapper) depends on whether this is a target in a package, a standalone package, or just a folder. See [Layers.md — Implementation Strategies](Layers.md#implementation-strategies).

## What a Feature Contains

A feature module contains:

1. **Use cases** — `UseCase` or `StreamingUseCase` conformers that orchestrate multi-step operations
2. **Feature-specific types** — Models, mappers, and helpers that are only used within this feature
3. **Feature-specific configuration** — Settings or options scoped to this feature

A feature does **not** contain:

- ❌ SwiftUI views or `@Observable` models (those belong in Apps)
- ❌ CLI commands or ArgumentParser structs (those belong in Apps)
- ❌ Shared models used across features (those belong in Services)

## Dependency Declaration

How you declare feature dependencies depends on the project's implementation strategy (see [Layers.md — Implementation Strategies](Layers.md#implementation-strategies)).

### Target in a Single Package

The feature is a target in the project's root `Package.swift`:

```swift
// In the root Package.swift
.target(
    name: "ImportFeature",
    dependencies: ["Uniflow", "APIClientSDK", "CoreService"],
    path: "Sources/features/ImportFeature"
),
```

### Separate Swift Package

The feature has its own `Package.swift`:

```swift
let package = Package(
    name: "ImportFeature",
    products: [
        .library(name: "ImportFeature", targets: ["ImportFeature"])
    ],
    dependencies: [
        .package(path: "../sdks/Uniflow"),
        .package(path: "../sdks/APIClientSDK"),
        .package(path: "../services/CoreService"),
    ],
    targets: [
        .target(
            name: "ImportFeature",
            dependencies: ["Uniflow", "APIClientSDK", "CoreService"]
        ),
        .testTarget(
            name: "ImportFeatureTests",
            dependencies: ["ImportFeature"]
        ),
    ]
)
```

### Folders Only

No separate dependency declaration — features are folders within a single target. Layer boundaries are enforced by convention.

## App Structure Pattern

Apps are separate entry points that consume features. They live in the `apps/` directory:

### Mac App
```
apps/MyMacApp/
└── Sources/
    └── MyMacApp/
        ├── MyMacApp.swift              # @main App struct
        ├── Models/
        │   ├── AppModel.swift          # Root @Observable model
        │   ├── ImportModel.swift        # Import @Observable model
        │   └── ExportModel.swift        # Export @Observable model
        └── Views/
            ├── ContentView.swift
            ├── ImportView.swift
            └── ExportView.swift
```

### CLI App
```
apps/MyCLIApp/
└── Sources/
    └── MyCLIApp/
        ├── MyCLIApp.swift              # @main root command
        ├── ImportCommand.swift
        └── ExportCommand.swift
```

Both app entry points depend on the same features — the declaration mechanism varies by implementation strategy.

## Guidelines for New Features

When creating a new feature:

### 1. Create the use case module

Create the feature in `features/MyFeature/`:
- Define use cases in `usecases/`
- Add feature-specific types in `services/`

**Example use case:**
```swift
import Uniflow
import CoreService
import APIClientSDK

public struct ExportUseCase: StreamingUseCase {
    public typealias State = ExportState
    public typealias Result = State

    public struct Options: Sendable {
        public let format: ExportFormat
        public let destination: String
    }

    private let apiClient: APIClient

    public init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    public func stream(options: Options) -> AsyncThrowingStream<State, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    continuation.yield(.preparing)
                    let data = try await apiClient.fetchData(source: options.destination)
                    continuation.yield(.exporting(progress: 0.5))
                    // ... export logic
                    continuation.yield(.completed(ExportResult(path: options.destination)))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
```

### 2. Add shared types to Services if needed

If the feature introduces types that other features will use, put them in a service:
- `services/CoreService/` for core models
- `services/AuthService/` for auth-related types
- Create a new service only if the types don't fit an existing one

### 3. Add app-layer consumption

**Mac app** — Create an `@Observable` model that consumes the use case stream:
```swift
@MainActor @Observable
class ExportModel {
    var state: ModelState = .ready

    func startExport(format: ExportFormat, destination: String) {
        Task {
            for try await useCaseState in useCase.stream(options: .init(format: format, destination: destination)) {
                state = ModelState(from: useCaseState)
            }
        }
    }
}
```

**CLI** — Create a command that uses the use case directly:
```swift
struct ExportCommand: AsyncParsableCommand {
    func run() async throws {
        for try await state in useCase.stream(options: opts) {
            printProgress(state)
        }
    }
}
```

### 4. Follow the dependency rules

- Features → Services, SDKs
- Apps → Features, Services, SDKs
- No reverse dependencies
- See [Dependencies.md](Dependencies.md) for details

### 5. Share all business logic via use cases

- CLI and Mac app consume the same use cases
- No duplication of orchestration logic
- Only the app-layer consumption pattern differs (model vs direct)

## Key Points

1. **Features are use case modules** — not UI/CLI target pairs
2. **Apps are separate entry points** — Mac app, CLI, and server each have their own target in `apps/`
3. **Use cases orchestrate** — multi-step operations via `UseCase` / `StreamingUseCase`
4. **Zero duplication** — CLI and Mac app share the same features
5. **Independent modules** — features can be built and tested in isolation (when using targets or packages)
6. **@Observable in Apps only** — models live in the app layer, not in features
