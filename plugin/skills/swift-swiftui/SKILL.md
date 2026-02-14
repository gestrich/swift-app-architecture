---
name: swift-swiftui
description: Provides SwiftUI Model-View architecture patterns including enum-based state, model composition, dependency injection, view state vs model state, view identity, and observable model conventions. Use when building SwiftUI views, creating observable models, implementing state management, or connecting use cases to the UI.
user-invocable: true
---

# SwiftUI Patterns

SwiftUI follows **Model-View (MV)** — not MVVM. Views connect directly to `@Observable` models that live **only in the Apps layer**. Models monitor use case streams and update state for the UI. Business logic belongs in Features (use cases) and SDKs (clients), not models.

**Key rules:**
- No dedicated ViewModels per view — models span many views
- `@MainActor` on all `@Observable` models
- Store root models in the `App` struct to avoid re-initialization on view rebuilds

## Detailed Guides

| Topic | When to Use | Document |
|-------|-------------|----------|
| Enum-based state, state flow, state ownership | Defining model state or consuming use case streams | [model-state.md](model-state.md) |
| Parent/child models, optional models, lifecycle | Composing models or managing model initialization | [model-composition.md](model-composition.md) |
| Environment injection, view-scoped models | Injecting models into views | [dependency-injection.md](dependency-injection.md) |
| View state vs model state, selection ownership | Deciding what belongs in `@State` vs `@Observable` models | [view-state.md](view-state.md) |
| `.id()` modifier for view reset | Resetting view state when dependencies change | [view-identity.md](view-identity.md) |
| Heavyweight state, model scalability | Managing memory when entities carry large or streaming data | [model-scalability.md](model-scalability.md) |
| Domain structs, prerequisite data | Creating data types or handling missing data in views | [data-models.md](data-models.md) |
| Alerts | Using SwiftUI's `.alert` API | [alerts.md](alerts.md) |

## Source Documentation

- **[swift-ui.md](../../../docs/architecture/swift-ui.md)** — Full SwiftUI architecture guidelines
