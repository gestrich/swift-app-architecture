# View State

How to distinguish view-owned state from model-owned state and where each belongs.

## View State vs Model State

**View state** is state that exists purely because of the UI — user selections, navigation position, sheet visibility, scroll offset. It has no meaning outside the view that displays it.

**Model state** is fetched or created data — API responses, use case outputs, domain objects. It represents the application's understanding of the world and persists regardless of which view is showing.

| Category | Examples | Belongs in |
|----------|----------|------------|
| View state | Selected item, expanded/collapsed, sheet shown, tab index | `@State` / `@AppStorage` in the view |
| Model state | Fetched data, use case output, loaded snapshots | `@Observable` model |

## Selection Belongs in the View

Selection is a view concern. The model provides the data; the view tracks which item the user has chosen. Use `@State` for selection and `@AppStorage` when selection should persist across launches.

**Preferred:**
```swift
struct ContentView: View {
    @Environment(AppModel.self) private var model
    @State private var selectedItem: Item?
    @AppStorage("selectedItemID") private var savedItemID: String = ""

    var body: some View {
        NavigationSplitView {
            List(model.items, selection: $selectedItem) { item in
                ItemRow(item: item)
                    .tag(item)
            }
        } detail: {
            if let selectedItem {
                DetailView(item: selectedItem)
            } else {
                ContentUnavailableView("Select an Item", systemImage: "list.bullet")
            }
        }
        .task {
            if let item = model.items.first(where: { $0.id.uuidString == savedItemID }) {
                selectedItem = item
            }
        }
        .onChange(of: selectedItem) { _, new in
            savedItemID = new?.id.uuidString ?? ""
        }
    }
}
```

**Avoid** — storing selection in the model:
```swift
// ❌ Model tracks which item is selected
@Observable class AppModel {
    var selectedItem: Item? {
        get { ... }
        set { selectItem(newValue) }  // Side effects hidden in setter
    }
}

// ❌ View needs @Bindable or custom Binding to bridge selection
@ViewBuilder var sidebar: some View {
    @Bindable var model = model
    let binding = Binding<Item?>(
        get: { model.selectedItem },
        set: { model.selectItem($0) }
    )
    List(model.items, selection: binding) { ... }
}
```

When the model stores selection, the view needs workarounds (`@Bindable`, custom `Binding`) to create the two-way binding that `List(selection:)` requires. Moving selection to `@State` eliminates this.

## When Selection Triggers Data Loading

Selection is still view state even when choosing an item triggers a model operation. The view owns the selection and tells the model to load data via `.onChange`.

```swift
.onChange(of: selectedProject) { old, new in
    guard let project = new, project.id != old?.id else { return }
    model.loadDetails(for: project)
    savedProjectID = project.id.uuidString
}
```

The model's `loadDetails(for:)` is a data operation — it fetches or loads data into model state. The view just tells the model *when* to do it based on the user's selection.

## Detail Views Driven by Selection

Use `if let` on the view's selection state to control which detail view appears. This makes the view structure follow the selection directly rather than pattern matching on model state.

```swift
// ✅ View structure follows view state
if let selectedProject {
    if let selectedFile {
        FileDetailView(project: selectedProject, file: selectedFile)
            .id(selectedFile.id)
    } else {
        ContentUnavailableView("Select a File", systemImage: "doc")
    }
} else {
    ContentUnavailableView("Select a Project", systemImage: "folder")
}
```

The `.id()` modifier ensures the detail view is recreated when the selection changes, resetting any internal `@State` (see [view-identity.md](view-identity.md)).

## Multi-Level Selection

When selection is hierarchical (selecting a project, then a file within it), each level is a separate `@State`. Changing a parent selection clears child selections.

```swift
@State private var selectedProject: Project?
@State private var selectedFile: ProjectFile?

// ...

.onChange(of: selectedProject) { old, new in
    guard let project = new, project.id != old?.id else { return }
    model.loadProject(project)
    savedProjectID = project.id.uuidString
    selectedFile = nil
    savedFileID = ""
}
```

## Restoring Selection on Launch

Use `.task` to restore selections from `@AppStorage` on first appearance. Guard against redundant model calls when `.onChange` fires for the restored value.

```swift
.task {
    if let project = model.projects.first(where: { $0.id.uuidString == savedProjectID }) {
        selectedProject = project
        model.loadProject(project)
        if !savedFileID.isEmpty,
           let file = model.files.first(where: { $0.id.uuidString == savedFileID }) {
            selectedFile = file
        }
    }
}
.onChange(of: selectedProject) { old, new in
    guard let project = new, project.id != old?.id else { return }
    guard project != model.currentProject else { return }  // Skip if already loaded (from .task)
    model.loadProject(project)
    savedProjectID = project.id.uuidString
    selectedFile = nil
    savedFileID = ""
}
```

The second guard (`project != model.currentProject`) prevents the `.onChange` triggered by `.task` from redundantly calling the model.
