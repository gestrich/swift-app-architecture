# Creating a Feature

Guide for creating new feature modules in the 4-layer Swift architecture. Features are **use case modules** — they contain `UseCase` / `StreamingUseCase` conformers that orchestrate multi-step operations. Features do not contain UI or CLI code.

## Workflow Overview

1. Create the feature module in `features/`
2. Define use cases (`UseCase` or `StreamingUseCase`)
3. Add feature-specific types in `services/` subdirectory if needed
4. Add shared types to Services layer if needed
5. Connect at the app layer (Mac model and/or CLI command)

> **Important:** Match the implementation strategy already used in the project (separate packages, targets in one package, or folders). If unsure, ask. See [Layers.md — Implementation Strategies](../../../docs/architecture/Layers.md#implementation-strategies).

## Step 1: Create the Feature Module

Create a directory in `features/` following this structure:

```
features/MyFeature/
├── usecases/
│   ├── MyUseCase.swift              # StreamingUseCase or UseCase conformer
│   └── ValidateUseCase.swift         # Additional use cases
└── services/
    ├── MyMapper.swift               # Feature-specific helpers
    └── MyTypes.swift                # Feature-specific models
```

### Declaring Dependencies

How you declare dependencies depends on the project's implementation strategy:

**Target in a single package** — add a target in the root `Package.swift`:
```swift
.target(
    name: "MyFeature",
    dependencies: ["Uniflow", "APIClientSDK", "CoreService"],
    path: "Sources/features/MyFeature"
),
```

**Separate Swift package** — create a `Package.swift` in the feature directory:
```swift
let package = Package(
    name: "MyFeature",
    products: [
        .library(name: "MyFeature", targets: ["MyFeature"])
    ],
    dependencies: [
        .package(path: "../sdks/Uniflow"),
        .package(path: "../sdks/APIClientSDK"),
        .package(path: "../services/CoreService"),
    ],
    targets: [
        .target(
            name: "MyFeature",
            dependencies: ["Uniflow", "APIClientSDK", "CoreService"]
        ),
        .testTarget(
            name: "MyFeatureTests",
            dependencies: ["MyFeature"]
        ),
    ]
)
```

**Folders only** — no dependency declaration needed; just create the folder.

### Naming Convention

Modules use PascalCase with `<Name>Feature` suffix: `ImportFeature`, `ExportFeature`, `SyncFeature`.

## Step 2: Define Use Cases

### Choosing UseCase vs StreamingUseCase

| Protocol | Use When | Example |
|----------|----------|---------|
| `UseCase` | Single result, no intermediate progress | Status checks, validation, configuration loading |
| `StreamingUseCase` | Multi-step with progress updates | Imports, builds, deployments, syncs |

### UseCase Protocol (from Uniflow)

```swift
public protocol UseCase: Sendable {
    associatedtype Options: Sendable = Void
    associatedtype Result: Sendable

    func run(options: Options) async throws -> Result
}
```

### StreamingUseCase Protocol (from Uniflow)

```swift
public protocol StreamingUseCase: UseCase {
    associatedtype State: Sendable

    func stream(options: Options) -> AsyncThrowingStream<State, Error>
}
```

When `Result == State`, a default `run()` implementation consumes the stream and returns the last state.

### StreamingUseCase Example

```swift
import Uniflow
import CoreService
import APIClientSDK

public struct ImportUseCase: StreamingUseCase {
    public typealias State = ImportState
    public typealias Result = State

    public struct Options: Sendable {
        public let config: ImportConfig
    }

    private let apiClient: APIClient

    public init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    public func stream(options: Options) -> AsyncThrowingStream<State, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    continuation.yield(.validating)
                    let data = try await apiClient.fetchData(source: options.config.source.identifier)

                    continuation.yield(.importing(.starting))
                    for try await progress in apiClient.submitImport(payload: data) {
                        continuation.yield(.importing(.progress(progress)))
                    }

                    continuation.yield(.verifying)
                    let status = try await apiClient.fetchStatus(id: "latest")

                    let snapshot = ImportSnapshot(status: status, itemCount: data.count)
                    continuation.yield(.completed(snapshot))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

public enum ImportState: Sendable {
    case validating
    case importing(ImportProgress)
    case verifying
    case completed(ImportSnapshot)

    public var completedSnapshot: ImportSnapshot? {
        if case .completed(let snapshot) = self { return snapshot }
        return nil
    }
}
```

### UseCase Example

```swift
import Uniflow
import CoreService

public struct ValidateUseCase: UseCase {
    public typealias Options = ValidateOptions
    public typealias Result = ValidationResult

    public struct ValidateOptions: Sendable {
        public let source: DataSource
    }

    public func run(options: ValidateOptions) async throws -> ValidationResult {
        // Single-step validation, no progress needed
    }
}
```

### Use Case Rules

- Use cases are **structs**, not classes
- Accept dependencies via `init` with defaults: `init(apiClient: APIClient = APIClient())`
- Options are `Sendable` structs
- State enums are `Sendable`
- No `@Observable` — that belongs in the Apps layer

## Step 3: Add Shared Types to Services (If Needed)

If the feature introduces types that **other features will also use**, put them in a service:

- `services/CoreService/` for core models
- `services/AuthService/` for auth-related types
- Create a new service only if the types don't fit an existing one

Types used **only by this feature** stay in `features/MyFeature/services/`.

## Step 4: Connect at the App Layer

### Mac App — @Observable Model

Create an `@Observable` model in `apps/MyMacApp/Models/` that consumes the use case stream:

```swift
import ImportFeature
import CoreService

@MainActor @Observable
class ImportModel {
    var state: ModelState = .loading(prior: nil)
    private let useCase: ImportUseCase

    init(useCase: ImportUseCase = ImportUseCase()) {
        self.useCase = useCase
    }

    func startImport(config: ImportConfig) {
        let prior = state.snapshot
        Task {
            do {
                for try await useCaseState in useCase.stream(options: .init(config: config)) {
                    state = ModelState(from: useCaseState, prior: prior)
                }
            } catch {
                state = .error(error, prior: prior)
            }
        }
    }

    enum ModelState {
        case loading(prior: ImportSnapshot?)
        case ready(ImportSnapshot)
        case operating(ImportState, prior: ImportSnapshot?)
        case error(Error, prior: ImportSnapshot?)

        var snapshot: ImportSnapshot? {
            switch self {
            case .ready(let s): return s
            case .operating(_, let prior): return prior
            case .loading(let prior): return prior
            case .error(_, let prior): return prior
            }
        }

        init(from useCaseState: ImportState, prior: ImportSnapshot?) {
            if let snapshot = useCaseState.completedSnapshot {
                self = .ready(snapshot)
            } else {
                self = .operating(useCaseState, prior: prior)
            }
        }
    }
}
```

Key patterns:
- **Enum-based state** — not multiple independent properties
- **State ownership** — use cases own state data, models own state transitions
- **Minimal mapping** — receive use case state and assign; complex mapping means the use case should return better-structured state

### CLI — Direct Use Case Consumption

Create a command in `apps/MyCLIApp/` that uses the use case directly:

```swift
import ArgumentParser
import ImportFeature
import CoreService

struct ImportCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "import",
        abstract: "Import data from a source"
    )

    @Option(help: "Data source path or URL")
    var source: String

    func run() async throws {
        let config = ImportConfig(source: .local(path: source), validateFirst: true, batchSize: 100)
        let useCase = ImportUseCase()

        for try await state in useCase.stream(options: .init(config: config)) {
            switch state {
            case .validating: print("Validating...")
            case .importing(let progress): print("Importing: \(progress)")
            case .verifying: print("Verifying...")
            case .completed(let snapshot): print("Done — \(snapshot.itemCount) items imported")
            }
        }
    }
}
```

Both the Mac model and CLI command consume the **same use case** — zero duplication of business logic.

### App Dependencies

Both app entry points depend on the same features — the declaration mechanism varies by implementation strategy.

## What a Feature Contains vs. Does Not Contain

**Contains:**
- Use cases (`UseCase` / `StreamingUseCase` conformers)
- Feature-specific types (models, mappers, helpers scoped to this feature)
- Feature-specific configuration

**Does NOT contain:**
- SwiftUI views or `@Observable` models (Apps layer)
- CLI commands or ArgumentParser structs (Apps layer)
- Shared models used across features (Services layer)

## Checklist

**Before creating the feature:**
- [ ] Is this really needed or can I extend an existing feature?
- [ ] Does it orchestrate multi-step operations? (If not, it may belong in Services)
- [ ] Does the name follow `<Name>Feature` convention?
- [ ] Am I using the same implementation strategy as the rest of the project?

**After creating the feature:**
- [ ] Module builds independently (when using targets or packages)
- [ ] All dependencies flow downward only
- [ ] Use cases conform to `UseCase` or `StreamingUseCase`
- [ ] No `@Observable` in the feature module
- [ ] Feature-only types are in `features/MyFeature/services/`, shared types in Services
- [ ] App-layer model and/or CLI command created to consume the use cases

## Source Documentation

- **[FeatureStructure.md](../../../docs/architecture/FeatureStructure.md)** — Feature module structure details
- **[Examples.md](../../../docs/architecture/Examples.md)** — Reference implementation walkthrough
- **[Layers.md](../../../docs/architecture/Layers.md)** — Detailed layer descriptions
