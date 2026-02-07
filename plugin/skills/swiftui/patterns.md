# SwiftUI Patterns — Detail

Advanced SwiftUI patterns for model composition, dependency injection, view identity, and data modeling.

## Model Composition

Parent models can hold child models as properties. Each model owns its slice of state.

**Core principles:**
1. **Child models own their state** — single source of truth for their domain
2. **Parent models must not duplicate child state** — access through the child model reference
3. **Models call models, not use cases calling use cases** — ensures each model updates its own state

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
    let servicesModel: ServicesModel
    enum State {
        case idle
        case stoppingPrimary(PrimaryProgress)
        case waitingForServices
        case stopped
    }
}
```

**Composite operations — models call models:**

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

**Why not use case composition?** If a parent use case called a child use case directly, the child model would never know the operation happened — its state would be stale.

**Views access child state through the child model:**

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

## Optional Child Models for Configuration

For features that require configuration (API credentials, tokens), prefer optional child models over models that exist in an "unconfigured" state. A model that doesn't exist is clearer than one that can't do anything.

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
| `integrationModel.state = .loading` | Child view re-renders (internal state changed) |

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

## Dependency Injection

### Global Models — Environment

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

Inject at the root:

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

### View-Scoped Models — @State

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

Use `.id()` when state or identity falls outside normal data-driven view updates.

**When to use:**
- `@State` initialized in `init()` with `State(initialValue:)` — only runs once per view identity
- `.task {}`, `.onAppear`, `.onDisappear` that need to re-run when dependencies change
- When you want to reset ALL internal view state (scroll position, focus, animations)

**How it works:** When `.id()` receives a new value, SwiftUI destroys the old view and creates a fresh one. All `@State` resets, all lifecycle hooks re-run.

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

## Data Models

SwiftUI should be driven by well-formed structs representing domain data. These are distinct from `@Observable` models.

- Use structs for domain data from services
- If a view has many properties for small pieces of data, a model struct is missing
- Data fetched together for a view should be bundled in a struct

```swift
struct Repository {
    let name: String
    let url: URL
    let lastCommitDate: Date

    var displayDate: String {
        lastCommitDate.formatted(date: .abbreviated, time: .omitted)
    }
}

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

If a view requires data to function, don't show the view without that data.

- Make data a non-optional requirement (e.g., `let filePath: URL`)
- Only navigate to the view when data is available
- Show a placeholder from the **parent** if data isn't ready

```swift
// ❌ Bad: View handles missing data
struct FileEditorView: View {
    let filePath: URL?  // Optional = unclear contract
    var body: some View {
        if let filePath { Text("Editing: \(filePath.path)") }
        else { Text("No file selected") }
    }
}

// ✅ Good: View requires data, parent decides when to show it
struct FileEditorView: View {
    let filePath: URL  // Non-optional = clear contract

    var body: some View {
        Text("Editing: \(filePath.path)")
    }
}

struct ParentView: View {
    @State private var selectedFile: URL?

    var body: some View {
        if let selectedFile {
            FileEditorView(filePath: selectedFile)
        } else {
            Text("Select a file to edit").foregroundStyle(.secondary)
        }
    }
}
```

## Source Documentation

- **[swift-ui.md](../../../docs/architecture/swift-ui.md)** — Full SwiftUI architecture guidelines
