# Code Style

Guidelines for consistent code organization across the project.

## Imports

Order imports alphabetically:

```swift
import APIClientSDK
import CoreService
import Foundation
import ImportFeature
```

## File Organization

Structure files to show the most important elements first:

```swift
struct MyService {
    // 1. Stored properties (most important - what the type holds)
    private let client: APIClient
    private let cache: Cache

    // 2. Initializer (how to create it)
    init(client: APIClient, cache: Cache) {
        self.client = client
        self.cache = cache
    }

    // 3. Computed properties
    var isReady: Bool { client.isConnected }

    // 4. Methods
    func fetch() async throws -> Data { ... }

    // 5. Nested types (enums, structs) at the bottom
    enum State {
        case idle
        case loading
        case loaded(Data)
    }
}
```

**Rationale**: Readers scanning a file want to quickly understand what a type holds and how to create it. Nested type definitions are implementation details that can live at the bottom.

## Avoid Type Aliases and Re-exports

Type aliases and re-exports are a code smell. They obscure the actual types being used and create indirection that makes code harder to follow.

```swift
// Avoid
public typealias ClientResult = Result<Data, ClientError>
@_exported import APIClientSDK

// Prefer
// Use the actual types directly
func fetch() -> Result<Data, ClientError>
```

If you find yourself wanting a type alias, consider whether the underlying type should be renamed or if a new type is warranted.

## Avoid Default and Fallback Values

Prefer requiring data explicitly rather than providing defaults or fallbacks. Missing values often represent errors that should surface immediately rather than being silently masked.

```swift
// Avoid - masks missing data
func configure(timeout: Int = 30, retries: Int = 3) { ... }
let name = user.displayName ?? "Unknown"

// Prefer - require what you need
func configure(timeout: Int, retries: Int) { ... }
let name = user.displayName  // Let caller handle nil appropriately
```

**When fallbacks are appropriate**: Only use optionals with fallbacks when the value genuinely may be absent and that absence is expected behavior, not an error condition. Examples include user preferences that haven't been set yet or optional UI customizations.

**Rationale**: Default values hide configuration decisions and make debugging harder. When something breaks, you want to know immediately that required data was missing, not discover later that a silent fallback caused unexpected behavior. APIs should require the data they need from the client.

## Propagate Errors — Don't Swallow Them

Always propagate errors to callers rather than catching and ignoring them. SDKs and use cases should mark methods `throws` and let errors bubble up. The only place errors should be caught is at the app layer (models and CLI commands), where they can be presented to the user.

```swift
// Avoid — silently swallows the error
func save(data: Data) {
    do {
        try storage.write(data)
    } catch {
        print("save failed")
    }
}

// Prefer — let it propagate
func save(data: Data) throws {
    try storage.write(data)
}
```

**At the app layer**, catch errors to set state the UI can display:

```swift
// Model catches at the boundary to show the user
func save() {
    Task {
        do {
            try await useCase.run(options: opts)
            state = .ready(snapshot)
        } catch {
            state = .error(error, prior: state.snapshot)
        }
    }
}
```

**Rationale**: Swallowed errors hide failures and make debugging nearly impossible. When an operation fails, the caller needs to know so they can respond — in most cases that means showing the user an error message. If a lower layer catches and discards an error, the UI has no way to communicate the failure.
