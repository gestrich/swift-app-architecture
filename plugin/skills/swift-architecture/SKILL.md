---
name: swift-architecture
description: Provides the 4-layer Swift app architecture (Apps, Features, Services, SDKs) including layer responsibilities, dependency rules, placement guidance, feature creation, configuration, code style, and reference examples. Use when the user asks about the architecture, needs to understand layers, wants to add code, create features, or review architectural compliance.
user-invocable: true
---

# Swift App Architecture

A layered architecture for building Swift applications — macOS apps, CLI tools, and servers — emphasizing separation of concerns, code reuse across entry points, and testability through use case protocols.

## Which Document Do I Need?

| Situation | Document |
|-----------|----------|
| Understanding the architecture overview | Start here |
| Understanding why the architecture works this way | [principles.md](principles.md) |
| Deciding which layer code belongs in | [layers.md](layers.md) |
| Creating a new feature module | [creating-features.md](creating-features.md) |
| Setting up configuration or data paths | [configuration.md](configuration.md) |
| Writing or reviewing code style | [code-style.md](code-style.md) |
| Seeing a full end-to-end implementation | [examples.md](examples.md) |

## 4-Layer Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         Apps Layer                           │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────┐ │
│  │ MyMacApp         │  │ MyCLIApp         │  │ MyServer   │ │
│  │ (@Observable     │  │ (ArgumentParser  │  │ App        │ │
│  │  models + views) │  │  commands)       │  │            │ │
│  └──────────────────┘  └──────────────────┘  └────────────┘ │
│          Entry points, I/O, platform-specific concerns       │
└────────────────────────┬────────────────────────────────────┘
                         │ uses
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                       Features Layer                         │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────┐ │
│  │ ImportFeature    │  │ ExportFeature    │  │ Sync       │ │
│  │ (UseCases)       │  │ (UseCases)       │  │ Feature    │ │
│  └──────────────────┘  └──────────────────┘  └────────────┘ │
│   Multi-step orchestration via UseCase / StreamingUseCase    │
└────────────────────────┬────────────────────────────────────┘
                         │ uses
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                       Services Layer                         │
│  ┌───────────────┐  ┌──────────────┐  ┌──────────────────┐ │
│  │ CoreService   │  │ AuthService  │  │ StorageService   │ │
│  │ • Models      │  │ • Config     │  │ • Persistence    │ │
│  │ • Shared      │  │ • Tokens     │  │ • File paths     │ │
│  │   types       │  │              │  │                  │ │
│  └───────────────┘  └──────────────┘  └──────────────────┘ │
│      Models, configuration, shared stateful utilities        │
└────────────────────────┬────────────────────────────────────┘
                         │ uses
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                        SDKs Layer                            │
│  ┌───────────────┐  ┌──────────────┐  ┌──────────────────┐ │
│  │ API Clients   │  │ CLI Wrappers │  │ Utility SDKs     │ │
│  │ (REST, etc.)  │  │ (git, etc.)  │  │ (parsing, etc.)  │ │
│  └───────────────┘  └──────────────┘  └──────────────────┘ │
│     Stateless Sendable structs — reusable across projects    │
└─────────────────────────────────────────────────────────────┘
```

### Apps Layer (Entry Points)

Platform-specific entry points that handle I/O and own `@Observable` state.

- Executable targets: macOS apps, CLI tools, server handlers
- `@Observable` models live here — not in Services or Features
- Minimal business logic; focus on I/O and calling features
- Enum-based state in `@Observable` models (not multiple independent properties)

### Features Layer (Use Cases)

Multi-step orchestration via use case protocols.

- Use cases are structs conforming to `UseCase` or `StreamingUseCase` protocols
- Coordinate multiple SDK clients and services into multi-step operations
- Return `AsyncThrowingStream` for progress reporting
- **Not** `@Observable` — that belongs in the Apps layer

### Services Layer (Shared Models & Utilities)

Shared models, configuration, and stateful utilities used across features.

- App-specific models and types
- Configuration persistence (auth tokens, user settings)
- Stateful utilities that don't orchestrate multi-step operations

### SDKs Layer (Stateless, Reusable)

Low-level, reusable building blocks with no app-specific logic.

- Each method wraps a single operation (one CLI command, one API call)
- **Stateless** — use `Sendable` structs, not actors or classes
- Reusable across features and even across projects

## Implementation Strategies

The four layers are a logical structure. How they map to the build system varies:

- **Targets in a single package** — Each module is a target in one `Package.swift`, grouped by layer folders. Good default for most projects.
- **Separate Swift packages** — Each module has its own `Package.swift`. Common in large or multi-team codebases.
- **Folders only** — Organizational folders within a single target. Suitable for small apps or prototypes.

**Always match the convention already established in the codebase.** If starting fresh and unsure, ask which approach to use.

## Dependency Flow

Dependencies flow **downward only**:

```
Apps → Features → Services → SDKs
```

- **Apps** depend on Features, Services, and SDKs
- **Features** depend on Services and SDKs
- **Services** depend on other Services and SDKs
- **SDKs** depend only on other SDKs or external packages
- Never depend upward
- Features never depend on other features — compose at the App layer

## Key Principles

1. **Depth Over Width** — App-layer code calls ONE use case per user action; orchestration lives in Features
2. **Zero Duplication** — CLI and Mac app share the same use cases and features
3. **Use Cases Orchestrate** — Features expose `UseCase` / `StreamingUseCase` conformers for multi-step operations
4. **SDKs Are Stateless** — Single operations, `Sendable` structs, no business concepts
5. **@Observable at the App Layer Only** — Models consume use case streams; use cases own state data, models own state transitions

For the reasoning behind these principles, see [principles.md](principles.md).

## Data Flow Patterns

### CLI
```
useCase.stream() → print progress
useCase.run()    → print result
```

### Mac App
```
useCase.stream() → @Observable model → View
```

Both CLI commands and Mac models share the same use cases. The difference:
- **Mac app** routes through `@Observable` models to update observable state
- **CLI** uses use cases directly since there is no observable state

## Quick Reference: Where to Put Things

| What you're adding | Where it goes | Layer |
|-------------------|---------------|-------|
| SwiftUI views | `apps/MyMacApp/Views/` | Apps |
| `@Observable` models | `apps/MyMacApp/Models/` | Apps |
| CLI commands | `apps/MyCLIApp/` | Apps |
| Server handlers | `apps/MyServerApp/` | Apps |
| Multi-step orchestration | `features/MyFeature/usecases/` | Features |
| Feature-specific types | `features/MyFeature/services/` | Features |
| Shared data models | `services/CoreService/Models/` | Services |
| Configuration / settings | `services/AuthService/`, `services/StorageService/` | Services |
| Stateful shared utility | `services/MyService/` | Services |
| Single API call wrapper | `sdks/APIClientSDK/` | SDKs |
| Single CLI command wrapper | `sdks/CLISDK/`, `sdks/GitSDK/` | SDKs |
| Use case protocol definitions | `sdks/Uniflow/` | SDKs |

For decision flowcharts and boundary guidance, see [layers.md](layers.md).

## Quick Checks

**Before adding code:**
- [ ] Am I putting this in the right layer?
- [ ] Does this violate any dependency rules?
- [ ] Is `@Observable` only in the Apps layer?
- [ ] Is orchestration logic in Features (use cases), not in Apps or Services?

**Before creating a new module:**
- [ ] Is this really needed or can I extend an existing module?
- [ ] What layer does this belong to?
- [ ] Does it follow the `<Name><Layer>` naming convention?
- [ ] Am I using the same implementation strategy (packages, targets, or folders) as the rest of the project?


## Performance Patterns

### Parallel Processing
- Use cases can process work concurrently using Swift Concurrency
- Independent operations can run in parallel within a streaming use case

### Caching
- Commit-based caching invalidates automatically when code changes
- Per-module granularity minimizes redundant work
- Three-level cache hierarchy: whole-repo snapshots, per-module caches, dependency graph caches

### Lazy Loading
- UI uses `LazyVStack` / `LazyHStack` for efficient scrolling
- Data loaded on-demand

### Progress Reporting
- Use cases report real-time progress via `AsyncThrowingStream`
- Apps display progress however they choose (SwiftUI indicators, CLI terminal output, server logs)

## Testing Strategy

### Unit Tests
- Test individual parsers and utilities
- Test graph/dependency algorithms
- Test cache invalidation logic

### Integration Tests
- End-to-end use case workflows
- Cache hit/miss scenarios

### Manual Testing via CLI
- Use CLI commands against real data
- Verify results match expectations

## Common Questions

**I'm adding a new feature to the app. Where does it go?**
Create three things:
1. **Feature module** in `features/MyFeature/` — use cases that orchestrate the logic
2. **Mac app model** in `apps/MyMacApp/Models/` — `@Observable` model consuming use case streams
3. **CLI command** in `apps/MyCLIApp/` — command consuming use cases directly (if CLI access needed)

**Where do `@Observable` models go?**
Always in the **Apps layer** (`apps/MyMacApp/Models/`). Never in Features or Services.

**Can a feature depend on another feature?**
No. If two features need shared logic, extract to a **Service** or **SDK**. Compose at the **App layer**.

**How do I share code between CLI and Mac app?**
Put all shared logic in **Features** (use cases). Both CLI commands and Mac models consume the same use cases.

## Documentation Workflow

Documentation follows this directory structure:

```
docs/
├── proposed/        # In-progress specs and proposals
└── completed/       # Finished implementation docs
```

- Create a proposal in `docs/proposed/` when planning new work
- Move to `docs/completed/` once implementation is merged
- `plugin/skills/` is the **single source of truth** for architecture documentation
