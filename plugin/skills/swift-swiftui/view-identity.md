# View Identity with `.id()`

How to use the `.id()` modifier to reset view state when dependencies change.

## When to Use `.id()`

Use `.id()` when state or identity falls outside normal data-driven view updates:

- `@State` initialized in `init()` with `State(initialValue:)` — only runs once per view identity
- `.task {}`, `.onAppear`, `.onDisappear` that need to re-run when dependencies change
- When you want to reset ALL internal view state (scroll position, focus, animations)

## How It Works

SwiftUI normally reuses view instances when the view hierarchy updates. When `.id()` receives a new value, SwiftUI destroys the old view instance completely and creates a fresh one. All `@State` variables reset to their initial values and all lifecycle hooks (`.task`, `.onAppear`) run again.

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
