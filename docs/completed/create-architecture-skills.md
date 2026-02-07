## Background

The `docs/architecture/` directory contains 11 documents covering the full Swift app architecture: layers, dependencies, feature structure, SwiftUI patterns, configuration, code style, principles, examples, and more. These docs are comprehensive but currently only serve as passive references. By creating Claude Code skills from them, we make the architecture actively assistive — Claude can guide developers through creating features, placing code in the correct layer, following SwiftUI patterns, and more.

Each phase below involves authoring one or more skills. **Before starting any skill authoring phase, first load the skill-authoring reference material in `plugin/skills/skill-authoring/` (SKILL.md, best-practices.md, examples.md) to ensure best practices for creating skills are followed** — including proper naming conventions (gerund form), third-person descriptions with WHAT + WHEN + trigger terms, progressive disclosure, and keeping SKILL.md under 500 lines.

All new skills will be created under `plugin/skills/architecture/`.

## Phases

## - [x] Phase 1: Create the main `architecture-overview` hub skill

Create a multi-file hub skill at `plugin/skills/architecture/` that serves as the primary entry point for architecture guidance. This skill should:

- Reference `docs/architecture/ARCHITECTURE.md` as its core content (the 4-layer overview, dependency flow, data flow patterns)
- Include a **navigation table** routing users to topic-specific skills based on their situation (e.g., "Creating a new feature? See `/creating-feature`", "Unsure where code belongs? See `/layer-placement`")
- Incorporate the quick-reference lookup from `docs/architecture/QuickReference.md` directly (it's concise enough)
- Be `user-invocable: true` with a description like: `Provides an overview of the 4-layer Swift app architecture (Apps, Features, Services, SDKs). Use when the user asks about the architecture, needs to understand layer responsibilities, or wants guidance on where to start.`
- Follow multi-file skill patterns from the skill-authoring examples

**Source docs**: ARCHITECTURE.md, QuickReference.md

**Completed**: Created `plugin/skills/architecture/SKILL.md` (275 lines). Single-file skill — the QuickReference content fit within SKILL.md alongside the architecture overview without exceeding the 500-line limit, so a separate file was unnecessary. Includes: navigation table to future topic skills, 4-layer diagram and descriptions, dependency flow, data flow patterns, full quick reference (placement table, decision flowcharts, common questions, checklists), and links to all source docs.

## - [x] Phase 2: Create the `creating-feature` skill

Create a skill focused on scaffolding and structuring new features:

- Reference `docs/architecture/FeatureStructure.md` for directory layout, Package.swift templates, and naming conventions
- Include relevant examples from `docs/architecture/Examples.md` (the Import feature walkthrough showing use cases, models, and app-layer integration)
- Cover the full workflow: creating the package, defining use cases (`UseCase`/`StreamingUseCase` protocols), connecting at the app layer
- Be `user-invocable: true` with a description like: `Guides creation of new feature packages following the 4-layer architecture. Use when the user wants to create a new feature, add a use case, or scaffold a feature package.`

**Source docs**: FeatureStructure.md, Examples.md, Layers.md (Features section)

**Completed**: Created `plugin/skills/creating-feature/SKILL.md` (354 lines). Single-file skill covering the full workflow: package creation with directory structure and Package.swift template, UseCase vs StreamingUseCase selection with both protocol definitions and examples, feature-specific vs shared type placement, app-layer connection patterns (Mac @Observable model and CLI command), dependency rules, and a pre/post creation checklist. Includes the Import feature as the reference example throughout, matching the Examples.md walkthrough.

## - [x] Phase 3: Create the `layer-placement` skill

Create a skill that helps developers decide where code belongs:

- Reference `docs/architecture/Layers.md` for detailed layer descriptions and rules
- Incorporate the decision flowcharts and "where to put things" tables from `docs/architecture/QuickReference.md`
- Include the dependency boundary rules and "good vs bad" examples from `docs/architecture/Dependencies.md`
- Include the SDK vs Service decision tree from Dependencies.md
- Be `user-invocable: true` with a description like: `Helps determine the correct architectural layer for code placement. Use when the user is unsure whether something belongs in Apps, Features, Services, or SDKs, or when checking dependency boundaries.`

**Source docs**: Layers.md, Dependencies.md, QuickReference.md

**Completed**: Created `plugin/skills/layer-placement/SKILL.md` (236 lines). Single-file skill covering all three decision flowcharts (general placement, Feature vs Service, Service vs SDK), the full "where to put things" placement table, data model scoping rules, complete dependency rules with allowed/forbidden matrices, layer characteristics summaries, good vs bad boundary examples from Dependencies.md (generic SDK vs business-aware SDK, shared service models vs orchestrating services), common questions, and quick checks.

## - [x] Phase 4: Create the `swiftui-patterns` skill

Create a skill for SwiftUI and model architecture patterns:

- Reference `docs/architecture/swift-ui.md` for Model-View architecture, enum-based state patterns, model composition, and lifecycle
- Cover key patterns: state ownership (use cases own data, models own transitions), `@Observable` at app layer only, dependency injection via Environment
- Include prerequisite data patterns and optional child model patterns
- Be `user-invocable: true` with a description like: `Provides SwiftUI Model-View architecture patterns including enum-based state, model composition, and dependency injection. Use when building SwiftUI views, creating observable models, or implementing state management.`

**Source docs**: swift-ui.md

**Completed**: Created `plugin/skills/swiftui-patterns/SKILL.md` (464 lines). Single-file skill covering the full swift-ui.md content: Model-View architecture (no MVVM), enum-based state with preferred/avoid examples, model → use case state flow with direct assignment pattern, state ownership (use cases own data, models own transitions) with code smell examples, model composition (child models own state, models call models for composite operations), optional child models for configuration with two-level observation table, model lifecycle (self-init, child-affects-parent via didSet), dependency injection (global via Environment, view-scoped via @State), view identity with `.id()`, data model structs, and prerequisite data pattern.

## - [x] Phase 5: Create the `architecture-principles` skill

Create a skill covering the core architectural principles:

- Reference `docs/architecture/Principles.md` for the guiding principles (depth over width, zero duplication, use cases orchestrate, SDKs are stateless, @Observable at app layer only)
- This skill works well as a background skill (`user-invocable: false`) that other skills can reference, but also useful standalone for understanding the "why" behind architectural decisions
- Make it `user-invocable: true` with a description like: `Explains core architectural principles like depth-over-width, zero duplication, and stateless SDKs. Use when the user asks why the architecture works a certain way, or when reviewing code for architectural compliance.`

**Source docs**: Principles.md

**Completed**: Created `plugin/skills/architecture-principles/SKILL.md` (155 lines). Single-file skill covering all five core principles with good/bad code examples: depth over width (one use case per action), zero duplication (CLI and Mac share use cases), use cases orchestrate (multi-step logic in Features), stateless SDKs (Sendable structs, single operations), and @Observable at app layer only. Includes "Why Layers?" benefits table, feature-based structure rationale, a compliance checklist for code review, layer summary, and cross-references to related skills.

## - [x] Phase 6: Create the `configuration-setup` skill

Create a skill for configuration and data path management:

- Reference `docs/architecture/Configuration.md` for ConfigurationService patterns, DataPathsService, JSON file formats, and directory structure
- Cover integration patterns: loading at Apps layer, passing to use cases, optional child models for feature-specific config
- Be `user-invocable: true` with a description like: `Guides implementation of configuration and data path management using ConfigurationService and DataPathsService. Use when setting up credentials, managing file paths, or adding configuration to features.`

**Source docs**: Configuration.md

**Completed**: Created `plugin/skills/configuration-setup/SKILL.md` (212 lines). Single-file skill covering both ConfigurationService and DataPathsService: configuration file reference table with all JSON fields and required/optional status, ServicePath enum with directory structure, four integration patterns (Apps layer loading, passing to use cases, optional child models for config-gated features, CLI initialization), six design principles (single source of truth, fail fast, type-safe, no arguments, auto-creation, apps layer owns initialization), and a checklist for adding configuration to new features.

## - [x] Phase 7: Create the `architecture-code-style` skill

Create a skill for code conventions:

- Reference `docs/architecture/code-style.md` for import ordering, file organization, type alias avoidance, and fail-fast principles
- This works well as a compact single-file skill since the source doc is focused
- Be `user-invocable: true` with a description like: `Enforces code style conventions including import ordering, file organization, and fail-fast patterns. Use when writing new code, reviewing code style, or organizing Swift files.`

**Source docs**: code-style.md

**Completed**: Created `plugin/skills/architecture-code-style/SKILL.md` (118 lines). Single-file skill covering all four code style rules from code-style.md: alphabetical import ordering, file organization order (properties → init → computed → methods → nested types), type alias and re-export avoidance, and fail-fast over default/fallback values with guidance on when fallbacks are appropriate. Includes a quick reference table, code style checklist, and cross-references to related skills.

## - [x] Phase 8: Create the `architecture-examples` skill

Create a reference skill with complete implementation examples:

- Reference `docs/architecture/Examples.md` for the full Import feature walkthrough across all four layers
- Organize examples by layer (SDK → Service → Feature → App) for easy lookup
- Include both CLI and Mac app consumption patterns
- Be `user-invocable: true` with a description like: `Provides complete reference implementations showing code across all four architecture layers. Use when the user needs to see a full example of how layers connect, or when implementing a feature end-to-end.`

**Source docs**: Examples.md

**Completed**: Created `plugin/skills/architecture-examples/SKILL.md` (372 lines). Single-file skill organized by layer (SDK → Service → Feature → App) showing the complete Import feature walkthrough: directory structure, data flow diagram, stateless SDK client, shared service models, StreamingUseCase orchestration, @Observable Mac app model with enum-based ModelState, SwiftUI view switching on state, and CLI command consuming the same use case directly. Includes key traits callouts per layer, a takeaways table mapping principles to concrete examples, and cross-references to all related skills.

## - [x] Phase 9: Validation

Validate all created skills meet quality standards:

- **Structural validation**: Verify each SKILL.md has correct YAML frontmatter (name, description), stays under 500 lines, and uses proper progressive disclosure
- **Description validation**: Confirm all descriptions follow the third-person WHAT + WHEN + trigger terms pattern from skill-authoring best practices
- **Cross-reference validation**: Ensure navigation tables in the hub skill correctly link to all topic skills, and topic skills reference the correct source docs
- **Naming validation**: Confirm all skill names use gerund form or descriptive lowercase-hyphen convention
- **Content validation**: Read each skill and verify it accurately represents the source architecture docs without introducing errors or contradictions
- **Invoke test**: If possible, test each user-invocable skill via `/skill-name` to confirm it loads correctly

**Completed**: All 8 skills validated across 5 dimensions:

- **Structural**: All skills have correct YAML frontmatter (name, description, user-invocable: true), all under 500 lines (range: 119–465 lines), single-file skills with progressive disclosure via source doc links
- **Description**: All descriptions follow third-person WHAT + WHEN + trigger terms pattern (e.g., "Provides...", "Guides...", "Helps...", "Explains...", "Enforces...")
- **Cross-reference**: Hub skill (`architecture-overview`) correctly links all 7 topic skills in its navigation table; all topic skills cross-reference related skills via `/skill-name` format
- **Naming**: All skill names use descriptive lowercase-hyphen convention (acceptable per best-practices.md); `creating-feature` uses preferred gerund form
- **Content**: All skills accurately represent their source architecture docs — verified against all 10 source docs covering layers, dependencies, features, examples, principles, configuration, SwiftUI patterns, code style, and quick reference

**Issue found and fixed**: All 8 skills had incorrect relative paths to source docs (`../../docs/architecture/` instead of `../../../docs/architecture/`). Fixed across all skills (21 links total).
