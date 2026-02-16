# Swift Skills Reorganization

## Background

Voice dump from Bill — raw ideas for reorganizing skills across repositories. This is a planning/brainstorming doc, not yet actionable phases.

## Key Ideas

### 1. Rename & Consolidate into "Swift Skills" Repository

- Rename `swift-app-architecture` repo to **`swift-skills`** (or similar)
- This becomes the single home for all Swift-related skills
- Skills to include:
  - **SwiftUI** (already exists as `swift-swiftui`)
  - **Clean Architecture** — rename current "layered architecture" to reflect it's Bill's interpretation of clean architecture
  - **AWS Lambda** (Swift) — new skill
  - **Vapor** (server-side Swift) — new skill
  - **CLI Applications** — already exists but needs better organization
  - Additional skills TBD

### 2. Absorb Learnings from Other Repos

- There's a repo called something like "Golden*" under `gestrich/` on GitHub — pull learnings from that into the Swift skills repo
- Bill has several repos with Swift experiments and learnings about:
  - SwiftUI patterns and best practices
  - Swift language features and idioms
- **Idea:** Convert individual experiments/learnings into small, focused skills
- Example: Each significant learning or best practice becomes its own skill file

### 3. Python Skills Repo

- Bill also has a Python repository with skills
- Mentioned as context but no specific action proposed yet
- May follow a similar consolidation pattern later

### 4. Better Skill Discovery & Planning Workflow

**Problem:** The current tooling that discovers skills from `CLAUDE.md` does a poor job of actually *reading* and *applying* them during planning. It finds skills but doesn't invoke them before starting work.

**Proposed solution:** Create a more thorough planning workflow (as a skill or CLI tool) that:
- Takes an **inventory of all available skills**
- Outlines what each skill provides
- Creates a **binary checklist** for each task: "Should I use this skill? Yes/No"
- Forces the agent to actually read relevant skills before starting development
- Trade-off: Slower development but much higher accuracy and consistency

### 5. Organizing Swift Experiments as Skills

- Bill has multiple repos with Swift experiments and best practices
- Idea: Bring experiments into the skills repo as small, focused skill files
- Each learning/experiment becomes a discrete skill
- Could organize under the main Swift skill as sub-skills
- Example: All Swift language learnings could live under a `swift` skill umbrella

## Answers to Open Questions

- **"Golden*" repo:** https://github.com/gestrich/GoldenPath — pull learnings from here
- **Skill granularity:** Group by **topic**, not one per experiment
- **Planning workflow:** Bill has an existing skill for this — will share later. Not in scope here.

## Open Questions

- Should the Python skills follow the same pattern?
- How to handle the rename from `swift-app-architecture` → `swift-skills` without breaking existing references (OpenClaw `extraDirs`, etc.)

## Next Steps

- [ ] Clone and inventory https://github.com/gestrich/GoldenPath
- [ ] Inventory what skills/content exists across Bill's Swift experiment repos
- [ ] Propose a concrete directory structure for the consolidated `swift-skills` repo
- [ ] Create actionable phases for the migration
