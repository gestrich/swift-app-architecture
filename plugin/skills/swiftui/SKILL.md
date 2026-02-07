---
name: swiftui
description: Provides SwiftUI Model-View architecture patterns including enum-based state, model composition, dependency injection, view identity, and observable model conventions. Use when building SwiftUI views, creating observable models, implementing state management, or connecting use cases to the UI.
user-invocable: true
---

# SwiftUI Patterns

SwiftUI architecture patterns for the Apps layer. Models live **only in the Apps layer** — not in Services or Features. They consume use case streams and update state for the UI.

## Which Document Do I Need?

| Situation | Document |
|-----------|----------|
| Understanding Model-View basics and enum-based state | Start here |
| Model composition, dependency injection, view identity, prerequisite data | [patterns.md](patterns.md) |

## Architecture: Model-View (MV)

Prefer **Model-View** over MVVM. Views connect directly to observable models.

- No dedicated ViewModels for individual views
- Observable models live in the Apps layer, spanning many views
- Views observe and interact with models directly
- Models contain minimal logic — monitor use case streams and update state
- Business logic belongs in Features (use cases) and SDKs (clients), not models

## Enum-Based State

Use enums to represent model state rather than multiple independent properties.

**Why enums:**
1. **Impossible invalid states** — associated values guarantee only valid combinations
2. **Exhaustive handling** — switch statements force handling every case
3. **Clear state transitions** — one case, not a combination of booleans and optionals
4. **Easier to reason about** — each case documents exactly what data is available

**Preferred:**
```swift
enum ModelState {
    case uninitialized
    case loading(prior: Snapshot?)
    case ready(Snapshot)
    case operating(UseCaseState, prior: Snapshot?)
}
```

**Avoid:**
```swift
class Model {
    var isLoading = false
    var isOperating = false
    var snapshot: Snapshot?
    var useCaseState: UseCaseState?
    var prior: Snapshot?
    // What if isLoading && isOperating? What if snapshot != nil && isLoading?
}
```

## Model → Use Case State Flow

Models receive state from use cases and assign it directly to a state enum. Avoid excessive translations, mapping, or reconstruction.

**Preferred:**
```swift
@MainActor @Observable
class ImportModel {
    var state: ModelState = .uninitialized

    func startImport() {
        let prior = state.snapshot
        Task {
            for try await useCaseState in useCase.stream(options: opts) {
                state = ModelState(from: useCaseState, prior: prior)
            }
        }
    }
}
```

**Avoid** complex mapping in the model — if the model needs excessive transformation, the use case should return better-structured state.

## State Ownership

**Use cases own state data; models own state transitions.**

- Use cases define and return snapshot types (e.g., `ImportSnapshot`, `SyncSnapshot`)
- Models define their enum cases for app-layer concerns (`uninitialized`, `loading`, `operating`, `ready`)
- Associated values in model state come directly from use case types

```swift
enum ModelState {
    case uninitialized
    case loading(prior: UseCaseSnapshot?)
    case ready(UseCaseSnapshot)
    case operating(UseCaseState, prior: UseCaseSnapshot?)
}
```

**Code smell** — switching on use case state to create model state with similar cases:

```swift
// ❌ Bad: Redundant transformation
for try await useCaseState in useCase.stream() {
    switch useCaseState {
    case .importing(let progress):
        state = .operating(step: progress.step, startTime: progress.startTime)
    case .completed(let id):
        state = .ready(status: .success(id: id))
    }
}

// ✅ Good: Direct assignment via init
for try await useCaseState in useCase.stream() {
    state = ModelState(from: useCaseState, prior: prior)
}
```

The `ModelState.init(from:prior:)` should be trivial:

```swift
init(from useCaseState: UseCaseState, prior: Snapshot?) {
    if let snapshot = useCaseState.completedSnapshot {
        self = .ready(snapshot)
    } else {
        self = .operating(useCaseState, prior: prior)
    }
}
```

## Key Rules

- `@MainActor` on all `@Observable` models — observation may fail silently on background threads
- Store root models in the `App` struct, not individual views, to avoid re-initialization on view rebuilds
- `@Observable` exists **only** in the Apps layer

## Source Documentation

- **[swift-ui.md](../../../docs/architecture/swift-ui.md)** — Full SwiftUI architecture guidelines
