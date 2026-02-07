# Code Style Conventions

Code style rules for consistent Swift code across the project. These apply to all layers (Apps, Features, Services, SDKs).

## Import Ordering

Order imports **alphabetically**:

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
    // 1. Stored properties
    private let client: APIClient
    private let cache: Cache

    // 2. Initializer
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

**Why this order**: Readers scanning a file want to quickly understand what a type holds and how to create it. Nested type definitions are implementation details that live at the bottom.

## Avoid Type Aliases and Re-exports

Type aliases and re-exports obscure actual types and create indirection.

```swift
// Avoid
public typealias ClientResult = Result<Data, ClientError>
@_exported import APIClientSDK

// Prefer — use the actual types directly
func fetch() -> Result<Data, ClientError>
```

If you find yourself wanting a type alias, consider whether the underlying type should be renamed or if a new type is warranted.

## Avoid Default and Fallback Values

Prefer requiring data explicitly. Missing values often represent errors that should surface immediately rather than being silently masked.

```swift
// Avoid — masks missing data
func configure(timeout: Int = 30, retries: Int = 3) { ... }
let name = user.displayName ?? "Unknown"

// Prefer — require what you need
func configure(timeout: Int, retries: Int) { ... }
let name = user.displayName  // Let caller handle nil appropriately
```

**When fallbacks are appropriate**: Only use optionals with fallbacks when the value genuinely may be absent and that absence is *expected behavior*, not an error condition. Examples: user preferences that haven't been set yet, optional UI customizations.

**Why**: Default values hide configuration decisions and make debugging harder. When something breaks, you want to know immediately that required data was missing, not discover later that a silent fallback caused unexpected behavior.

## Quick Reference

| Rule | Do | Don't |
|------|-----|-------|
| Imports | Alphabetical order | Random or grouped |
| File structure | Properties → init → computed → methods → nested types | Mixed ordering |
| Type aliases | Use actual types directly | `typealias` or `@_exported import` |
| Parameters | Require values explicitly | Default parameter values |
| Missing data | Surface errors immediately | `?? "fallback"` silent defaults |

## Checklist

When writing or reviewing code:

- [ ] Imports are alphabetically ordered
- [ ] File follows the property → init → computed → method → nested type order
- [ ] No type aliases or re-exports
- [ ] No unnecessary default parameter values
- [ ] No silent fallbacks masking missing data
- [ ] Optional fallbacks are only for genuinely optional, non-error cases

## Source Documentation

- **[code-style.md](../../../docs/architecture/code-style.md)** — Full code style reference
