# Data Models & Prerequisite Data

Domain structs that drive views and how to handle missing data.

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

**Benefits:**
- Views are simpler and focused on their primary purpose
- Data requirements are explicit in the API (non-optional parameters)
- Impossible states are not representable
- Parent views control when child views appear
