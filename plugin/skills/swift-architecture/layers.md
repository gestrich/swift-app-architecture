# Layer Placement

Determines the correct architectural layer (Apps, Features, Services, SDKs) for new or existing code. Use the decision flowcharts, placement table, and dependency rules below to guide placement decisions.

## Decision Flowchart: Where Does This Code Belong?

```
Start: I need to add new code
    ↓
Is it UI, @Observable, or platform-specific I/O?
    ├─ Yes → Apps Layer
    │         (models, views, CLI commands, server handlers)
    │
    └─ No → Does it orchestrate multiple steps into a workflow?
              ├─ Yes → Features Layer
              │         (UseCase / StreamingUseCase)
              │
              └─ No → Is it a shared model, config, or stateful utility?
                        ├─ Yes → Services Layer
                        │
                        └─ No → Is it a single operation (one API call, one command)?
                                  ├─ Yes → SDKs Layer
                                  │         (stateless Sendable struct)
                                  └─ No → Services Layer (shared utility)
```

## Decision Flowchart: Feature vs Service

```
I'm adding new business logic
    ↓
Does it orchestrate multiple steps into a workflow?
    ├─ Yes → Feature Layer (use case)
    │         (e.g., ImportUseCase, SyncUseCase)
    │
    └─ No → Is it a shared model, config, or utility?
              ├─ Yes → Services Layer
              │         (e.g., CoreService, AuthService)
              │
              └─ Not sure → Does it coordinate SDK calls?
                            ├─ Yes → Feature Layer (use case)
                            └─ No → Services Layer
```

## Decision Flowchart: Service vs SDK

```
I'm adding functionality
    ↓
Is this ONE command or API call?
    ├─ Yes → SDK Layer
    │         (e.g., GitClient, APIClient)
    │
    └─ No → Is it a shared model or config used by multiple features?
              ├─ Yes → Services Layer
              │         (e.g., CoreService models, AuthService)
              │
              └─ Not sure → Could any project reuse this as-is?
                            ├─ Yes → SDK Layer
                            └─ No → Services Layer
```

## Where Do Data Models Go?

- **Used by multiple features?** → `services/CoreService/Models/` (Services layer)
- **Only used by one feature?** → `features/MyFeature/services/` (Features layer)
- **Only used by the UI?** → `apps/MyMacApp/` (Apps layer)

## Dependency Rules

Dependencies flow **downward only**:

```
Apps → Features → Services → SDKs
```

**Allowed:**
```
Apps     → Features, Services, SDKs
Features → Services, SDKs
Services → Other Services, SDKs
SDKs     → Other SDKs, external packages only
```

**Forbidden (never depend upward):**
```
SDKs     → Services, Features, Apps   ❌
Services → Features, Apps              ❌
Features → Apps                        ❌
Features → Other Features              ❌
```

If two features need shared logic, extract to a **Service** or **SDK**. Compose features at the **App layer** (model composition or composite CLI commands).

## Layer Characteristics

### Apps Layer
- Platform-specific entry points (macOS apps, CLI tools, servers)
- **Only layer** with `@Observable` models
- Minimal business logic — calls features and displays results
- CLI commands are app-layer constructs parallel to Mac models

### Features Layer
- Use cases conforming to `UseCase` / `StreamingUseCase` protocols
- **Multi-step orchestration** across SDKs and services
- Return `AsyncThrowingStream` for progress reporting
- Feature-specific models in `services/` subdirectory
- No `@Observable`, no UI, no CLI code

### Services Layer
- Shared models and types used across features
- Configuration persistence (auth tokens, user settings)
- Stateful utilities that **don't** orchestrate multi-step operations
- No orchestration (that belongs in Features)

### SDKs Layer
- **Stateless** `Sendable` structs — no internal state management
- Each method wraps a **single operation** (one CLI command, one API call)
- Generic, reusable — no business logic, no app-specific concepts
- Could be extracted to a standalone package for reuse across projects

## Good vs Bad Boundaries

### Good: SDK is Generic

```swift
// SDK — stateless, single operation, generic types
public struct GitClient: Sendable {
    public func createWorktree(path: String, branch: String) throws { }
}

// Feature — adds business context and orchestration
public struct PrepareTaskUseCase: UseCase {
    private let gitClient: GitClient

    public func run(options: TaskConfig) async throws -> TaskResult {
        let branchName = "task/\(options.name)"
        try gitClient.createWorktree(path: options.path, branch: branchName)
        return TaskResult(branch: branchName)
    }
}
```

### Bad: SDK Knows About Business Concepts

```swift
// ❌ SDK shouldn't know about app-specific types
public struct GitClient: Sendable {
    public func createWorktreeForTask(task: TaskConfig) throws { }
}
```

### Good: Service Holds Shared Models

```swift
// Service — shared configuration, no orchestration
public struct GitConfig {
    public let defaultRemote: String
    public let mainBranch: String
}
```

### Bad: Service Orchestrates Multi-Step Workflows

```swift
// ❌ Multi-step orchestration belongs in a Feature (use case)
public struct GitService {
    func prepareBranchAndPush(name: String) async throws {
        try gitClient.checkout(branch: "main")
        try gitClient.checkout(branch: "feature/\(name)")
        try gitClient.push(branch: "feature/\(name)")
    }
}
```

## Common Questions

**Can I call an SDK directly from an App?**
For simple cases, yes:
- Better: App → Feature (use case) → SDK
- Acceptable: App → SDK (for trivial single-call operations)
- Avoid: Complex SDK orchestration in Apps (use a Feature instead)

**Where does configuration go?**
In the **Services layer**: auth tokens → `AuthService/`, file paths → `StorageService/`, app settings → `CoreService/`. See [configuration.md](configuration.md) for implementation details.

**When should I create a new module vs extend an existing one?**
- New SDK: when wrapping a new external tool/service with no overlap
- New Feature: when the operations are a distinct domain (not related to existing features)
- New Service: when introducing shared types/config that don't fit existing services
- Otherwise: extend the existing module in the appropriate layer
- Always match the project's existing implementation strategy (separate packages, targets in one package, or folders)


## Implementation Strategies

The four-layer architecture is a logical structure. How you implement it depends on codebase size and existing conventions. **Match the style already used in the app you're working on.** If starting fresh and unsure, ask.

### Strategy 1: Targets in a Single Package

Each layer module is a **target** within one `Package.swift`. Parent folders (`features/`, `sdks/`, etc.) group targets by layer. Most common approach.

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

Dependencies declared between targets:
```swift
.target(name: "ImportFeature", dependencies: ["CoreService", "APIClientSDK", "Uniflow"]),
.target(name: "MyMacApp", dependencies: ["ImportFeature", "ExportFeature", "CoreService"]),
```

### Strategy 2: Separate Swift Packages

Each module has its own `Package.swift`. Common in large or multi-team codebases.

### Strategy 3: Folders Only

Layers are organizational folders within a single target. No separate targets or packages — layer boundaries enforced by convention only. Suitable for small apps or prototypes.

### Choosing a Strategy

| Strategy | When to use | Boundary enforcement |
|----------|------------|---------------------|
| Targets in a single package | Most projects — good balance of isolation and simplicity | Compile-time (import visibility) |
| Separate Swift packages | Large/multi-team codebases needing independent builds | Compile-time + independent versioning |
| Folders only | Small apps, prototypes, early-stage projects | Convention only |

## Source Code Structure

Regardless of implementation strategy, code is organized by architectural layer:

```
Sources/
├── apps/                     # Entry points
│   ├── MyCLIApp/             # CLI tool
│   ├── MyServerApp/          # Server entry point
│   └── MyMacApp/             # Mac app (@Observable models, SwiftUI views)
├── features/                 # Feature modules (use case + service combined)
│   ├── ImportFeature/
│   │   ├── usecases/         # ImportUseCase, ValidateUseCase, etc.
│   │   └── services/         # Models, config
│   ├── ExportFeature/
│   └── SyncFeature/
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

Modules use PascalCase names following the `<Name><Layer>` convention:

| Target | Folder | Layer |
|--------|--------|-------|
| `MyMacApp` | apps | App |
| `MyCLIApp` | apps | App |
| `ImportFeature` | features | Feature |
| `ExportFeature` | features | Feature |
| `CoreService` | services | Service |
| `AuthService` | services | Service |
| `APIClientSDK` | sdks | SDK |
| `GitSDK` | sdks | SDK |
| `Uniflow` | sdks | SDK |

## Use Case Protocols (Uniflow)

The `Uniflow` SDK defines two protocols for use case execution:

**`UseCase`** — Single `run(options:)` method:
```swift
public protocol UseCase: Sendable {
    associatedtype Options: Sendable = Void
    associatedtype Result: Sendable
    func run(options: Options) async throws -> Result
}
```

**`StreamingUseCase`** — Extends `UseCase` with streaming state:
```swift
public protocol StreamingUseCase: UseCase {
    associatedtype State: Sendable
    func stream(options: Options) -> AsyncThrowingStream<State, Error>
}
```

When `Result == State`, `StreamingUseCase` provides a default `run()` that consumes the stream and returns the last state.

| Protocol | Use When | Example |
|----------|----------|---------|
| `UseCase` | Single result, no intermediate progress | Status checks, configuration loading |
| `StreamingUseCase` | Multi-step with progress updates | Imports, builds, deployments |
