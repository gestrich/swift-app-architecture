# Swift Best Practices Ecosystem

## Relevant Skills

| Skill | Description |
|-------|-------------|
| `swift-architecture` | 4-layer architecture conventions — the primary source of truth this ecosystem enforces |
| `swift-swiftui` | SwiftUI Model-View conventions — a second body of conventions to enforce and evolve |

---

## Background

This repo (`swift-app-architecture`) holds architectural skills for Claude Code and Codex. The vision is to expand it into a full **Swift best-practices ecosystem** with three pillars:

1. **Demo application inside this repo** — a canonical Swift monorepo (iOS, watchOS, visionOS, Vapor, AWS Lambda) lives in this repo alongside the skills. Uses XcodeGen — no `.xcodeproj` checked in. The repo is now both the source of truth for best practices AND the canonical demo app that exemplifies them.

2. **Reusable conformance workflow (GitHub Actions)** — a reusable workflow defined in this repo that any repo can call. It runs daily, checks recent pushes for violations, walks the architectural roadmap, and opens fix PRs against the calling repo plus new-paradigm PRs against this best-practices repo. **First pilot: this repo runs the workflow on itself**, so the demo app is continuously kept in conformance.

3. **Self-improvement workflow** — a separate daily workflow that improves the skills content (`plugin/skills/`) — finds gaps and contradictions, stages improvement PRs.

### Key decisions

- **One repo, two roles**: This repo is both best-practices source AND demo app. Eliminates the synchronization problem between a separate starter repo and the skills.
- **Self-piloting**: The conformance workflow's first pilot is this repo itself. Tight feedback loop — when you change a skill, the next conformance run might create a PR to update the demo app.
- **Billing**: Use a standard Anthropic API key (`ANTHROPIC_API_KEY`) stored as a GitHub Actions secret. Pay-per-token billing. No OAuth hacks.
- **State management**: GitHub agentic workflow pattern — state stored as a dedicated branch (e.g. `claude/conformance-state`) holding JSON for roadmap position and last-run timestamp.
- **Reusable workflow**: Defined in `.github/workflows/conformance.yml` here, called by external repos via `uses: gestrich/swift-app-architecture/.github/workflows/conformance.yml@main`.
- **Two-directional PRs**: Conformance run can open PRs against (a) the calling repo for fixes, (b) this best-practices repo for new paradigms. Requires a fine-grained PAT with appropriate scopes.
- **Scope of AI instructions**: High signal-to-noise PRs only. One concern per PR. Architectural violations take priority over style nits. Instructions are a first-class deliverable.
- **Testing scope**: How to write unit tests, UI tests, and integration tests IS in scope. Tooling that lets AI interact with UI directly is OUT of scope.
- **XcodeGen**: Demo app uses XcodeGen — contributors only edit `.yml` project specs.

### Final repo layout (after all phases)

```
swift-app-architecture/
├── .claude-plugin/marketplace.json
├── .github/
│   ├── workflows/
│   │   ├── conformance.yml        ← reusable, callable by any repo (incl. this one)
│   │   ├── self-conformance.yml   ← scheduled caller of conformance.yml against this repo
│   │   └── self-improve.yml       ← improves skills content
│   └── agent-instructions.md      ← Claude's prompt for conformance runs
├── plugin/                        ← Claude/Codex plugin (skills)
│   ├── skills/
│   │   ├── swift-architecture/
│   │   └── swift-swiftui/
│   └── .codex-plugin/plugin.json
├── demo/                          ← canonical demo app (NEW)
│   ├── ios/
│   ├── watchos/
│   ├── visionos/
│   ├── vapor/
│   ├── lambda/
│   ├── shared/                    ← cross-target Swift packages
│   ├── project.yml                ← XcodeGen spec
│   └── README.md                  ← "deploy with AI" prompt template
├── AGENTS.md
├── CLAUDE.md
└── README.md
```

---

## Phases

## - [x] Phase 1: Design Agent Instructions

**Skills used**: `swift-architecture`, `swift-swiftui`
**Principles applied**: Anchored every check to a quoted skill excerpt with a path reference so PRs are auditable. Encoded the "one concern per PR, high-confidence only, drafts only" rules as hard gates rather than guidelines. Split each run into two passes (recent commits + one roadmap module) to bound work and PR volume. State stored as JSON on `claude/conformance-state` with `cycle` counter, `skipped_checks` ring-buffered to 50, and an explicit "never write partial state" rule so resumption is deterministic.

**Skills to read:** `swift-architecture`, `swift-swiftui`

The quality of every downstream phase depends on these instructions. Draft the prompt fed to Claude on each workflow run.

**Scope — what to check:**
- Composition root: present, correct, dependencies injected top-down
- Architectural layer violations: wrong-direction dependencies, code in wrong layer
- SwiftUI model/view separation
- Test conventions: how unit tests, UI tests, and integration tests should be structured
- Naming and structural conventions from the skills

**Scope — what NOT to flag:**
- Whitespace, minor formatting, comment style
- Incomplete features / WIP branches
- Framework-level choices (which test framework, which HTTP library) — tooling is out of scope
- Business logic correctness — Claude cannot know the app's intent

**PR quality rules:**
- One concern per PR — never bundle unrelated fixes
- PR body must quote the specific best-practice being violated, with a reference to the skill
- New-paradigm PRs against this repo must include a proposed SKILL.md draft, not just a description
- Do not open a PR unless confidence is high — if uncertain, skip and log it

**Roadmap sequencing:**
- Start at the composition root
- Walk downward: Apps layer → Features layer → Services layer → SDKs layer
- State tracks last layer/module checked so each run continues from the checkpoint

**Outcome:** `.github/agent-instructions.md` in this repo — the canonical prompt referenced by the workflow.

---

## - [ ] Phase 2: Research GitHub Agentic Workflow Patterns

**Skills to read:** none

Before writing YAML, confirm the building blocks:

**GitHub agentic workflow pattern:**
- Find GitHub's official agentic workflow examples
- Document the state-branch convention: branch name, JSON schema, how the agent reads/writes it
- Confirm the official Claude Code GitHub Action (`anthropics/claude-code-action`) — inputs, env vars, how it handles `ANTHROPIC_API_KEY`

**Reusable workflows:**
- Confirm `uses: gestrich/swift-app-architecture/.github/workflows/conformance.yml@main` works for cross-repo calls
- Confirm a workflow defined here can be triggered both on a schedule (in this repo) AND by a caller workflow in another repo
- Identify secret-passing syntax for the caller workflow

**Two-directional PR auth:**
- A fine-grained PAT (or GitHub App) with write access across multiple repos
- Document how the workflow uses one token for caller-repo PRs and a different one for upstream PRs against this repo

**Outcome:** A research note appended to this doc with verified patterns before any YAML is written.

---

## - [ ] Phase 3: Add Demo Application with XcodeGen

**Skills to read:** `swift-architecture`, `swift-swiftui`

Build out `demo/` in this repo so it exemplifies the skills.

**Coverage — minimum for V1:**
- iOS app (SwiftUI, observable models, composition root)
- Vapor server
- AWS Lambda function
- Shared Swift package(s) for SDKs/Services that the targets depend on

**Stretch (V2):**
- watchOS app
- visionOS app

**XcodeGen setup:**
- No `.xcodeproj` checked in — generated via `xcodegen generate`
- One or more `project.yml` files
- README in `demo/`: clone → `xcodegen generate` → open `.xcodeproj`

**Architectural conformance:**
- Each target follows the 4-layer architecture from `swift-architecture`
- SwiftUI screens follow `swift-swiftui` conventions
- Tests demonstrate the conventions for each test type (unit, UI, integration)

**AI-assisted bootstrap:**
- `demo/README.md` includes a prompt template a user can give to an AI agent: "starting from this repo, scaffold a new app that does X, deploy to Y"

**Outcome:** A buildable, deployable demo monorepo inside this repo that serves as living documentation. Becomes the input the conformance workflow validates against in Phase 4.

---

## - [ ] Phase 4: Implement Reusable Conformance Workflow + Self-Pilot

**Skills to read:** none

Create the reusable workflow and wire this repo up as the first caller.

**Files:**
```
.github/
├── workflows/
│   ├── conformance.yml          ← reusable (workflow_call)
│   └── self-conformance.yml     ← scheduled caller targeting this repo
└── agent-instructions.md        ← from Phase 1
```

**`conformance.yml` responsibilities:**
1. Check out the calling repo
2. Read state branch (`claude/conformance-state`) for roadmap position and last-run timestamp
3. Run the Claude Code action with `ANTHROPIC_API_KEY` and the agent instructions
4. Claude analyzes recent commits + continues roadmap walk → produces fix PRs against the calling repo
5. If new paradigms found → opens PRs against this best-practices repo using the upstream PAT
6. Write updated state back to the state branch

**`self-conformance.yml` (this repo's caller):**
```yaml
name: Self Conformance
on:
  schedule:
    - cron: '0 2 * * *'
  workflow_dispatch:

jobs:
  conformance:
    uses: ./.github/workflows/conformance.yml   # local reference, no network round-trip
    secrets:
      ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
      UPSTREAM_PAT: ${{ secrets.SWIFT_BEST_PRACTICES_PAT }}
```

> Self-pilot tests the workflow against the demo app inside this repo. Tight feedback loop: changes to skills can trigger PRs against the demo app on the next run.

**External repo adoption** (later, when ready):
```yaml
jobs:
  conformance:
    uses: gestrich/swift-app-architecture/.github/workflows/conformance.yml@main
    secrets:
      ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
      UPSTREAM_PAT: ${{ secrets.SWIFT_BEST_PRACTICES_PAT }}
```

**Outcome:** A working reusable workflow with this repo as the first pilot — the demo app gets continuous best-practice checks.

---

## - [ ] Phase 5: Self-Improvement Workflow for Skills Content

**Skills to read:** `swift-architecture`, `swift-swiftui`

A separate scheduled workflow at `.github/workflows/self-improve.yml` that runs daily on `plugin/skills/` (not the demo app):

**What it checks:**
- Gaps in coverage (e.g., Lambda, Vapor, watchOS patterns not yet documented)
- Internal contradictions between skills
- Unclear or ambiguous instructions
- Missing examples
- Stale guidance relative to Swift/SwiftUI evolution

**Same PR quality rules** as conformance. PRs against this repo only.

**Distinction from Phase 4 self-conformance:**
- Phase 4 (`self-conformance.yml`) — checks the **demo app** for skill conformance
- Phase 5 (`self-improve.yml`) — checks the **skills content** for clarity/gaps

**Outcome:** Daily PRs that incrementally improve skills content without manual curation.

---

## - [ ] Phase 6: Validation

**Skills to read:** none

**Phase 3 (demo app):**
- [ ] `cd demo && xcodegen generate` produces a buildable Xcode project from scratch
- [ ] iOS, Vapor, Lambda targets all build cleanly
- [ ] Tests demonstrate unit/UI/integration conventions

**Phase 4 (conformance workflow + self-pilot):**
- [ ] Manual `workflow_dispatch` of `self-conformance.yml` completes without errors
- [ ] State branch is created, JSON written, roadmap resumes correctly on second run
- [ ] If a deliberate violation is introduced into `demo/`, a fix PR is opened
- [ ] If a new-paradigm scenario is staged in `demo/`, an upstream PR is opened (when applicable)

**Phase 5 (self-improvement):**
- [ ] At least one quality improvement PR on first run
- [ ] No spurious/low-value PRs
