# Reference Implementation: Example Feature Walkthrough

This document shows the ideal implementation of the layered architecture using a generic **Import** feature as the reference example. The directory structure below uses the "targets in a single package" strategy — see [Layers.md — Implementation Strategies](Layers.md#implementation-strategies) for alternatives.

## Directory Structure

### SDK Module (APIClientSDK)
```
sdks/APIClientSDK/
└── APIClient.swift              # Stateless Sendable struct
```

### Service Module (CoreService)
```
services/CoreService/
├── Models/
│   ├── ImportConfig.swift
│   ├── ImportResult.swift
│   └── DataSource.swift
└── Configuration/
    └── AppConfiguration.swift
```

### Feature Module (ImportFeature)
```
features/ImportFeature/
├── usecases/
│   ├── ImportUseCase.swift        # StreamingUseCase conformer
│   └── ValidateUseCase.swift      # UseCase conformer
└── services/
    └── ImportMapper.swift         # Feature-specific helpers
```

### App Modules (MyMacApp, MyCLIApp)
```
apps/MyMacApp/
├── Models/
│   └── ImportModel.swift          # @Observable model
└── Views/
    └── ImportView.swift           # SwiftUI view

apps/MyCLIApp/
└── ImportCommand.swift            # CLI command
```

## Data Flow Example

This shows the complete flow from user interaction to result:

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

## Code Examples

### SDK Layer

**Stateless client** — `sdks/APIClientSDK/APIClient.swift`
```swift
import Foundation

public struct APIClient: Sendable {
    public init() {}

    public func fetchData(source: String) async throws -> Data {
        // Single API call — no business logic
    }

    public func submitImport(payload: Data) -> AsyncThrowingStream<ImportProgress, Error> {
        // Single operation returning a stream
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

### Service Layer

**Shared models** — `services/CoreService/Models/ImportConfig.swift`
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

### Feature Layer (Use Case)

**StreamingUseCase** — `features/ImportFeature/usecases/ImportUseCase.swift`
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
                    // 1. Validate
                    continuation.yield(.validating)
                    let data = try await apiClient.fetchData(source: options.config.source.identifier)

                    // 2. Import with progress
                    continuation.yield(.importing(.starting))
                    for try await progress in apiClient.submitImport(payload: data) {
                        continuation.yield(.importing(.progress(progress)))
                    }

                    // 3. Verify
                    continuation.yield(.verifying)
                    let status = try await apiClient.fetchStatus(id: "latest")

                    // 4. Complete
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

### App Layer (Mac App — @Observable Model)

**Model** — `apps/MyMacApp/Models/ImportModel.swift`
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

**View** — `apps/MyMacApp/Views/ImportView.swift`
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

### App Layer (CLI — Direct Use Case Consumption)

**CLI command** — `apps/MyCLIApp/ImportCommand.swift`
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

Notice how **both the Mac app model and CLI command consume the exact same use case** — zero duplication of business logic.

## Key Takeaways

1. **Apps Layer is Platform-Specific**
   - Mac app uses `@Observable` models to bridge use case streams to SwiftUI
   - CLI consumes use case streams directly with `print` statements
   - Both call the same use cases

2. **Features Layer Orchestrates**
   - `StreamingUseCase` conformers coordinate multi-step operations
   - Yield progress via `AsyncThrowingStream`
   - No `@Observable` — that belongs in Apps

3. **Services Layer Shares**
   - Models and configuration used across features
   - No orchestration — that belongs in Features

4. **SDKs Layer is Stateless**
   - `Sendable` structs with single operations
   - No business logic or app-specific concepts
   - Reusable across features and projects

5. **Zero Duplication**
   - CLI and Mac app share identical use cases
   - Fix bugs once, add features once
   - Only the app-layer consumption differs

## Further Reading

- **[ARCHITECTURE.md](ARCHITECTURE.md)** — Architecture overview
- **[Layers.md](Layers.md)** — Detailed layer descriptions with examples
- **[FeatureStructure.md](FeatureStructure.md)** — How to structure feature modules
- **[swift-ui.md](swift-ui.md)** — SwiftUI and model architecture guidelines
