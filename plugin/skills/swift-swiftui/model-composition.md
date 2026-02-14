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

## Child-to-Parent State Propagation

When child state changes affect the parent, the approach depends on what changed:

**Child model instance replaced** — route through the parent, since the parent owns the reference:

```swift
@MainActor @Observable
class AppModel {
    var settingsModel: SettingsModel? {
        didSet { Task { await refreshState() } }
    }

    func configure(_ config: SettingsConfiguration) {
        settingsModel = SettingsModel(config: config)
    }
}
```

**Child model internal state changes** — the child provides a factory method that returns a new `AsyncStream` per caller. Each subscriber gets its own independent stream, avoiding the single-consumer pitfall of a shared `AsyncStream` property:

```swift
@MainActor @Observable
class SettingsModel {
    private(set) var current: Settings {
        didSet {
            for continuation in continuations.values {
                continuation.yield(current)
            }
        }
    }
    private var continuations: [UUID: AsyncStream<Settings>.Continuation] = [:]

    func observeChanges() -> AsyncStream<Settings> {
        let id = UUID()
        let (stream, continuation) = AsyncStream.makeStream(of: Settings.self)
        continuations[id] = continuation
        continuation.onTermination = { [weak self] _ in
            self?.continuations.removeValue(forKey: id)
        }
        return stream
    }

    func apply(_ setting: Setting) {
        current = current.applying(setting)
    }
}

@MainActor @Observable
class AppModel {
    let settingsModel: SettingsModel
    private let dataUseCase: FetchDataUseCase

    init(settingsModel: SettingsModel, dataUseCase: FetchDataUseCase) {
        self.settingsModel = settingsModel
        self.dataUseCase = dataUseCase
        Task { await observeSettingsModel() }
    }

    private func observeSettingsModel() async {
        for await settings in settingsModel.observeChanges() {
            for try await snapshot in dataUseCase.stream(settings: settings) {
                state = .ready(snapshot)
            }
        }
    }
}
```

Views call `settingsModel.apply()` directly — the child model remains fully usable on its own. The parent subscribes at construction time without the child knowing who is listening.

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

