# Alerts

SwiftUI alert patterns and conventions.

## Basic Alert

Use a `Bool` binding to control visibility:

```swift
@State private var isResetConfirmationPresented = false

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
```

Name boolean state `is<Context>Presented` to follow SwiftUI's `isPresented` convention.

## Optional Data Driving an Alert

Use the `presenting:` parameter when an optional value should trigger the alert and be available inside its closures. Create a computed `Binding<Bool>` that derives from the optional:

```swift
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
```

The setter clears the optional when SwiftUI dismisses the alert, keeping state and presentation in sync.

### Multiple Optional Sources

Use separate `@State` properties with distinct binding names:

```swift
@State private var saveError: Error?
@State private var deleteError: Error?

private var isSaveErrorPresented: Binding<Bool> {
    Binding(
        get: { saveError != nil },
        set: { if !$0 { saveError = nil } }
    )
}
```

## Key Rules

- Alert-driving properties (`Bool` or optional) belong in `@State`, not in `@Observable` models
- Name computed bindings `is<Context>Presented`
- Use `presenting:` to pass optional data into alert closures instead of unwrapping

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

### Naming Convention

| Good | Avoid |
|------|-------|
| `isErrorPresented` | `showError` |
| `isDeleteErrorPresented` | `errorShowing` |
| `isItemToDeletePresented` | `showDeleteItem` |

Follow SwiftUI's `is___Presented` pattern for all computed bindings.
