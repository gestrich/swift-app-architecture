# Dependency Injection

How to inject models into views using Environment and @State.

## Global Models — Environment

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

## View-Scoped Models — @State

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
