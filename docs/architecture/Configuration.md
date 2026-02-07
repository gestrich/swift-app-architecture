# Configuration Architecture

Applications benefit from centralized configuration and data path management. Configuration services live in the **Services layer** as shared utilities, and are initialized at the **Apps layer** and passed into models and use cases.

## ConfigurationService

**Purpose**: Manages credentials and settings via JSON files

**Location**: `~/.myapp/*.json` (or `~/Library/Application Support/MyApp/`)

**Layer**: Services — shared configuration utility used across features

**Usage**:
```swift
let configService = try ConfigurationService()
let config = try configService.get(APIConfiguration.self, from: "api-service")
```

**Configuration Files**:
- `api-service.json` - API service credentials
- `build-server.json` - Build server credentials
- `ai-service.json` - AI provider API key (optional)
- `issue-tracker.json` - Issue tracker credentials (optional)
- `analytics.json` - Analytics service credentials (optional)

### Configuration File Reference

All configuration files should be placed in the app's config directory and use JSON format.

#### api-service.json
```json
{
  "token": "your-api-token"
}
```

#### build-server.json
```json
{
  "userName": "your-username",
  "password": "your-password",
  "baseURL": "https://build.your-company.com"
}
```

**Note**: All fields including `baseURL` are required.

#### issue-tracker.json
```json
{
  "baseURL": "https://your-company.atlassian.net",
  "username": "your-email@company.com",
  "apiToken": "your-api-token"
}
```

#### analytics.json
```json
{
  "username": "analytics-user",
  "password": "analytics-password",
  "baseURL": "http://analytics.your-company.com/api/"
}
```

#### ai-service.json (optional)
```json
{
  "apiKey": "your-ai-service-api-key"
}
```

---

## DataPathsService

**Purpose**: Manages file system paths where features and services store data

**Location**: `~/.myapp/data/`

**Layer**: Services — shared data path utility

**Usage**:
```swift
let dataPathsService = try DataPathsService()
let path = try dataPathsService.path(for: .builds)  // Type-safe enum
```

**Directory Structure**:
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

**ServicePath Enum** (Type-safe paths):
```swift
public enum ServicePath {
    case builds             // ~/.myapp/data/api-service/builds/
    case apiArtifacts       // ~/.myapp/data/api-service/artifacts/
    case buildArtifacts     // ~/.myapp/data/build-server/artifacts/
    case analyticsReports   // ~/.myapp/data/analytics/reports/
    case analyticsProcessed
    case taskJobs           // ~/.myapp/data/tasks/jobs/
    case appDatabase        // ~/.myapp/data/app/database/
}
```

---

## Integration with the Architecture

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

Use cases receive configuration through their initializer — they don't load configuration themselves:

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

### Optional Child Models for Configuration

For features that require credentials, use optional child models (see [swift-ui.md](swift-ui.md)):

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

---

## Design Principles

1. **Single Source of Truth**: One service per concern (config vs data paths)
2. **Fail Fast**: Missing configuration crashes at startup with clear errors
3. **Type-Safe**: Strongly-typed configuration and enum-based paths
4. **No Arguments**: Both services use hardcoded root paths
5. **Auto-Creation**: DataPathsService creates directories automatically
6. **Apps Layer Owns Initialization**: Configuration services are created at the app layer and injected downward
