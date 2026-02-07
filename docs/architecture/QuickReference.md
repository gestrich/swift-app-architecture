# Quick Reference Guide

Quick decision guides for common architectural questions.

## Where to Put Things

| What you're adding | Where it goes |
|-------------------|---------------|
| SwiftUI views | `apps/MyMacApp/Views/` |
| `@Observable` models | `apps/MyMacApp/Models/` |
| CLI commands | `apps/MyCLIApp/` |
| Server handlers | `apps/MyServerApp/` |
| Multi-step orchestration | `features/MyFeature/usecases/` |
| Feature-specific types | `features/MyFeature/services/` |
| Shared data models | `services/CoreService/Models/` |
| Configuration / settings | `services/AuthService/`, `services/StorageService/` |
| Stateful shared utility | `services/MyService/` |
| Single API call wrapper | `sdks/APIClientSDK/` |
| Single CLI command wrapper | `sdks/CLISDK/`, `sdks/GitSDK/` |
| Use case protocol definitions | `sdks/Uniflow/` |

## Decision Flowcharts

### Where Does This Code Belong?

```
Start: I need to add new code
    ↓
Is it UI, @Observable, or platform-specific I/O?
    ├─ Yes → Apps Layer
    │         (models, views, CLI commands, server handlers)
    │
    └─ No → Does it orchestrate multiple steps into a workflow?
              ├─ Yes → Features Layer
              │         (UseCase / StreamingUseCase)
              │
              └─ No → Is it a shared model, config, or stateful utility?
                        ├─ Yes → Services Layer
                        │
                        └─ No → Is it a single operation (one API call, one command)?
                                  ├─ Yes → SDKs Layer
                                  │         (stateless Sendable struct)
                                  └─ No → Services Layer (shared utility)
```

### Should This Be a Feature or Service?

```
I'm adding new business logic
    ↓
Does it orchestrate multiple steps into a workflow?
    ├─ Yes → Feature Layer (use case)
    │         (e.g., ImportUseCase, SyncUseCase)
    │
    └─ No → Is it a shared model, config, or utility?
              ├─ Yes → Services Layer
              │         (e.g., CoreService, AuthService)
              │
              └─ Not sure → Does it coordinate SDK calls?
                            ├─ Yes → Feature Layer (use case)
                            └─ No → Services Layer
```

### Should This Be a Service or SDK?

```
I'm adding functionality
    ↓
Is this ONE command or API call?
    ├─ Yes → SDK Layer
    │         (e.g., GitClient, APIClient)
    │
    └─ No → Is it a shared model or config used by multiple features?
              ├─ Yes → Services Layer
              │         (e.g., CoreService models, AuthService)
              │
              └─ Not sure → Could any project reuse this as-is?
                            ├─ Yes → SDK Layer
                            └─ No → Services Layer
```

## Common Questions

### Q: I'm adding a new feature to the app. Where does it go?

**A:** Create three things:
1. **Feature module** in `features/MyFeature/` — use cases that orchestrate the logic
2. **Mac app model** in `apps/MyMacApp/Models/` — `@Observable` model consuming use case streams
3. **CLI command** in `apps/MyCLIApp/` — command consuming use cases directly (if CLI access needed)

### Q: I need to add a git operation. SDK or Feature?

**A:** Ask yourself:
- **ONE git command?** → GitSDK (SDK)
- **Multiple git commands in sequence?** → Feature use case
- **Shared git config or models?** → Service

### Q: Where do `@Observable` models go?

**A:** Always in the **Apps layer** (`apps/MyMacApp/Models/`):
- ✅ `apps/MyMacApp/Models/ImportModel.swift`
- ❌ `features/ImportFeature/ImportModel.swift`
- ❌ `services/CoreService/ImportModel.swift`

### Q: Where do I put data models?

**A:** Depends on scope:
- **Used by multiple features?** → `services/CoreService/Models/`
- **Only used by one feature?** → `features/MyFeature/services/`
- **Only used by the UI?** → `apps/MyMacApp/` (app layer)

### Q: Can a feature depend on another feature?

**A:** No — features depend on Services and SDKs only, not other features. If two features need shared logic:
- Extract shared types to a **Service**
- Extract shared operations to an **SDK**
- If composition is needed, do it at the **App layer** (model composition or composite CLI commands)

### Q: Can I call an SDK directly from an app?

**A:** For simple cases, yes:
- ✅ Better: App → Feature (use case) → SDK
- ⚠️ Acceptable: App → SDK (for trivial single-call operations)
- ❌ Avoid: Complex SDK orchestration in apps (use a Feature instead)

### Q: How do I share code between CLI and Mac app?

**A:** Put all shared logic in **Features** (use cases):
- Both CLI commands and Mac models consume the same use cases
- CLI calls `useCase.stream()` or `useCase.run()` directly
- Mac models call use cases and update `@Observable` state

### Q: Where does configuration go?

**A:** In the **Services layer**:
- Auth tokens and credentials → `services/AuthService/`
- File paths and storage → `services/StorageService/`
- App-wide settings → `services/CoreService/`
- See [Configuration.md](Configuration.md) for detailed patterns

## Common Patterns

### Pattern: New Feature

```
1. Create use case module:
   features/MyFeature/
       ├── usecases/         UseCase / StreamingUseCase conformers
       └── services/         Feature-specific types

2. Add Mac app model:
   apps/MyMacApp/Models/MyModel.swift     @Observable, consumes use case stream

3. Add CLI command (optional):
   apps/MyCLIApp/MyCommand.swift          Consumes use case directly

4. Both app entry points depend on MyFeature
5. Both consume the same use cases
```

### Pattern: Multi-Step Workflow

```
1. Create StreamingUseCase in feature:
   features/MyFeature/usecases/MyUseCase.swift
   └── stream(options:) → AsyncThrowingStream<State, Error>

2. Use case orchestrates SDKs and services:
   apiClient.fetchData()      → SDK call
   gitClient.commit()         → SDK call
   coreService.saveConfig()   → Service call

3. Mac app model consumes stream:
   for try await state in useCase.stream(options: opts) {
       self.state = ModelState(from: state)
   }

4. CLI command consumes stream:
   for try await state in useCase.stream(options: opts) {
       print(state)
   }
```

### Pattern: Shared Types Across Features

```
1. Define types in a service:
   services/CoreService/Models/SharedModel.swift

2. Features import the service:
   features/ImportFeature/ → depends on CoreService
   features/ExportFeature/ → depends on CoreService

3. Both features use SharedModel
```

## Quick Checks

### Before Creating a New Module

- [ ] Is this really needed or can I extend an existing module?
- [ ] What layer does this belong to? (App / Feature / Service / SDK)
- [ ] What will depend on this?
- [ ] Does it follow the `<Name><Layer>` naming convention?
- [ ] Am I using the same implementation strategy (packages, targets, or folders) as the rest of the project?

### Before Adding Code

- [ ] Am I putting this in the right layer?
- [ ] Does this violate any dependency rules?
- [ ] Is there duplication I can eliminate?
- [ ] Am I following the "depth over width" principle?
- [ ] Is `@Observable` only in the Apps layer?

### Before Committing

- [ ] Can the module build independently? (when using targets or packages)
- [ ] Are all dependencies flowing downward?
- [ ] Is orchestration logic in Features (use cases), not in Apps or Services?
- [ ] Are SDKs stateless `Sendable` structs?

## Getting Help

See the detailed guides:
- **[Layers.md](Layers.md)** — Layer descriptions and rules
- **[Dependencies.md](Dependencies.md)** — Dependency rules and boundaries
- **[FeatureStructure.md](FeatureStructure.md)** — How to structure features
- **[Examples.md](Examples.md)** — Reference implementation
- **[Principles.md](Principles.md)** — Core architectural principles
- **[Configuration.md](Configuration.md)** — Configuration and data path management
- **[swift-ui.md](swift-ui.md)** — SwiftUI and model architecture guidelines
