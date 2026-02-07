# Skill Examples

Annotated examples of well-structured skills from the ForeFlight repository.

## Example 1: Simple Single-File Skill

**Skill**: `feature-flags`

This skill demonstrates a focused, single-file approach for a specific domain.

### What Makes It Good

```yaml
---
name: feature-flags
description: Encapsulates knowledge about FlagKit and feature flag patterns. Use when adding feature flags, understanding flag configuration, or gating features during development.
user-invocable: true
---
```

**Description analysis:**
- Third person ("Encapsulates knowledge...")
- Explains WHAT: "FlagKit and feature flag patterns"
- Explains WHEN: "adding feature flags, understanding flag configuration, gating features"
- Includes trigger terms users would say

### Structure Highlights

```markdown
# Feature Flags Skill

## When to Use
[Clear list of situations]

## Architecture Overview
[Visual diagram using ASCII art]

## Key Files
[Table of important files]

## Adding a New Feature Flag
[Step-by-step instructions with code examples]

## Checklist for Adding a New Flag
[Actionable checklist]

## Related Skills
[Cross-references to other skills]
```

**Patterns to emulate:**
- "When to Use" section upfront
- Architecture diagram for visual learners
- Key files table for quick reference
- Checklist for common tasks
- Cross-references to related skills

---

## Example 2: Multi-File Skill with Navigation

**Skill**: `design-kit`

This skill demonstrates progressive disclosure with a navigation table.

### What Makes It Good

```yaml
---
name: design-kit
description: Provide context about the DesignKit package for ForeFlight's SwiftUI design system.
user-invocable: true
---
```

### Structure Highlights

```markdown
# DesignKit Design System

## Which Document Do I Need?

| Situation | Document |
|-----------|----------|
| Writing new SwiftUI code | [designkit-2.0.md](designkit-2.0.md) |
| Understanding existing legacy code | [designkit-1.0.md](designkit-1.0.md) |
| Converting 1.0 code to 2.0 | [migration.md](migration.md) |

## Quick Start
[Minimal working example]

## Package Location
[Essential reference info]

## Documentation Index
[Complete list of reference files]
```

**Patterns to emulate:**
- Navigation table as first major section
- Situation-based routing ("If you're doing X, go here")
- Quick start example before detailed docs
- Documentation index at the end

### File Organization

```
design-kit/
├── SKILL.md           # 74 lines - overview and navigation
├── designkit-1.0.md   # Legacy API reference
├── designkit-2.0.md   # Modern API reference
└── migration.md       # Migration patterns
```

---

## Example 3: Complex Multi-Document Skill

**Skill**: `app-architecture`

This skill demonstrates handling complex, interconnected topics.

### What Makes It Good

```yaml
---
name: app-architecture
description: Encapsulates knowledge about FFM's composition root pattern, FFSL service locator, and how services are wired together. Use when creating composition roots, understanding service dependencies, or integrating features with the main app.
user-invocable: true
---
```

**Description analysis:**
- Lists specific patterns: "composition root pattern, FFSL service locator"
- Concrete use cases: "creating composition roots, understanding service dependencies"

### Structure Highlights

```markdown
# FFM App Architecture

## Which Document Do I Need?

| Situation | Document |
|-----------|----------|
| Creating a new service/composition root | [composition-root.md](composition-root.md) |
| Understanding FFSL service locator | [ffsl-service-locator.md](ffsl-service-locator.md) |
| Adding UI to a feature in FFM libraries | [libraries-conventions.md](libraries-conventions.md) |

## Quick Overview

### Architecture Hierarchy
[ASCII diagram showing relationships]

### Key Concepts
[Numbered list of core ideas]

### When to Use What
[Decision table]

## Key Files
[Table with file paths and purposes]

## Related Commands
[Slash commands that work with this skill]
```

**Patterns to emulate:**
- Quick overview with visual hierarchy
- "When to Use What" decision table
- Related commands section for discoverability
- Key files table for navigation

---

## Example 4: Background Skill (Non-Invocable)

**Skill**: `module-structure`

This skill demonstrates a knowledge skill that Claude uses automatically.

### What Makes It Good

```yaml
---
name: module-structure
description: Explains ForeFlight iOS package architecture, layers (features, services, sdks, ui-toolkits, utilities), and the FFM target. Use when creating Swift packages, adding packages to the ForeFlight target, editing dependencies.yml, understanding where code belongs, or asking about modular architecture.
user-invocable: false
---
```

**Key difference:** `user-invocable: false` means:
- Not shown in slash command menu
- Claude still activates it automatically based on context
- Good for foundational knowledge that supports many tasks

**When to use `user-invocable: false`:**
- Knowledge that applies across many different tasks
- Background context rather than specific workflows
- Skills that other skills reference

---

## Template: Starting a New Skill

Copy this template when creating a new skill:

```yaml
---
name: my-skill-name
description: [Action verb] [specific capabilities]. Use when [situations] or when the user mentions [trigger terms].
user-invocable: true
---

# [Skill Title]

[One sentence overview]

## When to Use

Use this skill when:
- [Specific situation 1]
- [Specific situation 2]
- [Specific situation 3]

## Quick Start

[Minimal working example or essential steps]

## Key Information

[Core content - the essential stuff]

## Key Files

| File | Purpose |
|------|---------|
| `path/to/file` | Description |

## Related Skills

- **skill-name** — Brief description of relationship

## Related Commands

- `/command-name` — What it does
```

---

## Checklist: Is My Skill Ready?

Use this checklist before committing a new skill:

- [ ] **Name**: Lowercase, hyphens, gerund form preferred
- [ ] **Description**: Third person, WHAT + WHEN, includes trigger terms
- [ ] **SKILL.md**: Under 500 lines
- [ ] **Navigation**: Table if multi-file
- [ ] **Quick start**: Working example early in the file
- [ ] **Key files**: Table of important paths
- [ ] **Related**: Cross-references to other skills/commands
- [ ] **Tested**: Verified with actual tasks
