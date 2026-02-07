# Architecture Principles

Core principles that guide the 4-layer Swift app architecture. Use these when making architectural decisions or reviewing code for compliance.

## The Five Principles

### 1. Depth Over Width

App-layer code calls **ONE** use case per user action. The use case orchestrates everything internally.

**Good (depth):**
```swift
// App layer calls ONE use case
for try await progress in useCase.stream(options: opts) {
    print(progress)
}
```

**Bad (width):**
```swift
// App layer orchestrates multiple steps directly
let worktree = try await gitClient.createWorktree(...)
try await scriptRunner.runScript(...)
try await gitClient.commit(...)
try await gitClient.push(...)
try await apiClient.createPR(...)
```

**Why:** Keeps app-layer thin, makes business logic testable, and ensures CLI and Mac app don't duplicate orchestration.

### 2. Zero Duplication

CLI and Mac app share 100% of business logic through the Features layer. Use cases are consumed by both entry points — only the app-layer consumption differs.

**Benefits:**
- Fix once, works everywhere
- Add features once, both clients benefit
- Single source of truth for business logic

**Pattern:**
```
Feature (use case) ← shared
    ├── CLI command (Apps layer)
    └── @Observable model (Apps layer)
```

### 3. Use Cases Orchestrate

Features expose `UseCase` / `StreamingUseCase` conformers that orchestrate multi-step operations across SDKs and services. Use cases are the primary unit of business logic.

```swift
public struct ImportDataUseCase: StreamingUseCase {
    private let apiClient: APIClient
    private let storageClient: StorageClient

    public func stream(options: ImportOptions) -> AsyncThrowingStream<Progress, Error> {
        // Multi-step orchestration across multiple SDKs
    }
}
```

**Rule:** If code coordinates multiple SDK/service calls, it belongs in a use case, not in an app-layer model or service.

### 4. SDKs Are Stateless

SDK clients are `Sendable` structs with no mutable state. Each method wraps a single operation (one CLI command, one API call). No business concepts, no app-specific types.

```swift
public struct GitClient: Sendable {
    public func checkout(branch: String) throws { }
    public func commit(message: String) throws { }
}
```

**Tests:**
- Could another project use this SDK as-is? → Yes = correct
- Does the SDK reference app-specific types? → Yes = violation
- Does the SDK hold mutable state? → Yes = violation

### 5. @Observable at the App Layer Only

`@Observable` models exist only in the Apps layer where UI binding is needed. Models consume use case streams and update state for the UI.

```swift
@MainActor @Observable
class ImportModel {
    var state: ImportState = .idle

    func start() {
        Task {
            for try await progress in useCase.stream(options: opts) {
                state = ImportState(from: progress)
            }
        }
    }
}
```

**State ownership:** Use cases own the data; models own the transitions.

## Why Layers?

| Benefit | How |
|---------|-----|
| **Zero duplication** | CLI and Mac app share use cases |
| **Easy testing** | Test use cases without UI; mock SDKs for unit tests |
| **Clear responsibilities** | Every piece of code has an obvious home |
| **Reusability** | SDKs work in any project; use cases back multiple entry points |
| **Maintainability** | Changes isolated to appropriate layer; no circular dependencies |

## Feature-Based Structure

Each major capability corresponds to its own feature module containing use cases. App-layer entry points consume these features.

This ensures:
- Each feature is independently buildable and testable
- Features can be developed in isolation
- Clear ownership and boundaries
- Features can be reused across entry points or extracted to separate projects

## Compliance Checklist

When reviewing code against these principles:

- [ ] App-layer code calls one use case per user action (depth over width)
- [ ] Business logic lives in Features, not duplicated between CLI and Mac app
- [ ] Multi-step orchestration is in use cases, not app-layer models or services
- [ ] SDKs are stateless `Sendable` structs with single-operation methods
- [ ] `@Observable` only appears in the Apps layer
- [ ] SDKs have no app-specific types or business concepts
- [ ] Dependencies flow downward only (Apps → Features → Services → SDKs)

## Source Documentation

- **[Principles.md](../../../docs/architecture/Principles.md)** — Full principles document
