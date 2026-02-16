# GoldenPath Repository Inventory

**Source:** https://github.com/gestrich/GoldenPath
**Cloned for review:** 2026-02-15

## Overview

GoldenPath is a **reference application** demonstrating best practices across the Apple ecosystem. It contains both runnable app targets and a `Principles/` directory with written guidelines. The codebase is early-stage — mostly scaffolding and placeholder models (`Foo`, `SubFoo`) — but the documentation is the real value.

## Repository Structure

```
GoldenPath/
├── GoldenPathiOS/          # iOS app target (minimal)
├── GoldenPathMac/          # macOS app target (minimal)
├── GoldenPathKit/           # Shared Swift package
│   ├── Sources/
│   │   ├── GoldenPathKit/       # Core library (stub)
│   │   └── GoldenPathKitUI/     # Shared UI
│   │       ├── Models/           # Foo model (placeholder)
│   │       ├── Navigation/       # NavigationContext pattern
│   │       └── Views/            # List/detail/sidebar views
│   └── Tests/
├── Principles/              # ★ Written guidelines (main value)
│   ├── Architecture/
│   │   └── MV-Architecture.md
│   ├── Documentation/
│   │   └── App-Documentation-Guidelines.md
│   ├── SwiftUI/
│   │   ├── SwiftUI-Style-Guide.md
│   │   ├── SwiftUI-Sheets.md
│   │   ├── SwiftUI-Forms.md
│   │   └── SwiftUI-Detail-Views.md
│   └── Swift-Style.md
├── CLAUDE.md                # AI context file
└── TODO.md                  # Navigation research links
```

## Content Inventory

### Principles (Documentation)

| File | Topic | Content Summary | Overlap with Existing Skills? |
|------|-------|----------------|-------------------------------|
| `MV-Architecture.md` | MV (Model-View) architecture | No ViewModel layer; `@Observable` models; domain services pattern; static predicates for `@Query`/`FetchDescriptor` reuse across UI and CLI | **High overlap** with `swift-swiftui` skill (observable models, enum state). Adds domain services pattern, predicate sharing, CLI reuse. |
| `SwiftUI-Style-Guide.md` | View composition | `@ViewBuilder` computed properties for breaking up views; sheet item API vs bool; macOS API differences | **Moderate overlap** with `swift-swiftui`. New: `@ViewBuilder` computed property convention, `.sheet(item:)` preference. |
| `SwiftUI-Sheets.md` | Sheet presentation | Decision guide (self-contained vs pure content); parent-managed NavigationStack; toolbar placements; platform considerations | **New content** — not covered in existing skills. |
| `SwiftUI-Forms.md` | Form best practices | When to use Form vs ScrollView; `.formStyle(.grouped)`; section organization; platform differences | **New content.** |
| `SwiftUI-Detail-Views.md` | Inline editing + full editor | Reminders-style progressive disclosure; inline tap-to-edit; temporary object pattern for create/edit reuse | **New content.** |
| `Swift-Style.md` | Swift style | Alphabetical imports (stub — very short) | **Minimal.** Could be a small addition to any style skill. |
| `App-Documentation-Guidelines.md` | README standards | What goes in a README (reason, functions, platforms, structure) | **Minimal.** |

### Code Patterns (from source)

| Pattern | Location | Notes |
|---------|----------|-------|
| NavigationContext | `GoldenPathKitUI/Navigation/` | Navigation state management — TODO.md notes this is still being researched |
| ModelManager | `GoldenPathKitUI/ModelManager.swift` | Centralized model management |
| Multi-platform targets | iOS + macOS app targets | Demonstrates shared package across platforms |

### CLAUDE.md

Contains a comprehensive project overview describing intended scope: iOS, macOS, watchOS, Widgets, Vapor backend, Swift Lambda, CLI. Most of these are aspirational — only iOS and macOS app shells exist.

### TODO.md

Research links on SwiftUI navigation patterns (Coordinator pattern, flow navigation, app router). Not yet synthesized into guidance.

## Recommendations for Skill Absorption

### High Priority — Merge into `swift-swiftui` skill:
1. **MV Architecture / Domain Services** — The domain services pattern (predicates, calculators, organizers) and `@Observable` model guidance complement the existing skill. The CLI reuse pattern is a valuable addition.
2. **View Composition** — `@ViewBuilder` computed property convention for breaking up views.
3. **Sheet Presentation** — Complete sheet patterns (self-contained vs pure content, parent-managed NavigationStack).

### Medium Priority — New sub-skill or skill section:
4. **Forms** — When to use Form, `.formStyle(.grouped)`, platform differences.
5. **Detail Views / Inline Editing** — The progressive disclosure pattern with temporary object creation.

### Low Priority — Extract if scope grows:
6. **Swift Style** — Currently just "alphabetical imports." Could grow.
7. **Documentation Guidelines** — Very short. May not justify its own skill.

### Not Ready:
8. **Navigation** — Still being researched (per TODO.md). Don't absorb yet.

## Content NOT in GoldenPath (gaps)

Per CLAUDE.md, the repo was intended to also cover:
- watchOS patterns
- Widget development
- Vapor (server-side Swift)
- AWS Lambda (Swift)
- CLI applications
- SwiftData patterns (beyond basic `@Query`)

These are mentioned in the reorganization plan as future skills but don't exist in GoldenPath yet.
