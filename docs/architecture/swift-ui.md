# SwiftUI Architecture Guidelines

## Observation

Use `@Observable` for state management. `@Observable` models live **only in the Apps layer** — not in Services or Features. They exist where UI binding is needed (Mac apps) and consume use case streams to update state for the UI.

## Architecture: Model-View (MV)

Prefer **Model-View** over MVVM. Views connect directly to observable models.

**Key principles:**
- No dedicated ViewModels for individual views
- Observable models live in the Apps layer, spanning many views
- Views observe and interact with models directly
- Models contain minimal logic — their role is to monitor use case streams and update state
- Business logic belongs in Features (use cases) and SDKs (clients), not models

## Model State Patterns

### Enum-Based State

Use enums to represent model state rather than multiple independent properties.

**Why enums:**

1. **Impossible invalid states**: An enum with associated values guarantees only valid combinations exist.
2. **Exhaustive handling**: Switch statements force you to handle every case. Adding a new state is a compile-time change, not a runtime bug.
3. **Clear state transitions**: The current state is always unambiguous — one case, not a combination of booleans and optionals.
4. **Easier to reason about**: Reading `case operating(UseCaseState, prior: Snapshot?)` tells you exactly what data is available during an operation.

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

### Model → Use Case State Flow

When consuming use case streams, models should do the minimum work necessary: receive state from the use case and assign it directly to a state enum. Avoid excessive translations, mapping, or reconstruction of state in the model layer.

**Preferred pattern:**
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

**Avoid this pattern:**
```swift
for try await progress in useCase.stream(options: opts) {
    // Excessive mapping and transformation
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

The use case should yield state that the model can use directly. If the model needs to do complex mapping, that's a signal the use case should be returning better-structured state.

### State Ownership

**Use cases own state data; models own state transitions.**

- Use cases define and return snapshot types (e.g., `ImportSnapshot`, `SyncSnapshot`)
- Models define their enum cases for app-layer concerns (`uninitialized`, `loading`, `operating`, `ready`)
- Associated values in model state should come directly from use case types

```swift
enum ModelState {
    case uninitialized
    case loading(prior: UseCaseSnapshot?)
    case ready(UseCaseSnapshot)
    case operating(UseCaseState, prior: UseCaseSnapshot?)
}
```

**Code smell**: Switching on use case state to create model state with similar cases.

```swift
// ❌ Bad: Redundant transformation
for try await useCaseState in useCase.stream() {
    switch useCaseState {
    case .importing(let progress):
        state = .operating(step: progress.step, startTime: progress.startTime)
    case .completed(let id):
        state = .ready(status: .success(id: id))
    case .failed(let id, let reason):
        state = .ready(status: .failed(id: id, reason: reason))
    }
}

// ✅ Good: Direct assignment via init
for try await useCaseState in useCase.stream() {
    state = ModelState(from: useCaseState, prior: prior)
}
```

The `ModelState.init(from:prior:)` should be trivial — typically just checking if the use case completed:

```swift
init(from useCaseState: UseCaseState, prior: Snapshot?) {
    if let snapshot = useCaseState.completedSnapshot {
        self = .ready(snapshot)
    } else {
        self = .operating(useCaseState, prior: prior)
    }
}
```

## Model Composition

Parent models can hold child models as properties. Each model owns its slice of state.

**Core Principles:**

1. **Child models own their state.** The child model is the single source of truth for its domain.
2. **Parent models must not duplicate child state.** Access child state through the child model reference.
3. **Models call other models, not use cases calling use cases.** When operations span multiple domains, the parent model calls child model methods. This ensures each model updates its own state.

```swift
// ❌ BAD: Parent duplicates child state
@MainActor @Observable
final class ParentModel {
    var state: State
    enum State {
        case stopping(services: ServicesProgress)  // Duplicated from child!
    }
}

// ✅ GOOD: Parent holds child model, accesses its state
@MainActor @Observable
final class ParentModel {
    var state: State
    let servicesModel: ServicesModel  // Child model reference
    enum State {
        case idle
        case stoppingPrimary(PrimaryProgress)
        case waitingForServices
        case stopped
    }
}
```

**Models call models for composite operations:**

```swift
@MainActor @Observable
final class ParentModel {
    private(set) var state: State = .idle
    let servicesModel: ServicesModel

    func stopAll() async throws {
        state = .stoppingPrimary(.init())
        for try await progress in stopPrimaryUseCase.stream() {
            state = .stoppingPrimary(progress)
        }

        state = .waitingForServices
        try await servicesModel.stopAll()  // Call child model, not use case

        state = .stopped
    }
}
```

**Why not use case composition?** If a parent use case called a child use case directly, the child model would never know the operation happened — its state would be stale. By routing through models, each model stays responsible for its state.

**Views access child state through child model:**

```swift
struct ParentView: View {
    @Bindable var model: ParentModel

    var body: some View {
        switch model.state {
        case .waitingForServices:
            ServicesProgressView(model: model.servicesModel)
        // ...
        }
    }
}
```

### Optional Child Models for Configuration

For features that require configuration (API credentials, tokens, etc.), prefer optional child models over models that exist in an "unconfigured" state.

A model that doesn't exist is clearer than a model that exists but can't do anything. Views naturally handle this via `if let`.

```swift
@MainActor @Observable
class AppModel {
    var integrationModel: IntegrationModel?  // nil if not configured

    init() {
        if let config = try? IntegrationConfiguration.load() {
            self.integrationModel = IntegrationModel(config: config)
        }
    }

    func configure(_ config: IntegrationConfiguration) {
        integrationModel = IntegrationModel(config: config)
    }

    func clearIntegration() {
        integrationModel = nil
    }
}
```

**View conditional rendering:**

```swift
struct ContentView: View {
    @State var appModel = AppModel()

    var body: some View {
        if let integrationModel = appModel.integrationModel {
            IntegrationView(model: integrationModel)
        } else {
            ConfigureIntegrationPrompt()
        }
    }
}
```

**Two levels of observation:**

| Change | What Updates |
|--------|--------------|
| `appModel.integrationModel = newModel` | Parent view re-renders (model existence changed) |
| `integrationModel.state = .loading` | Child view re-renders (model's internal state changed) |

**Requirements:**

- Use `@MainActor` on all models — observation may fail silently for changes on background threads
- Store root models in the `App` struct, not individual views, to avoid re-initialization on view rebuilds

## Model Lifecycle

Models self-initialize on `init`. This eliminates the need for views to trigger loading on appear.

```swift
@MainActor @Observable
class ImportModel {
    var state: ModelState = .loading(prior: nil)
    private let useCase: ImportStatusUseCase

    init(useCase: ImportStatusUseCase) {
        self.useCase = useCase
        Task { await load() }
    }

    private func load() async {
        let snapshot = try? await useCase.fetchStatus()
        state = .ready(snapshot ?? .empty)
    }
}
```

**When child models affect parent state**, refresh the parent when the child changes:

```swift
@MainActor @Observable
class AppModel {
    var state: AppState = .loading
    var integrationModel: IntegrationModel? {
        didSet { Task { await refreshState() } }
    }

    init() {
        Task { await refreshState() }
    }

    private func refreshState() async {
        let status = await integrationModel?.fetchStatus()
        state = .ready(AppSnapshot(integration: status))
    }
}
```

This pattern keeps views simple — they observe state without triggering loads.

## Model & Dependency Injection

### Global Models

Inject shared models via `Environment`:

```swift
@MainActor @Observable
class DataModel {
    var items: [Item] = []
}

struct ItemListView: View {
    @Environment(DataModel.self) var dataModel

    var body: some View {
        List(dataModel.items) { item in
            Text(item.name)
        }
    }
}
```

Inject models at the root:

```swift
@main
struct MyApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .environment(appModel.integrationModel)
        }
    }
}
```

### View-Scoped Models

For models tied to a view's lifecycle, use `@State` with initialization in `init`:

```swift
struct DetailView: View {
    let item: Item
    @State private var model: DetailModel

    init(item: Item) {
        self.item = item
        _model = State(initialValue: DetailModel(item: item))
    }

    var body: some View {
        ContentView()
            .environment(model)
            .id(item)  // Recreate when item changes
    }
}
```

**Handling dependency changes:**
- Use `.id(dependency)` when the entire view should reset on change
- Use `.onChange(of: dependency)` when only the model needs updating while preserving other state

## View Identity with `.id()`

The `.id()` modifier is used when there is state or identity that falls outside the normal data-driven view updates.

**When to use `.id()`:**
- When a view has `@State` initialized in `init()` using `State(initialValue:)` — this only runs once per view identity
- When a view uses `.task {}`, `.onAppear`, or `.onDisappear` that need to re-run when dependencies change
- When you want to reset ALL internal view state (scroll position, focus, animations, derived state, etc.)

**How it works:**
- SwiftUI normally reuses view instances when the view hierarchy updates
- When `.id()` receives a new value, SwiftUI destroys the old view instance completely and creates a fresh one
- All `@State` variables are reset to their initial values
- All lifecycle hooks (`.task`, `.onAppear`) run again

```swift
struct FileViewerWrapper: View {
    let file: FileDisplayInfo
    @State private var blameData: FileBlameData?

    var body: some View {
        CodeView(...)
            .task { await loadBlame() }
    }
    .id(file)  // Reset when file changes
}
```

Without `.id(file)`, changing the `file` property would update the view's body, but `@State` variables would retain old values and `.task` wouldn't re-run.

## Data Models

SwiftUI should be driven by well-formed structs that represent domain data. These are lowercase "models" (distinct from the `@Observable` Model in Model-View).

**Guidelines:**
- Use structs to represent domain data from services
- Models can have methods to extract or compute details
- SwiftUI is state-driven: views should be a simple reflection of data from models
- If a view has many properties for small pieces of data, that's a sign a model struct is missing
- Data that is fetched together for a view should generally be bundled together in a struct

```swift
// Domain model struct
struct Repository {
    let name: String
    let url: URL
    let lastCommitDate: Date

    var displayDate: String {
        lastCommitDate.formatted(date: .abbreviated, time: .omitted)
    }
}

// View displays structured data
struct RepositoryRow: View {
    let repository: Repository

    var body: some View {
        VStack(alignment: .leading) {
            Text(repository.name)
            Text(repository.displayDate)
        }
    }
}
```

## Prerequisite Data

**Principle:** If a view requires data to function, don't show the view without that data.

**Don't:**
- Show empty views waiting for data
- Use placeholder/dummy data
- Fill views with nil checks and optional handling
- Display views in invalid states

**Do:**
- Make data a non-optional requirement (e.g., `let filePath: URL`)
- Only navigate to/present the view when data is available
- Show a placeholder view from the parent if data isn't ready
- Make flows inaccessible until prerequisites are met

```swift
// Bad: View handles missing data with optionals and nil checks
struct FileEditorView: View {
    let filePath: URL?

    var body: some View {
        if let filePath = filePath {
            Text("Editing: \(filePath.path)")
        } else {
            Text("No file selected")
        }
    }
}

// Good: View requires data, parent decides whether to show it
struct FileEditorView: View {
    let filePath: URL  // Non-optional requirement

    var body: some View {
        Text("Editing: \(filePath.path)")
    }
}

// Parent handles the conditional logic
struct ParentView: View {
    @State private var selectedFile: URL?

    var body: some View {
        VStack {
            if let selectedFile = selectedFile {
                FileEditorView(filePath: selectedFile)
            } else {
                Text("Select a file to edit")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

**Benefits:**
- Views are simpler and focused on their primary purpose
- Data requirements are explicit in the API (non-optional parameters)
- Impossible states are not representable
- Parent views control when child views appear
- No defensive nil checking throughout the view hierarchy

## Further Reading

- **[ARCHITECTURE.md](ARCHITECTURE.md)** — Architecture overview
- **[Layers.md](Layers.md)** — Detailed layer descriptions with examples
- **[Examples.md](Examples.md)** — Reference implementation walkthrough
- **[Configuration.md](Configuration.md)** — Configuration and data path management
