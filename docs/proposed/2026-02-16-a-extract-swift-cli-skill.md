# Extract swift-cli Skill from SwiftCLI Repo

## Relevant Skills

| Skill | Description |
|-------|-------------|
| `swift-architecture` | 4-layer Swift app architecture — placement guidance and code style |

## Background

Bill's [SwiftCLI](https://github.com/gestrich/SwiftCLI) repo contains a macro-based framework for building type-safe CLI tool wrappers in Swift. It uses `@CLIProgram`, `@CLICommand`, `@Flag`, `@Option`, `@Positional` macros with async execution via `CLIClient` and structured output parsing. This is a well-documented, clean repo that's already used by other Bill projects (PRRadar). The goal is to extract its patterns into a `swift-cli` skill in the `plugin/skills/` directory of this repo.

**Source repo:** https://github.com/gestrich/SwiftCLI

## Phases

## - [ ] Phase 1: Deep-dive SwiftCLI patterns

**Skills to read**: `swift-architecture`

Clone/read the SwiftCLI repo in detail. Document:
- All macro definitions and their usage patterns
- `CLIClient` async execution model
- Structured output parsing approach
- How it integrates with the 4-layer architecture (which layer does it belong in?)
- Example usage from PRRadar or other consumers
- Any conventions or best practices Bill follows

Produce a summary of extractable patterns and how they map to skill sections.

## - [ ] Phase 2: Create swift-cli skill

**Skills to read**: `swift-architecture`

Create `plugin/skills/swift-cli/SKILL.md` covering:
- When to use macro-based CLI wrappers vs raw `Process`
- Macro reference (`@CLIProgram`, `@CLICommand`, `@Flag`, `@Option`, `@Positional`)
- `CLIClient` usage and async patterns
- Structured output parsing
- Layer placement (likely SDKs layer)
- Code examples from SwiftCLI

## - [ ] Phase 3: Validation

Review the new skill for:
- Accuracy against the source repo
- Consistency with existing skill format (`swift-architecture`, `swift-swiftui`)
- No duplication with existing skills
- Skill description is clear and matches discovery criteria
