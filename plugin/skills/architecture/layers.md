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

## Source Documentation

- **[Layers.md](../../../docs/architecture/Layers.md)** — Detailed layer descriptions and rules
- **[Dependencies.md](../../../docs/architecture/Dependencies.md)** — Dependency rules and boundaries
- **[QuickReference.md](../../../docs/architecture/QuickReference.md)** — Quick decision guides
