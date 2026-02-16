# Absorb GoldenPath Content into Skills

## Relevant Skills

| Skill | Description |
|-------|-------------|
| `swift-swiftui` | SwiftUI Model-View architecture patterns — target for most new content |
| `swift-architecture` | 4-layer architecture — reference for layer placement and code style conventions |
| `swift-testing` | Test style guide — used in validation phase |

## Background

The [GoldenPath](https://github.com/gestrich/GoldenPath) repo contains a `Principles/` directory with 6 authored guideline documents covering SwiftUI patterns (sheets, forms, detail views, style guide), MV architecture (domain services), and Swift style. An [inventory](2026-02-15-c-goldenpath-inventory.md) was completed identifying what content is new vs overlapping with existing skills.

The `swift-swiftui` skill already uses a multi-file structure with sub-documents (model-state.md, alerts.md, etc.) linked from a navigation table in SKILL.md. New GoldenPath content fits naturally as additional sub-files in this skill.

**What's being absorbed (5 docs from `Principles/`):**

| Source Doc | Lines | Overlap | Action |
|------------|-------|---------|--------|
| `SwiftUI-Sheets.md` | 283 | Low | New sub-file `sheets.md` |
| `SwiftUI-Forms.md` | 239 | None | New sub-file `forms.md` |
| `SwiftUI-Detail-Views.md` | 257 | None | New sub-file `detail-views.md` |
| `MV-Architecture.md` | 258 | Medium | New sub-file `domain-services.md` (unique content only) |
| `SwiftUI-Style-Guide.md` | 160 | Low | New sub-file `view-composition.md` |

**What's NOT being absorbed (and why):**
- `Swift-Style.md` (5 lines) — alphabetical imports already covered in `swift-architecture/code-style.md`
- `App-Documentation-Guidelines.md` (8 lines) — too minimal for a skill
- Navigation patterns (code + TODO.md) — still being researched per GoldenPath TODO.md; not ready
- SwiftData patterns (ModelManager.swift, Foo.swift) — code examples without authored principles; candidate for a future `swift-swiftdata` skill

**Conventions to follow:**
- Sub-files have no YAML frontmatter (only SKILL.md has that)
- Start with `# Title` then a brief description line
- Use `##` section headings with code examples
- Use "Preferred" / "Avoid" comparisons where applicable
- Keep each sub-file under 500 lines
- Content should be distilled guidance, not a copy-paste from GoldenPath

## Phases

## - [ ] Phase 1: Add `sheets.md` to swift-swiftui

**Skills to read**: `swift-swiftui`

**Source:** `../GoldenPath/Principles/SwiftUI/SwiftUI-Sheets.md` (283 lines)

Create `plugin/skills/swift-swiftui/sheets.md` covering sheet presentation patterns:

- **Quick decision table**: self-contained vs pure content vs boolean-based vs item-based
- **Parent-managed NavigationStack** (preferred pattern for reusability)
- **Self-contained vs pure content views**: when to use each, with code examples
  - Self-contained: complex internal state, multiple form fields (e.g., CreateTaskView)
  - Pure content (preferred): reusable in multiple contexts, parent controls presentation
- **Standard patterns**: `.sheet(item:)` preferred over `.sheet(isPresented:)` for type safety
- **Toolbar placements**: `.cancellationAction`, `.confirmationAction` — correct placement names
- **Platform considerations**: iOS presentation detents, background customization
- **Common mistakes**: mixing presentation patterns, wrong toolbar placements

Cross-reference `alerts.md` for the related `.alert` presentation pattern.

## - [ ] Phase 2: Add `forms.md` to swift-swiftui

**Skills to read**: `swift-swiftui`

**Source:** `../GoldenPath/Principles/SwiftUI/SwiftUI-Forms.md` (239 lines)

Create `plugin/skills/swift-swiftui/forms.md` covering Form best practices:

- **When to use Form**: data entry, settings, configuration, detail views with editable content
- **When NOT to use Form**: read-only content, custom layouts, mixed content types
- **Form vs ScrollView decision**: key rule — never wrap Form in ScrollView on iOS (it scrolls internally); macOS may need ScrollView wrapper
- **`.formStyle(.grouped)`**: always apply for consistent spacing across platforms; critical on macOS for sheets
- **Section organization**: headers, content, footers, help text patterns
- **Create/Edit view pattern**: NavigationStack + toolbar placement + disabled state for validation
- **Platform differences**: iOS auto-scrolls, macOS renders non-scrolling by default
- **Migration guide**: ScrollView + VStack → Form conversion steps

## - [ ] Phase 3: Add `detail-views.md` to swift-swiftui

**Skills to read**: `swift-swiftui`

**Source:** `../GoldenPath/Principles/SwiftUI/SwiftUI-Detail-Views.md` (257 lines), supplemented by `FooDetailView.swift` patterns

Create `plugin/skills/swift-swiftui/detail-views.md` covering detail view and inline editing patterns:

- **Progressive disclosure principle**: quick edits in-list, full editor in modal (Apple Reminders-style)
- **Inline editing mode**:
  - Tap to activate text field editing
  - Single item editing at a time (editingItemID pattern)
  - Automatic save behavior, Done button coordination
  - `InlineEditableRowView` pattern with `@Bindable` binding
- **Full editor modal**:
  - When to use (info button tap, creating new items, complex properties)
  - **Temporary object pattern**: same editor view handles both create and edit via `isNewItem` flag
  - Benefits: simpler code, type safety, clean separation
- **List + detail coordination**: state management with `editingItemID`, `endInlineEditing()` callback
- **Detail view sections**: using GroupBox for visual grouping (metadata, content, tags, relationships, actions)
- **Implementation checklist**

Cross-reference `sheets.md` for modal presentation and `model-state.md` for state management.

## - [ ] Phase 4: Add `domain-services.md` to swift-swiftui

**Skills to read**: `swift-swiftui`, `swift-architecture`

**Source:** `../GoldenPath/Principles/Architecture/MV-Architecture.md` (258 lines) — extract only the content NOT already in `model-state.md`

Create `plugin/skills/swift-swiftui/domain-services.md` covering the domain services pattern:

- **What are domain services**: focused structs that organize business logic by concern (not ViewModels)
- **Naming conventions by purpose**:
  - Predicates/Filters: `SchedulingPredicates`, `CompletionFilters`
  - Calculations: `CompletionCalculator`, `ScheduleEstimator`
  - Organization: `TaskOrganizer`, `CategoryGrouper`
  - Operations: `ImportOperations`, `SyncOperations`
- **Static predicates pattern**: define `@Query`/`FetchDescriptor` predicates as static methods on models for reuse across SwiftUI views and CLI
- **Data transformation methods**: static methods for processing query results, shared between UI and CLI
- **When to split a service**: ~150 lines threshold — break into focused services
- **CLI reuse**: same predicates and transformations work in both `@Query` (SwiftUI) and `FetchDescriptor` (CLI/services)

**Important**: Do NOT duplicate the MV architecture overview, `@Observable` patterns, or state management content — those are already in `model-state.md` and the SKILL.md hub.

## - [ ] Phase 5: Add `view-composition.md` to swift-swiftui

**Skills to read**: `swift-swiftui`

**Source:** `../GoldenPath/Principles/SwiftUI/SwiftUI-Style-Guide.md` (160 lines)

Create `plugin/skills/swift-swiftui/view-composition.md` covering view composition and platform conventions:

- **`@ViewBuilder` computed properties**: break up complex view bodies into named sections
  - Pattern: `private var headerSection: some View { ... }`
  - Benefits: readability, organization, no performance cost (not separate View structs)
  - When to use: body exceeds ~30 lines, logically distinct sections
  - When to extract to separate View: reused across multiple parents, needs its own state
- **Platform-specific API awareness**:
  - `.navigationBarTitleDisplayMode()` is iOS-only — use `.navigationTitle()` on macOS
  - Document other common macOS-incompatible APIs as encountered
- **`.sheet(item:)` over `.sheet(isPresented:)` with Bool**: type safety, automatic dismissal, single source of truth (cross-reference `sheets.md` for full patterns)

## - [ ] Phase 6: Update swift-swiftui SKILL.md navigation table

**Skills to read**: `swift-swiftui`

Update `plugin/skills/swift-swiftui/SKILL.md` to add all 5 new sub-files to the navigation table:

| Topic | When to Use | Document |
|-------|-------------|----------|
| Sheet presentation patterns | Presenting sheets, choosing sheet type | [sheets.md](sheets.md) |
| Form best practices | Building forms, settings views, data entry | [forms.md](forms.md) |
| Detail views and inline editing | Detail screens, inline edit mode, create/edit reuse | [detail-views.md](detail-views.md) |
| Domain services | Organizing business logic, static predicates, CLI reuse | [domain-services.md](domain-services.md) |
| View composition | Breaking up views, platform API differences | [view-composition.md](view-composition.md) |

Preserve the existing entries. Add new entries after the existing ones.

## - [ ] Phase 7: Validation

**Skills to read**: `swift-testing`, `swift-swiftui`

Validate all new and modified files:

- **Line count**: Verify each new sub-file stays under 500 lines
- **No frontmatter**: Sub-files should NOT have YAML frontmatter
- **Heading structure**: Each starts with `# Title`, uses `##` for sections
- **Cross-references**: Verify all cross-references between sub-files use correct filenames
- **Navigation table**: Confirm SKILL.md table links resolve to actual files
- **No duplication**: Check that domain-services.md does not duplicate content from model-state.md
- **Code examples**: Verify all code examples compile conceptually (correct Swift syntax)
- **Content accuracy**: Spot-check that distilled content accurately represents the GoldenPath source material
