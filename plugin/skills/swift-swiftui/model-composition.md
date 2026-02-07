# Model Composition & Lifecycle

How models compose with each other and manage their initialization.

## Parent/Child Composition

Parent models hold child models as properties. Each model owns its slice of state.

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

## Optional Child Models

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
