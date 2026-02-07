# Dependency Rules and Boundaries

This document defines the dependency rules and boundaries between architectural layers.

## Dependency Rules

Dependencies flow **downward only** through the four layers:

```
Apps → Features → Services → SDKs
```

**Allowed dependencies:**
```
Apps → Features, Services, SDKs
Features → Services, SDKs
Services → Other Services, SDKs
SDKs → Other SDKs, external packages only
```

**Forbidden dependencies (never depend upward):**
```
SDKs → Services   ❌
SDKs → Features   ❌
SDKs → Apps        ❌
Services → Features ❌
Services → Apps     ❌
Features → Apps     ❌
```

## Command Flow

The correct flow through the architecture layers:

```
App Layer (CLI command or @Observable model)
    ↓ calls use case
Feature Layer (UseCase / StreamingUseCase)
    ↓ orchestrates multiple SDK/service calls
Service Layer (shared models, config, utilities)
SDK Layer (single operations, stateless clients)
```

## SDK vs Service Layer Boundaries

Understanding the boundary between SDKs and Services is critical for maintaining clean architecture.

### The Rule

**SDKs (e.g., GitSDK):**
- Single operations only (each method = ONE command or API call)
- Typed parameters instead of raw string arrays
- Stateless `Sendable` structs
- NO multi-step workflows
- NO business logic or app-specific concepts

**Services (e.g., CoreService):**
- Shared models and types used across features
- Configuration and persistence (auth tokens, settings)
- Stateful utilities
- NO multi-step orchestration (that belongs in Features)

**Features (e.g., ImportFeature):**
- Multi-step orchestration via `UseCase` / `StreamingUseCase`
- Coordinate SDK clients and services into workflows
- Return `AsyncThrowingStream` for progress reporting

## When Adding New Operations

### Decision Tree: Where Does This Code Go?

Use these questions to determine the correct layer for new code:

#### 1. Is this ONE low-level command or API call?
- ✅ Yes → Add to an **SDK** (e.g., GitSDK, APIClientSDK)
- ❌ No → Continue to question 2

#### 2. Does it orchestrate multiple steps into a workflow?
- ✅ Yes → Add to a **Feature** as a use case
- ❌ No → Continue to question 3

#### 3. Is it a shared model, configuration, or stateful utility?
- ✅ Yes → Add to **Services**
- ❌ No → Continue to question 4

#### 4. Could any project reuse this?
- ✅ Yes → Add to an **SDK** (generic, reusable)
- ❌ No → Add to a **Service** (app-specific shared type)

### Decision Tree: SDK vs Service

**Ask yourself:**

1. **Is this ONE operation (single command, single API call)?**
   - ✅ Yes → SDK
   - ❌ No → It involves multiple steps; continue

2. **Is it a shared model, config, or utility used across features?**
   - ✅ Yes → Service
   - ❌ No → It's orchestration; belongs in a Feature (use case)

3. **Could another project use this as-is?**
   - ✅ Yes → SDK
   - ❌ No → Service

### Example: Adding New Git Operations

1. **Is this ONE git command?**
   - ✅ Yes → Add to GitSDK
   - ❌ No → It's a workflow, add to a Feature use case

2. **Is it a shared git-related model or config?**
   - ✅ Yes → Add to a Service
   - ❌ No → Continue

3. **Could any git-based project use this?**
   - ✅ Yes → Add to GitSDK
   - ❌ No → Add to a specific Service or Feature

## Good vs Bad Boundaries

### Good: SDK is Generic

```swift
// Good: Generic SDK operation — stateless Sendable struct
public struct GitClient: Sendable {
    public func createWorktree(path: String, branch: String) throws {
        // Just execute git command
    }
}

// Feature uses SDK and adds orchestration
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
// Bad: SDK knows about TaskConfig
public struct GitClient: Sendable {
    public func createWorktreeForTask(task: TaskConfig) throws {
        // ❌ SDK shouldn't know about app-specific types
    }
}
```

## Real-World Example: Git Operations

### SDK Layer (GitSDK)
```swift
// Single commands, typed parameters, stateless Sendable struct
public struct GitClient: Sendable {
    public func checkout(branch: String) throws { }
    public func commit(message: String) throws { }
    public func push(branch: String, remote: String = "origin") throws { }
    public func createWorktree(path: String, branch: String) throws { }
}
```

### Service Layer (CoreService)
```swift
// Shared models and configuration
public struct GitConfig {
    public let defaultRemote: String
    public let mainBranch: String
}
```

### Feature Layer (ImportFeature)
```swift
// Orchestrates multiple SDK calls via a use case
public struct PrepareFeatureBranchUseCase: StreamingUseCase {
    private let gitClient: GitClient

    public func stream(options: FeatureOptions) -> AsyncThrowingStream<Progress, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(.step("Checking out main..."))
            try gitClient.checkout(branch: "main")

            let branchName = "feature/\(options.name)"
            continuation.yield(.step("Creating branch \(branchName)..."))
            try gitClient.checkout(branch: branchName)
            try gitClient.push(branch: branchName)

            continuation.yield(.completed)
            continuation.finish()
        }
    }
}
```

### App Layer (MyCLIApp)
```swift
// Calls ONE use case
struct CreateBranchCommand: AsyncParsableCommand {
    func run() async throws {
        let useCase = PrepareFeatureBranchUseCase(gitClient: GitClient())
        for try await progress in useCase.stream(options: .init(name: name)) {
            print(progress)
        }
    }
}
```

## Documentation References

For detailed examples and patterns, see:
- **[Layers.md](Layers.md)** — Comprehensive layer descriptions and rules
- **[Principles.md](Principles.md)** — Core architectural principles
- **[Examples.md](Examples.md)** — Reference implementation walkthrough

## Summary

- Dependencies flow **downward only**: Apps → Features → Services → SDKs
- **Apps** are entry points — CLI commands, `@Observable` models, server handlers
- **Features** contain **use cases** that orchestrate multi-step workflows
- **Services** hold **shared models**, configuration, and stateful utilities
- **SDKs** are **stateless `Sendable` structs** — single operations, generic, reusable
- **No upward dependencies** — keeps architecture clean and maintainable
