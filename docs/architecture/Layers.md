# Architecture Layers

A strict **layered architecture** maintains separation of concerns, code reusability, and testability. The application is organized into four distinct layers:

1. **Apps Layer** — Entry points, `@Observable` models, platform-specific I/O
2. **Features Layer** — Use case orchestration via `UseCase` / `StreamingUseCase` protocols
3. **Services Layer** — Shared models, configuration, and stateful utilities
4. **SDKs Layer** — Stateless, reusable building blocks (`Sendable` structs)

## Implementation Strategies

The four-layer architecture is a logical structure. How you implement it in your project depends on the codebase size and existing conventions. **Match the style already used in the app you're working on.** If you're starting fresh and unsure which to pick, ask.

### Strategy 1: Targets in a Single Package

Each layer module is a **target** within one `Package.swift`. Parent folders (`features/`, `sdks/`, etc.) group targets by layer. This is the most common approach and works well for most projects.

```
MyApp/
├── Package.swift              # All targets defined here
└── Sources/
    ├── apps/
    │   ├── MyMacApp/          # target: MyMacApp
    │   └── MyCLIApp/          # target: MyCLIApp
    ├── features/
    │   ├── ImportFeature/     # target: ImportFeature
    │   └── ExportFeature/     # target: ExportFeature
    ├── services/
    │   └── CoreService/       # target: CoreService
    └── sdks/
        ├── APIClientSDK/      # target: APIClientSDK
        └── Uniflow/           # target: Uniflow
```

Dependencies are declared between targets in `Package.swift`:
```swift
.target(name: "ImportFeature", dependencies: ["CoreService", "APIClientSDK", "Uniflow"]),
.target(name: "MyMacApp", dependencies: ["ImportFeature", "ExportFeature", "CoreService"]),
```

### Strategy 2: Separate Swift Packages

Each layer module is its own **Swift package** with its own `Package.swift`. Common in large or multi-team codebases where independent versioning and build isolation matter.

```
MyApp/
├── apps/
│   ├── MyMacApp/
│   │   └── Package.swift      # depends on ../features/ImportFeature, etc.
│   └── MyCLIApp/
│       └── Package.swift
├── features/
│   ├── ImportFeature/
│   │   └── Package.swift      # depends on ../sdks/Uniflow, ../services/CoreService
│   └── ExportFeature/
│       └── Package.swift
├── services/
│   └── CoreService/
│       └── Package.swift
└── sdks/
    ├── APIClientSDK/
    │   └── Package.swift
    └── Uniflow/
        └── Package.swift
```

### Strategy 3: Folders Only

Layers are **organizational folders** within a single target or Xcode project. There are no separate targets or packages per module — the layer structure is a naming convention. Suitable for small apps or early-stage projects.

```
MyApp/
├── Package.swift              # Single target (or Xcode project)
└── Sources/
    └── MyApp/
        ├── apps/
        │   └── MyMacApp/
        ├── features/
        │   └── ImportFeature/
        ├── services/
        │   └── CoreService/
        └── sdks/
            └── GitSDK/
```

With this approach the build system does not enforce layer boundaries — the folder structure and naming conventions are the guardrails.

### Choosing a Strategy

| Strategy | When to use | Boundary enforcement |
|----------|------------|---------------------|
| Targets in a single package | Most projects — good balance of isolation and simplicity | Compile-time (import visibility) |
| Separate Swift packages | Large/multi-team codebases needing independent builds | Compile-time + independent versioning |
| Folders only | Small apps, prototypes, early-stage projects | Convention only |

> **Rule of thumb:** Follow the convention already established in the codebase. If starting a new project and unsure, targets in a single package is a good default.

## Layer Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  APPS LAYER (Entry Points)                                      │
│                                                                 │
│  apps/MyMacApp/          - macOS SwiftUI application            │
│  │   @Observable models, SwiftUI views                          │
│  │   └── Depends on: ImportFeature, CoreService, ...            │
│  │                                                              │
│  apps/MyCLIApp/          - Command-line interface tool           │
│  │   AsyncParsableCommand structs                               │
│  │   └── Depends on: ImportFeature, ExportFeature, ...          │
│  │                                                              │
│  apps/MyServerApp/       - Server entry point                   │
│      └── Depends on: SyncFeature, CoreService, ...              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  FEATURES LAYER (Use Cases)                                     │
│                                                                 │
│  features/ImportFeature/     - Import use cases                 │
│  │   ├── usecases/           - UseCase / StreamingUseCase       │
│  │   └── services/           - Feature-specific models, config  │
│  │   └── Depends on: CoreService, APIClientSDK, ...             │
│  │                                                              │
│  features/ExportFeature/     - Export use cases                  │
│  │   └── Depends on: CoreService, FileSystemSDK                 │
│  │                                                              │
│  features/SyncFeature/       - Sync use cases                   │
│      └── Depends on: CoreService, APIClientSDK, GitSDK          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  SERVICES LAYER (Shared Models & Utilities)                     │
│                                                                 │
│  services/CoreService/       - Core models and types            │
│  │   └── Depends on: GitSDK, CLISDK                             │
│  │                                                              │
│  services/AuthService/       - Auth configuration and tokens    │
│  │   └── Depends on: APIClientSDK                               │
│  │                                                              │
│  services/StorageService/    - Local file storage service        │
│      └── Depends on: CLISDK                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  SDKs LAYER (Stateless, Reusable)                               │
│                                                                 │
│  sdks/APIClientSDK/      - REST API wrapper                     │
│  sdks/GitSDK/            - Git operations                       │
│  sdks/CLISDK/            - Process execution, streams           │
│  sdks/FileSystemSDK/     - File system operations               │
│  sdks/Uniflow/           - Use case protocol definitions        │
│  sdks/DatabaseSDK/       - Database utilities                   │
└─────────────────────────────────────────────────────────────────┘
```

## 1. Apps Layer (Entry Points)

**Purpose:** Platform-specific entry points that handle I/O and own `@Observable` state.

**Responsibilities:**

- Executable targets (macOS apps, CLI tools, server handlers)
- `@Observable` models live here (for SwiftUI apps) — not in Services or Features
- CLI commands are app-layer constructs, parallel to Mac models
- Minimal business logic; focus on I/O and calling features

**Rules:**

- ✅ Own `@Observable` models that consume use case streams
- ✅ Handle platform-specific I/O (SwiftUI views, terminal output, server encoding)
- ✅ Call features (use cases) and display results
- ❌ NO business logic or multi-step orchestration
- ❌ NO direct SDK calls for business operations (use Features instead)

### Model Architecture (Mac Apps)

`@Observable` models consume use case streams and update state for the UI. Key patterns:

- **Model-View (MV)** — views connect directly to observable models, no dedicated ViewModels
- **Enum-based state** — represent model state as enums, not multiple independent properties
- **Minimal state mapping** — receive use case state and assign directly; complex mapping signals the use case should return better-structured state
- **State ownership** — use cases own state data, models own state transitions
- **Model composition** — parent models hold child models; models call models for cross-domain operations
- **Self-initializing lifecycle** — models load data on `init`, not on view appear
- **Optional child models** — prefer `nil` over "unconfigured" state for features requiring configuration

See **[swift-ui.md](swift-ui.md)** for detailed patterns, code examples, and guidelines.

### CLI Commands

CLI commands use use cases directly without the `@Observable` wrapper. Use `stream()` for progress output, or `run()` for fire-and-forget.

**CLI vs Mac App Composition Approaches:**

| App | Approach | Example |
|-----|----------|---------|
| Mac App | Model composition | `ParentModel.startAll()` → `childModel.start()` |
| CLI | Use case composition | `CompositeUseCase` → `ChildUseCase` + `AnotherUseCase` |

Both approaches share the same leaf use cases, ensuring consistent behavior. The difference is in orchestration:
- **Mac app** routes through models so each model can update its observable state
- **CLI** uses composite use cases directly since there's no observable state to track

```swift
struct ImportCommand: AsyncParsableCommand {
    func run() async throws {
        // Use stream() when you want progress output
        for try await state in useCase.stream(options: opts) {
            printProgress(state)
        }
    }
}

struct StatusCommand: AsyncParsableCommand {
    func run() async throws {
        // Use run() when you only care about the final result
        let result = try await useCase.run(options: opts)
        print(result)
    }
}
```

## 2. Features Layer (Use Cases)

**Purpose:** Multi-step orchestration operations. Features combine use case logic and feature-specific service code in one target.

**Responsibilities:**

- Use cases are structs conforming to `UseCase` or `StreamingUseCase` protocols (from `Uniflow`)
- Coordinate multiple SDK clients and services
- App-specific business logic and orchestration
- **Not** `@Observable` — that belongs in the Apps layer
- Depend on Services and SDKs, but never vice versa

**Rules:**

- ✅ Implement `UseCase` or `StreamingUseCase` protocols
- ✅ Orchestrate multi-step operations across SDKs and services
- ✅ Return `AsyncThrowingStream` for progress reporting
- ✅ Contain feature-specific models and configuration
- ❌ NO `@Observable` — that belongs in Apps
- ❌ NO direct UI or CLI code

### Features for Orchestration

Multi-step operations live in features as `StreamingUseCase` conformers.

```swift
import Uniflow

public struct ImportUseCase: StreamingUseCase {
    public typealias State = UseCaseState
    public typealias Result = State

    public struct Options: Sendable {
        public let source: DataSource
        public let validateFirst: Bool
    }

    public func stream(options: Options) -> AsyncThrowingStream<State, Error> {
        AsyncThrowingStream { continuation in
            Task {
                continuation.yield(.importing(.starting))
                for try await progress in apiClient.importStream(options: opts) {
                    continuation.yield(.importing(.progress(progress)))
                }
                continuation.yield(.completed(snapshot))
                continuation.finish()
            }
        }
    }
}
```

## 3. Services Layer (Shared Models & Utilities)

**Purpose:** Shared models, configuration, and stateful utilities used across features.

**Responsibilities:**

- App-specific models and types
- Configuration persistence (auth tokens, user settings)
- Stateful utilities that don't orchestrate multi-step operations
- Provide types and utilities consumed by features

**Rules:**

- ✅ Define shared models and types
- ✅ Manage configuration and persistence
- ✅ Provide stateful utilities
- ❌ NO multi-step orchestration (use Features instead)
- ❌ NO UI code or `@Observable`
- ❌ NO CLI argument parsing

## 4. SDKs Layer (Stateless, Reusable)

**Purpose:** Low-level, reusable building blocks with no app-specific logic.

**Responsibilities:**

- Wrap external tools and services
- **Stateless** — no internal state management
- Operations return `AsyncThrowingStream` for progress or values for one-shot queries
- Can be extracted to separate packages
- Use `Sendable` structs for clients — no mutable state means no need for actor isolation

**Rules:**

- ✅ Stateless and reusable
- ✅ Generic operations only
- ✅ `Sendable` struct clients
- ❌ NO business logic
- ❌ NO application state
- ❌ NO knowledge of app-specific concepts

**Example:**
```swift
// Good: Generic SDK operation
public struct GitClient: Sendable {
    public func createWorktree(path: String, branch: String) throws { ... }
    public func commitStream(message: String) -> AsyncThrowingStream<GitProgress, Error> { ... }
}

// Bad: SDK knows about business concepts
public struct GitClient: Sendable {
    public func createWorktreeForImport(task: ImportConfig) throws {
        // ❌ SDK shouldn't know about ImportConfig
    }
}
```

### Stateless SDKs

SDK clients don't maintain internal state. Each method call is independent.

```swift
public struct APIClient: Sendable {
    private let httpClient: HTTPClient

    // Returns stream — no internal state tracking
    public func importStream(options: ImportOptions) -> AsyncThrowingStream<ImportProgress, Error>

    // Returns value directly
    public func fetchStatus(id: String) async throws -> StatusResponse
}
```

### Use Case Protocols (Uniflow)

The `Uniflow` SDK defines two protocols for use case execution:

**`UseCase`** — Base protocol with a single `run(options:)` method:

```swift
public protocol UseCase: Sendable {
    associatedtype Options: Sendable = Void
    associatedtype Result: Sendable

    func run(options: Options) async throws -> Result
}
```

**`StreamingUseCase`** — Extends `UseCase` with streaming state updates:

```swift
public protocol StreamingUseCase: UseCase {
    associatedtype State: Sendable

    func stream(options: Options) -> AsyncThrowingStream<State, Error>
}
```

When `Result == State`, `StreamingUseCase` provides a default `run()` implementation that consumes the stream and returns the last state.

**When to use each:**

| Protocol | Use When | Example |
|----------|----------|---------|
| `UseCase` | Single result, no intermediate progress | Status checks, configuration loading |
| `StreamingUseCase` | Multi-step with progress updates | Imports, builds, deployments |

## Source Code Structure

Regardless of implementation strategy, code is organized by architectural layer in folders:

```
Sources/
├── apps/                     # Entry points
│   ├── MyCLIApp/             # CLI tool
│   ├── MyServerApp/          # Server entry point
│   └── MyMacApp/             # Mac app (@Observable models, SwiftUI views)
├── features/                 # Feature modules (use case + service combined)
│   ├── ImportFeature/        # Import feature
│   │   ├── usecases/         # ImportUseCase, ValidateUseCase, etc.
│   │   └── services/         # Models, config
│   ├── ExportFeature/        # Export feature
│   └── SyncFeature/          # Sync feature
├── services/                 # Shared service modules
│   ├── CoreService/          # Core models and types
│   ├── AuthService/          # Auth configuration and tokens
│   └── StorageService/       # Local file storage service
└── sdks/                     # Low-level SDK modules
    ├── APIClientSDK/         # REST API wrapper
    ├── CLISDK/               # CLI utilities (process execution, streams)
    ├── GitSDK/               # Git operations
    ├── FileSystemSDK/        # File system operations
    ├── DatabaseSDK/          # Database utilities
    └── Uniflow/              # Use case protocol definitions
```

## Module Naming

Modules (whether targets, packages, or folders) use PascalCase names following the `<Name><Layer>` convention:

| Folder | Layer | Position |
|--------|-------|----------|
| `apps/` | App | Top (entry points) |
| `features/` | Feature | Second |
| `services/` | Service | Third |
| `sdks/` | SDK | Bottom (reusable) |

**Examples:**

| Target | Folder | Layer | Description |
|--------|--------|-------|-------------|
| `MyMacApp` | apps | App | macOS application |
| `MyCLIApp` | apps | App | CLI tool |
| `MyServerApp` | apps | App | Server entry point |
| `ImportFeature` | features | Feature | Import use cases |
| `ExportFeature` | features | Feature | Export use cases |
| `SyncFeature` | features | Feature | Sync use cases |
| `CoreService` | services | Service | Core models and types |
| `AuthService` | services | Service | Auth configuration |
| `StorageService` | services | Service | Local storage |
| `APIClientSDK` | sdks | SDK | API client utilities |
| `CLISDK` | sdks | SDK | CLI utilities |
| `GitSDK` | sdks | SDK | Git operations |

**Benefits:**

1. **Architectural grouping**: `ls Sources/` shows the four layers clearly
2. **Layer visibility**: The folder immediately identifies which architectural layer a target belongs to
3. **Discoverability**: Finding all SDK targets is easy — look in `sdks/`

## Data Flow

**CLI**: `useCase.stream() → print progress` or `useCase.run() → print result`

**Mac App**: `useCase.stream() → @Observable model → View`

## Dependency Rules

1. **Apps** depend on Features, Services, and SDKs
2. **Features** depend on Services and SDKs
3. **Services** depend on other Services and SDKs
4. **SDKs** depend only on other SDKs or external packages
5. Never depend upward

## When to Create a New Module

**SDK**: Reusable, no app-specific logic, wraps external tool/service. Use `Sendable` structs.

**Feature**: Multi-step orchestration, coordinates SDKs and services, returns `AsyncThrowingStream`. Implements `UseCase` or `StreamingUseCase`.

**Service**: Models, configuration, stateful utilities that don't orchestrate.

**App**: Entry point, UI, platform-specific I/O. Owns `@Observable` models.

How the new module is physically created depends on the project's implementation strategy — see [Implementation Strategies](#implementation-strategies).

## Further Reading

- **[ARCHITECTURE.md](ARCHITECTURE.md)** — Architecture overview
- **[Dependencies.md](Dependencies.md)** — Dependency rules and boundaries
- **[FeatureStructure.md](FeatureStructure.md)** — How to structure feature modules
- **[swift-ui.md](swift-ui.md)** — SwiftUI and model architecture guidelines
- **[Configuration.md](Configuration.md)** — Configuration and data path management
