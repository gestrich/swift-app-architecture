# Core Principles

This document outlines the core architectural principles that guide development.

## 1. Depth Over Width

App-layer code (CLI commands, `@Observable` models) calls **ONE** use case per user action. The use case orchestrates everything needed internally through multiple SDK and service calls. Avoid wide orchestration in app-layer code.

**Good (Depth):**
```swift
// CLI calls ONE use case
for try await progress in useCase.stream(options: opts) {
    print(progress)
}
```

**Bad (Width):**
```swift
// CLI orchestrates multiple steps directly
let worktree = try await gitClient.createWorktree(...)
try await scriptRunner.runScript(...)
try await gitClient.commit(...)
try await gitClient.push(...)
try await apiClient.createPR(...)
```

## 2. Zero Duplication

CLI and Mac app share 100% of business logic through the Features layer. Use cases are consumed by both entry points — only the app-layer consumption differs.

**Benefits:**
- Fix once, works everywhere
- Add features once, both clients benefit
- Single source of truth for business logic

## 3. Use Cases Orchestrate

Features expose `UseCase` / `StreamingUseCase` conformers that orchestrate multi-step operations across SDKs and services. Use cases are the primary unit of business logic.

```swift
// Feature layer: orchestrates multiple SDK calls
public struct ImportDataUseCase: StreamingUseCase {
    private let apiClient: APIClient
    private let storageClient: StorageClient

    public func stream(options: ImportOptions) -> AsyncThrowingStream<Progress, Error> {
        // Multi-step orchestration
    }
}
```

## 4. SDKs Are Stateless

SDK clients are `Sendable` structs with no mutable state. Each method wraps a single operation (one CLI command, one API call). No business concepts, no app-specific types.

```swift
// Stateless, reusable, no app-specific knowledge
public struct GitClient: Sendable {
    public func checkout(branch: String) throws { }
    public func commit(message: String) throws { }
}
```

## 5. @Observable at the App Layer Only

`@Observable` models exist only in the Apps layer where UI binding is needed. Models consume use case streams and update state for the UI. Use cases own the state data; models own the state transitions.

```swift
// App layer: @Observable model consumes use case stream
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

## Why Layers?

### 1. Zero Duplication
- CLI and Mac app share 100% of business logic via Features
- Fix once, works everywhere
- Add features once, both clients benefit

### 2. Easy Testing
- Test use cases without UI
- Mock SDKs for unit tests
- Integration tests at the Feature layer

### 3. Clear Responsibilities
- Easy to find where code belongs
- New functionality has an obvious home
- Reduces mental overhead

### 4. Reusability
- SDKs can be used by other projects
- Use cases can back multiple app entry points
- Core logic is UI-agnostic

### 5. Maintainability
- Changes are isolated to the appropriate layer
- Dependencies flow downward only
- No circular dependencies

## Feature-Based Application Structure

In a macOS application, each major capability should correspond to its own feature module containing use cases. App-layer entry points (Mac app, CLI) consume these features, promoting modularity and independent development.

This mapping ensures:
- Each feature is independently buildable and testable
- Features can be developed in isolation
- Clear ownership and boundaries between different functionality
- Features can be reused across multiple app entry points or extracted to separate projects

## Summary

- **Apps** are thin entry points — CLI commands, `@Observable` models, server handlers
- **Features** contain **use cases** that orchestrate multi-step workflows
- **Services** hold **shared models**, configuration, and stateful utilities
- **SDKs** are **stateless `Sendable` structs** — single operations, reusable
- **Zero duplication** between CLI and Mac app — both share the same use cases
- **Depth over width** — app layer calls one use case per action
- **@Observable at the app layer only** — models consume streams, use cases own state data

## Further Reading

- **[ARCHITECTURE.md](ARCHITECTURE.md)** — Architecture overview
- **[Layers.md](Layers.md)** — Detailed layer descriptions with examples
- **[Dependencies.md](Dependencies.md)** — Dependency rules and boundaries
- **[Examples.md](Examples.md)** — Reference implementation walkthrough
