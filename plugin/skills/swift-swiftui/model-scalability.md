# Model Scalability

How to keep models lean when entities expose heavyweight or streaming data.

## The Problem

In MV, models are the single source of truth and multiple views observe the same models. This works well until entities carry heavyweight data — a list of 1,000 PRs where each can expose a large streaming log, for example.

If every entity model eagerly retains heavyweight data:

- **High memory** — many large objects alive simultaneously
- **Unnecessary churn** — streaming updates for objects the user isn't viewing
- **Models drift toward UI containers** — carrying transient data that only matters while a specific screen is visible

The tension: models should represent durable app state, not mirror transient UI lifecycles like "the log sheet is open right now."

## Approach 1: Model as Provider

The entity model does not retain heavyweight sub-state. Instead, it returns it on demand.

```swift
@MainActor @Observable
class PRModel {
    let id: String
    var title: String
    var status: PRStatus
    // No logModel property — kept lean

    private let logUseCaseFactory: () -> LogStreamUseCase

    func makeLogModel() -> LogModel {
        LogModel(useCase: logUseCaseFactory())
    }
}
```

The view creates and holds the heavy object for as long as needed:

```swift
struct PRDetailView: View {
    var prModel: PRModel
    @State private var logModel: LogModel?

    var body: some View {
        VStack {
            PRSummary(model: prModel)
            if let logModel {
                LogStreamView(model: logModel)
            }
        }
        .sheet(isPresented: $showingLog) {
            LogSheet(model: logModel!)
        }
        .onChange(of: showingLog) { _, showing in
            logModel = showing ? prModel.makeLogModel() : nil
        }
    }
}
```

**When the view disappears, the heavy object deallocates.**

**Best for:** heavyweight data that is primarily needed on a focused detail screen and not broadly shared.

**Tradeoff:** if the heavy child needs to coordinate with ongoing activity in the parent model, you need explicit lifecycle management (see Approach 2).

## Approach 2: Activation / Hydration

When the heavyweight child is tightly coupled to ongoing operations in the parent, the parent model can own it — but only while it's relevant.

The parent model has a lightweight concept of being *active* or *hydrated*:

```swift
@MainActor @Observable
class PRModel {
    let id: String
    var title: String
    var status: PRStatus
    private(set) var logModel: LogModel?

    private let logUseCaseFactory: () -> LogStreamUseCase

    func activate() {
        guard logModel == nil else { return }
        logModel = LogModel(useCase: logUseCaseFactory())
    }

    func deactivate() {
        logModel = nil
    }
}
```

This frames the behavior as a **resource policy**, not a UI event:

- "Only the active entity is fully hydrated."
- "Inactive entities remain lightweight."

The naming should be generic and reusable — not tied to one view:

| Good | Avoid |
|------|-------|
| `activate()` / `deactivate()` | `onSheetOpened()` / `onSheetClosed()` |
| `beginHydration()` / `endHydration()` | `userTappedLog()` |
| `setFocus(isFocused:)` | `logSheetVisible(_:)` |

**Best for:** heavyweight child data that must coordinate with the parent model's ongoing operations.

**Tradeoff:** the model includes a notion of "active context." This is a resource/lifecycle policy that happens to align with user focus — not UI state leaking into the model.

## Choosing Between Approaches

| Factor | Approach 1 (Provider) | Approach 2 (Activation) |
|--------|----------------------|------------------------|
| Child needs parent coordination | No | Yes |
| Multiple views share the child | Unlikely | Possible |
| Lifetime management | View owns it via `@State` | Model owns it via activate/deactivate |
| Model complexity | Lower — model stays stateless about the child | Higher — model manages child lifecycle |
