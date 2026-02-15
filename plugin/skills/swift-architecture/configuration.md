# Configuration & Data Path Setup

Configuration services live in the **Services layer** and are initialized at the **Apps layer**. They provide centralized credential management and type-safe file path resolution.

## Two Services

| Service | Purpose | Location |
|---------|---------|----------|
| `ConfigurationService` | Credentials & settings via JSON files | `~/.myapp/*.json` |
| `DataPathsService` | Type-safe file system paths for data storage | `~/.myapp/data/` |

## ConfigurationService

Loads typed configuration from JSON files in the app's config directory.

```swift
let configService = try ConfigurationService()
let config = try configService.get(APIConfiguration.self, from: "api-service")
```

### Configuration File Reference

| File | Fields | Required |
|------|--------|----------|
| `api-service.json` | `token` | Yes |
| `build-server.json` | `userName`, `password`, `baseURL` | Yes |
| `issue-tracker.json` | `baseURL`, `username`, `apiToken` | Yes |
| `analytics.json` | `username`, `password`, `baseURL` | Yes |
| `ai-service.json` | `apiKey` | No (optional) |

**Example** — `api-service.json`:
```json
{
  "token": "your-api-token"
}
```

**Example** — `build-server.json`:
```json
{
  "userName": "your-username",
  "password": "your-password",
  "baseURL": "https://build.your-company.com"
}
```

**Example** — `issue-tracker.json`:
```json
{
  "baseURL": "https://your-company.atlassian.net",
  "username": "your-email@company.com",
  "apiToken": "your-api-token"
}
```

**Example** — `analytics.json`:
```json
{
  "username": "analytics-user",
  "password": "analytics-password",
  "baseURL": "http://analytics.your-company.com/api/"
}
```

**Example** — `ai-service.json` (optional):
```json
{
  "apiKey": "your-ai-service-api-key"
}
```

**Note**: All fields including `baseURL` are required for services that declare it. Configuration directory is typically `~/.myapp/` or `~/Library/Application Support/MyApp/`.

## DataPathsService

Provides type-safe enum-based paths for data storage directories.

```swift
let dataPathsService = try DataPathsService()
let path = try dataPathsService.path(for: .builds)
```

### ServicePath Enum

```swift
public enum ServicePath {
    case builds             // ~/.myapp/data/api-service/builds/
    case apiArtifacts       // ~/.myapp/data/api-service/artifacts/
    case buildArtifacts     // ~/.myapp/data/build-server/artifacts/
    case analyticsReports   // ~/.myapp/data/analytics/reports/
    case analyticsProcessed // ~/.myapp/data/analytics/processed/
    case taskJobs           // ~/.myapp/data/tasks/jobs/
    case appDatabase        // ~/.myapp/data/app/database/
}
```

### Directory Structure

```
~/.myapp/data/
├── api-service/
│   ├── builds/
│   └── artifacts/
├── build-server/
│   └── artifacts/
├── analytics/
│   ├── reports/
│   └── processed/
├── tasks/
│   └── jobs/
└── app/
    └── database/          (SwiftData store)
```

## Integration Patterns

### Loading at the Apps Layer

Configuration services are created at the Apps layer and injected into models and use cases:

```swift
@main
struct MyApp: App {
    @State private var appModel: AppModel

    init() {
        let configService = try ConfigurationService()
        let dataPathsService = try DataPathsService()
        _appModel = State(initialValue: AppModel(
            configService: configService,
            dataPathsService: dataPathsService
        ))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
    }
}
```

### Passing to Use Cases

Use cases receive configuration through their initializer — they never load configuration themselves:

```swift
public struct ImportUseCase: StreamingUseCase {
    private let apiClient: APIClient
    private let storagePath: URL

    public init(apiClient: APIClient, storagePath: URL) {
        self.apiClient = apiClient
        self.storagePath = storagePath
    }
}
```

### Optional Child Models for Feature-Specific Config

For features that require credentials, use optional child models. The model is `nil` when config is missing:

```swift
@MainActor @Observable
class AppModel {
    var integrationModel: IntegrationModel?

    init(configService: ConfigurationService) {
        if let config = try? configService.get(IntegrationConfig.self, from: "integration") {
            self.integrationModel = IntegrationModel(config: config)
        }
    }
}
```

### CLI Initialization

CLI commands follow the same pattern — create configuration at the entry point and pass it down:

```swift
struct ImportCommand: AsyncParsableCommand {
    func run() async throws {
        let configService = try ConfigurationService()
        let dataPathsService = try DataPathsService()
        let config = try configService.get(APIConfiguration.self, from: "api-service")
        let apiClient = APIClient(token: config.token)
        let useCase = ImportUseCase(
            apiClient: apiClient,
            storagePath: try dataPathsService.path(for: .builds)
        )

        for try await state in useCase.stream(options: .init(source: source)) {
            print(state)
        }
    }
}
```

## Design Principles

1. **Single Source of Truth** — One service per concern (config vs data paths)
2. **Fail Fast** — Missing configuration crashes at startup with clear errors
3. **Type-Safe** — Strongly-typed configuration models and enum-based paths
4. **No Arguments** — Both services use hardcoded root paths (no path injection)
5. **Auto-Creation** — DataPathsService creates directories automatically
6. **Apps Layer Owns Initialization** — Configuration services are created at the app layer and injected downward

## Checklist

When adding configuration to a feature:

- [ ] Configuration model is a `Codable` struct matching the JSON file
- [ ] JSON file is documented with all required fields
- [ ] ConfigurationService loads the config at the Apps layer (not in the feature)
- [ ] Use case receives resolved values (API client, paths), not the config service itself
- [ ] Optional features use optional child models when config may be absent
- [ ] Missing required config fails fast at startup

