# Swift App Architecture

## Overview

This architecture guide describes a layered approach for building Swift applications — particularly macOS and iOS apps that may also expose CLI interfaces. The architecture emphasizes separation of concerns, code reuse across platform entry points, and testability through use case protocols.

## High-Level Architecture

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

## Implementation Strategies

The four layers are a logical structure. How they map to the build system varies by project:

- **Targets in a single package** — Each module is a target in one `Package.swift`, grouped by layer folders (`features/`, `sdks/`, etc.). Good default for most projects.
- **Separate Swift packages** — Each module is its own package with its own `Package.swift`. Common in large or multi-team codebases.
- **Folders only** — Layer structure is organizational folders within a single target. Suitable for small apps or prototypes.

Match the convention already established in the codebase. See [Layers.md — Implementation Strategies](Layers.md#implementation-strategies) for details.

## Layer Breakdown

### 1. Apps Layer (Entry Points)

**Purpose**: Platform-specific entry points that handle I/O and own `@Observable` state.

**Key Characteristics**:
- Executable targets: macOS apps, CLI tools, server handlers
- `@Observable` models live here (for SwiftUI apps) — not in Services or Features
- CLI commands are app-layer constructs, parallel to Mac models
- Minimal business logic; focus on I/O and calling features
- Models consume use case streams and update state for the UI

**State Management**:
- Enum-based state in `@Observable` models (not multiple independent properties)
- Models self-initialize on `init` — no need for views to trigger loading
- Model composition: parent models hold child models as properties
- See [swift-ui.md](swift-ui.md) for detailed model and view guidelines

### 2. Features Layer (Use Cases)

**Purpose**: Multi-step orchestration via use case protocols.

**Key Characteristics**:
- Use cases are structs conforming to `UseCase` or `StreamingUseCase` protocols
- Coordinate multiple SDK clients and services into multi-step operations
- Return `AsyncThrowingStream` for progress reporting
- App-specific business logic and orchestration lives here
- **Not** `@Observable` — that belongs in the Apps layer

**Use Case Protocols** (from a `Uniflow` SDK):
- `UseCase`: Single `run(options:)` → returns one result
- `StreamingUseCase`: Extends `UseCase` with `stream(options:)` → yields progress updates via `AsyncThrowingStream`

### 3. Services Layer (Shared Models & Utilities)

**Purpose**: Shared models, configuration, and stateful utilities used across features.

**Key Characteristics**:
- App-specific models and types
- Configuration persistence (auth tokens, user settings)
- Stateful utilities that don't orchestrate multi-step operations
- Provide types and utilities consumed by features

### 4. SDKs Layer (Stateless, Reusable)

**Purpose**: Low-level, reusable building blocks with no app-specific logic.

**Key Characteristics**:
- Each method wraps a single operation (one CLI command, one API call)
- **Stateless** — use `Sendable` structs for clients, not actors or classes
- Operations return `AsyncThrowingStream` for progress or values for one-shot queries
- Reusable across features and even across projects
- Includes use case protocol definitions (`Uniflow`)

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

See [Dependencies.md](Dependencies.md) for detailed rules and boundaries.

## Key Principles

1. **Use Cases Orchestrate** — Features expose `UseCase` / `StreamingUseCase` conformers that orchestrate multi-step operations across SDKs and services
2. **Zero Duplication** — CLI and Mac app share the same use cases and features; only the app-layer consumption differs
3. **SDKs Are Stateless** — Single operations, `Sendable` structs, no business concepts
4. **Services Are Shared** — Models, configuration, and utilities used across features
5. **@Observable at the App Layer Only** — Models consume use case streams; use cases own state data, models own state transitions

See [Principles.md](Principles.md) for the full principles guide.

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

Both CLI commands and Mac models share the same leaf use cases, ensuring consistent behavior. The difference is in orchestration:
- **Mac app** routes through `@Observable` models so each model can update its observable state
- **CLI** uses use cases directly since there is no observable state to track

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

## Further Reading

- **[Layers.md](Layers.md)** — Detailed layer descriptions with examples
- **[Dependencies.md](Dependencies.md)** — Dependency rules and boundaries
- **[FeatureStructure.md](FeatureStructure.md)** — How to structure feature modules
- **[Examples.md](Examples.md)** — Reference implementation walkthrough
- **[Principles.md](Principles.md)** — Core architectural principles
- **[QuickReference.md](QuickReference.md)** — Decision flowcharts and common patterns
- **[Configuration.md](Configuration.md)** — Configuration and data path management
- **[swift-ui.md](swift-ui.md)** — SwiftUI and model architecture guidelines
- **[code-style.md](code-style.md)** — Code style conventions
- **[documentation.md](documentation.md)** — Documentation workflow and standards
