# Architecture Reference Examples

Complete implementation examples showing code across all four layers using a generic **Import** feature as the reference walkthrough. The directory structure below uses the "targets in a single package" strategy — see [Layers.md — Implementation Strategies](../../../docs/architecture/Layers.md#implementation-strategies) for alternatives.

## Directory Structure

```
sdks/APIClientSDK/
└── APIClient.swift                # Stateless Sendable struct

services/CoreService/
├── Models/
│   ├── ImportConfig.swift
│   ├── ImportResult.swift
│   └── DataSource.swift
└── Configuration/
    └── AppConfiguration.swift

features/ImportFeature/
├── usecases/
│   ├── ImportUseCase.swift         # StreamingUseCase conformer
│   └── ValidateUseCase.swift       # UseCase conformer
└── services/
    └── ImportMapper.swift          # Feature-specific helpers

apps/MyMacApp/
├── Models/
│   └── ImportModel.swift           # @Observable model
└── Views/
    └── ImportView.swift            # SwiftUI view

apps/MyCLIApp/
└── ImportCommand.swift             # CLI command
```

## Data Flow

```
User clicks "Import" in Mac app
    ↓
ImportModel.startImport()
    ↓
ImportUseCase.stream(options:)          ← StreamingUseCase
    ↓
APIClient.fetchData() → APIClientSDK        ← SDK (stateless)
APIClient.submitImport() → APIClientSDK     ← SDK (stateless)
    ↓
AsyncThrowingStream yields progress
    ↓
ImportModel.state updated per yield     ← @Observable model
    ↓
ImportView re-renders automatically     ← SwiftUI
```

## SDK Layer — Stateless Client

`sdks/APIClientSDK/APIClient.swift`

```swift
import Foundation

public struct APIClient: Sendable {
    public init() {}

    public func fetchData(source: String) async throws -> Data {
        // Single API call — no business logic
    }

    public func submitImport(payload: Data) -> AsyncThrowingStream<ImportProgress, Error> {
        AsyncThrowingStream { continuation in
            Task {
                // ... yield progress, then finish
            }
        }
    }

    public func fetchStatus(id: String) async throws -> StatusResponse {
        // Single API call
    }
}
```

Key traits:
- `Sendable` struct, not a class or actor
- Each method wraps a single operation
- No business logic or app-specific concepts
- Reusable across projects

## Service Layer — Shared Models

`services/CoreService/Models/ImportConfig.swift`

```swift
public struct ImportConfig: Sendable {
    public let source: DataSource
    public let validateFirst: Bool
    public let batchSize: Int

    public init(source: DataSource, validateFirst: Bool, batchSize: Int) {
        self.source = source
        self.validateFirst = validateFirst
        self.batchSize = batchSize
    }
}

public enum DataSource: Sendable {
    case local(path: String)
    case remote(url: URL)
}
```

Key traits:
- Models shared across features
- No orchestration logic
- `Sendable` for safe concurrency

## Feature Layer — Use Case

`features/ImportFeature/usecases/ImportUseCase.swift`

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
                    let data = try await apiClient.fetchData(
                        source: options.config.source.identifier
                    )

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

public struct ImportSnapshot: Sendable {
    public let status: StatusResponse
    public let itemCount: Int
}
```

Key traits:
- `StreamingUseCase` conformer orchestrating multiple steps
- Yields progress via `AsyncThrowingStream`
- Coordinates multiple SDK calls into a workflow
- Not `@Observable` — that belongs in Apps

## App Layer — Mac App (@Observable Model)

`apps/MyMacApp/Models/ImportModel.swift`

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

`apps/MyMacApp/Views/ImportView.swift`

```swift
import SwiftUI
import CoreService

struct ImportView: View {
    @State private var model: ImportModel

    init(model: ImportModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        VStack {
            switch model.state {
            case .loading:
                ProgressView("Loading...")
            case .ready(let snapshot):
                Text("Ready — \(snapshot.itemCount) items")
                Button("Import") {
                    model.startImport(config: ImportConfig(
                        source: .remote(url: sourceURL),
                        validateFirst: true,
                        batchSize: 100
                    ))
                }
            case .operating(let state, _):
                ProgressView("Importing...")
                Text(state.description)
            case .error(let error, _):
                Text("Error: \(error.localizedDescription)")
            }
        }
    }
}
```

Key traits:
- `@Observable` model bridges use case stream to SwiftUI
- Enum-based `ModelState` with `prior` for retaining last-known data
- View switches on model state — no separate loading/error properties

## App Layer — CLI (Direct Use Case Consumption)

`apps/MyCLIApp/ImportCommand.swift`

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

    @Flag(help: "Skip validation")
    var skipValidation: Bool = false

    func run() async throws {
        let config = ImportConfig(
            source: .local(path: source),
            validateFirst: !skipValidation,
            batchSize: 100
        )
        let useCase = ImportUseCase()

        for try await state in useCase.stream(options: .init(config: config)) {
            switch state {
            case .validating:
                print("Validating...")
            case .importing(let progress):
                print("Importing: \(progress)")
            case .verifying:
                print("Verifying...")
            case .completed(let snapshot):
                print("Done — \(snapshot.itemCount) items imported")
            }
        }
    }
}
```

Key traits:
- Consumes the **same use case** as the Mac app — zero duplication
- No `@Observable` needed — prints progress directly
- Both apps share identical business logic

## Key Takeaways

| Principle | How It Shows in This Example |
|-----------|------------------------------|
| Apps layer is platform-specific | Mac uses `@Observable` model; CLI uses `print` — both call same use case |
| Features layer orchestrates | `StreamingUseCase` coordinates validate → import → verify steps |
| Services layer shares | `ImportConfig` and `DataSource` used by both feature and apps |
| SDKs layer is stateless | `APIClient` is a `Sendable` struct with single operations |
| Zero duplication | Fix bugs once, add features once — only app-layer consumption differs |

## Source Documentation

- **[Examples.md](../../../docs/architecture/Examples.md)** — Full reference implementation walkthrough
