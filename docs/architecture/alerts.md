# Alerts

SwiftUI alert patterns and conventions.

## Basic Alert

The simplest alert uses a `Bool` binding to control visibility:

```swift
struct SettingsView: View {
    @State private var isResetConfirmationPresented = false

    var body: some View {
        Button("Reset") {
            isResetConfirmationPresented = true
        }
        .alert("Reset Settings?", isPresented: $isResetConfirmationPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                // perform reset
            }
        } message: {
            Text("This cannot be undone.")
        }
    }
}
```

Name boolean state properties `is<Context>Presented` to follow SwiftUI's `isPresented` convention.

## Optional Data Driving an Alert

When an optional value should trigger the alert and be available inside the alert closures, use the `presenting:` parameter. This avoids force-unwrapping or `if let` inside the alert builder.

The `presenting:` overload requires `isPresented: Binding<Bool>`, so create a computed binding that derives its value from the optional:

```swift
struct SettingsView: View {
    @Environment(SettingsModel.self) private var model
    @State private var currentError: Error?

    private var isErrorPresented: Binding<Bool> {
        Binding(
            get: { currentError != nil },
            set: { if !$0 { currentError = nil } }
        )
    }

    var body: some View {
        content
            .alert("Settings Error", isPresented: isErrorPresented, presenting: currentError) { _ in
                Button("OK") { currentError = nil }
            } message: { error in
                Text(error.localizedDescription)
            }
    }
}
```

The setter clears the optional when SwiftUI dismisses the alert (`$0` is `false`), which keeps the state and presentation in sync.

### Triggering the Alert

Set the optional to a non-nil value at the call site:

```swift
Button("Save") {
    do {
        try model.save(config)
    } catch {
        currentError = error
    }
}
```

### Multiple Optional Sources

When a view has several operations that each produce different optional data for alerts, use separate `@State` properties with distinct binding names:

```swift
@State private var saveError: Error?
@State private var deleteError: Error?

private var isSaveErrorPresented: Binding<Bool> {
    Binding(
        get: { saveError != nil },
        set: { if !$0 { saveError = nil } }
    )
}

private var isDeleteErrorPresented: Binding<Bool> {
    Binding(
        get: { deleteError != nil },
        set: { if !$0 { deleteError = nil } }
    )
}
```

This allows each alert to have its own title and message while sharing the same binding pattern.

### Naming Convention

| Good | Avoid |
|------|-------|
| `isErrorPresented` | `showError` |
| `isDeleteErrorPresented` | `errorShowing` |
| `isItemToDeletePresented` | `showDeleteItem` |

Follow SwiftUI's `is___Presented` pattern for all computed bindings.

## Alert State is View State

Alert-driving properties — whether `Bool` or optional — belong in `@State`, not in `@Observable` models. Alert visibility is presentation concern, the same category as selection or sheet visibility.
