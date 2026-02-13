# Model State

How models represent state and consume use case streams.

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

**Avoid:**
```swift
for try await progress in useCase.stream(options: opts) {
    let outputs = progress.detail?.outputs ?? prior?.outputs
    let metadata = progress.detail?.metadata ?? prior?.metadata
    let result = ImportResult(
        outputs: outputs?.allEntries ?? [:],
        metadata: metadata?.parsed ?? ParsedMetadata()
    )
    state = .operating(RunningUseCase(
        kind: .importing(progress),
        startTime: startTime,
        prior: prior
    ))
    if progress.step == .complete {
        state = .ready(Snapshot(status: .imported(result), ...))
    }
}
```

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

## Why Models Must Not Orchestrate

When a model performs multiple steps directly — fetching data, saving to disk, updating a cache — it becomes responsible for keeping all its state consistent after each step. This leads to "refresh" methods scattered throughout the model as side effects.

**Anti-pattern — model orchestrates and must manually synchronize:**

```swift
@MainActor @Observable
class ImportModel {
    var items: [Item] = []
    var summary: Summary?
    var lastSyncDate: Date?

    func performImport(source: Source) async throws {
        let data = try await apiClient.fetch(source: source)
        try await storage.save(data)
        items = try await storage.loadAll()       // Must remember to refresh
        summary = try await storage.loadSummary() // Must remember to refresh
        lastSyncDate = Date()                     // Must remember to update
    }
}
```

Every new operation must remember to refresh every piece of dependent state. Miss one and the UI shows stale data. As the model grows, these synchronization obligations compound — each method must know about every other piece of state it might affect.

**Preferred — use case handles the operation atomically:**

```swift
// Use case returns one coherent snapshot per yield
public struct ImportUseCase: StreamingUseCase {
    func stream(options: Options) -> AsyncThrowingStream<ImportState, Error> {
        // Fetches, saves, and builds a complete snapshot internally
        // The snapshot includes items, summary, and sync date — all consistent
    }
}

// Model just assigns the result
@MainActor @Observable
class ImportModel {
    var state: ModelState = .uninitialized

    func startImport(source: Source) {
        Task {
            for try await useCaseState in useCase.stream(options: .init(source: source)) {
                state = ModelState(from: useCaseState, prior: state.snapshot)
            }
        }
    }
}
```

The use case yields a complete, consistent state at each step. The model receives it and assigns — no refresh logic, no risk of forgetting to update a dependent property. The observation system picks up the change and the view renders the new state.

**Key insight:** Use cases make multi-step operations atomic from the model's perspective. The model never lands in a half-updated state because it never manages the individual steps.
