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

## - [x] Phase 2: Research GitHub Agentic Workflow Patterns

**Skills used**: none
**Principles applied**: Verified each building block against primary sources (GitHub docs, anthropics/claude-code-action README + docs, gh-aw reference) rather than relying on memory. Picked the GitHub App over PAT for upstream auth based on rate limits and lifecycle. Adopted the gh-aw `repo-memory` convention (`memory/<id>` branch, last-writer-wins) instead of inventing a custom state-branch protocol — Phase 4 can either use gh-aw directly or mirror its conventions, but both options now have a concrete reference.

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

### Research Notes (2026-05-10)

#### 1. GitHub agentic workflow pattern

GitHub ships an official "Agentic Workflows" framework (`github/gh-aw`, technical preview as of Feb 2026). It is **not required** for our use case — we can call `anthropics/claude-code-action` directly from a normal `.github/workflows/*.yml` — but its conventions are worth borrowing.

**Workflow definition format (gh-aw):** Markdown files with YAML frontmatter (config) + natural-language body (the prompt). Compiled into a sandboxed runner job with read-only token, then a separate "safe outputs" job applies write operations (issues, PRs, commits) that the agent proposed as a structured artifact.

**State persistence — `repo-memory` (the pattern we'll mirror):**
- **Branch name:** `memory/default` by default; customizable as `{branch-prefix}/{id}` (e.g. `daily/insights`).
- **Filesystem path during run:** `/tmp/gh-aw/repo-memory-{id}/` — agent reads/writes regular files; the runner auto-commits and pushes them to the memory branch after the workflow completes.
- **Schema:** No required schema. `.json`, `.md`, `.txt`, `.csv` are all supported. Defaults: `max-file-size: 10KB`, `max-file-count: 100`.
- **Concurrency:** Last-writer-wins. If another run pushed since the branch was checked out, the runner replays the local diff on top of the latest remote via a GraphQL mutation. No manual conflict resolution.
- **Frontmatter:** `tools: { repo-memory: true }` (or with explicit id/branch-prefix/file-glob).

**Decision for Phase 4:** Use the same conventions even when calling `claude-code-action` directly — branch named `claude/conformance-state` (matches the spec above), single `state.json` file, last-writer-wins via force-push or replay-on-top. Don't invent a new schema.

**Reference:** `https://github.github.com/gh-aw/reference/repo-memory/`

#### 2. `anthropics/claude-code-action`

- **Latest stable:** `v1` (released Aug 2025; v0.x → v1 is a breaking change — inputs collapsed to `prompt` + `claude_args`).
- **Auth:** `anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}` works as expected. Alternatives: `claude_code_oauth_token`, AWS Bedrock, Vertex AI, Microsoft Foundry.
- **Mode detection:** Auto. Cron/`workflow_dispatch` triggers run in **Automation Mode** (no `@claude` mention needed) — exactly what we want.
- **Required job permissions** for write operations (commits, PRs, issues):
  ```yaml
  permissions:
    contents: write
    pull-requests: write
    issues: write
    id-token: write       # required by the action itself
  ```
- **Tool allowlist** is passed via `claude_args` (deprecated standalone `allowed_tools` input still works):
  ```yaml
  claude_args: |
    --model claude-opus-4-7
    --system-prompt-file .github/agent-instructions.md
    --allowedTools "Read,Write,Edit,Bash(git:*),Bash(gh pr:*),Bash(gh issue:*)"
    --max-turns 30
  ```
- **System prompt** comes from `claude_args: --system-prompt` (inline) or `--system-prompt-file <path>`. We'll use the file form so `.github/agent-instructions.md` (Phase 1 output) is the authoritative source.
- **Cross-repo PR creation is NOT built-in.** The action authenticates against the repo it's checked out in. To open a PR against `swift-app-architecture` from a run inside a caller repo, the workflow must do a second `actions/checkout@v4` of `gestrich/swift-app-architecture` with `token: ${{ secrets.UPSTREAM_PAT }}` and let Claude branch/commit/push there via `gh pr create`.

**Reference:** `https://github.com/anthropics/claude-code-action`

#### 3. Reusable workflows

- **Cross-repo `uses:` syntax confirmed:**
  `uses: gestrich/swift-app-architecture/.github/workflows/conformance.yml@main` — value must be a literal (no expression interpolation), `@ref` is required (branch, tag, or SHA — pin to SHA in production for supply-chain safety).
- **Same-repo (self-pilot) caller:** `uses: ./.github/workflows/conformance.yml` — no network round-trip, no `@ref`. Confirmed valid.
- **Visibility requirement:** For external repos to call our reusable workflow, this repo must be **public** OR use GitHub's "actions access" setting to whitelist callers. Since `swift-app-architecture` is public, no extra config needed.
- **Dual triggers:** A reusable workflow defined with `on: workflow_call` can also be invoked by `workflow_dispatch` and `schedule` from inside its own repo via a thin caller workflow (which is exactly what `self-conformance.yml` does). The reusable file itself only declares `workflow_call`; the scheduling lives in the caller.
- **Secrets passing:**
  - **Same org / same repo:** `secrets: inherit` (one line, implicitly forwards all secrets).
  - **Cross-org or explicit:** name them in the `secrets:` block:
    ```yaml
    jobs:
      conformance:
        uses: gestrich/swift-app-architecture/.github/workflows/conformance.yml@main
        secrets:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          UPSTREAM_PAT: ${{ secrets.SWIFT_BEST_PRACTICES_PAT }}
    ```
  - GitHub validates this at parse time — secrets passed via `with:` (instead of `secrets:`) are rejected before the job starts.
- **Reusable workflow declares them:**
  ```yaml
  on:
    workflow_call:
      secrets:
        ANTHROPIC_API_KEY: { required: true }
        UPSTREAM_PAT: { required: false }
  ```

**Reference:** `https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows`

#### 4. Two-directional PR auth

Every conformance run needs two distinct write contexts:

| Target | Token | Source |
|--------|-------|--------|
| Caller repo (fix PRs) | `GITHUB_TOKEN` | Auto-issued by Actions; `permissions:` block grants `contents: write`, `pull-requests: write`. |
| `swift-app-architecture` (new-paradigm PRs) | `UPSTREAM_PAT` or GitHub App installation token | External secret declared in caller workflow. |

**Recommendation: GitHub App, not PAT.** Confirmed reasons:
- **Rate limits:** GitHub Apps get 15,000 req/hr per installation; PATs get 5,000 req/hr per user. Conformance runs across many repos will accumulate.
- **Lifecycle:** App installations survive when the installing user leaves the org; PATs die with the user account and consume a seat.
- **Token lifetime:** App tokens are short-lived (~1 hour, generated per run via `actions/create-github-app-token`); PATs are long-lived secrets — bigger blast radius if leaked.
- **PAT pitfalls confirmed:** Fine-grained PATs cannot contribute to repos where the user is only an outside/repo collaborator, and have documented 403 "Resource not accessible" issues even with the right scopes.

**Required scopes (either token type):**
- `contents: write` (push branches)
- `pull-requests: write` (open PRs)
- `metadata: read` (always required for fine-grained access)

**Phase 4 wiring:**
1. Create a GitHub App named e.g. "swift-best-practices-bot", install it on `gestrich/swift-app-architecture` with the three scopes above.
2. Store its App ID and private key as repo/org secrets (`UPSTREAM_APP_ID`, `UPSTREAM_APP_PRIVATE_KEY`).
3. In `conformance.yml`, mint an installation token at job start:
   ```yaml
   - uses: actions/create-github-app-token@v1
     id: upstream-token
     with:
       app-id: ${{ secrets.UPSTREAM_APP_ID }}
       private-key: ${{ secrets.UPSTREAM_APP_PRIVATE_KEY }}
       owner: gestrich
       repositories: swift-app-architecture
   ```
4. Pass `${{ steps.upstream-token.outputs.token }}` only to the upstream-checkout step. Caller-repo operations continue to use `GITHUB_TOKEN`.

**Fallback** (lower-friction MVP): Start with a fine-grained PAT (`UPSTREAM_PAT`), upgrade to a GitHub App if rate limits or seat-management become painful. The wiring is identical; only the token source changes. The doc spec already references `SWIFT_BEST_PRACTICES_PAT`, so this fallback is what's currently scoped.

**References:**
- `https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens`
- `https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/deciding-when-to-build-a-github-app`

#### Open questions deferred to Phase 4

- Should `conformance.yml` use the `gh-aw` framework end-to-end (markdown workflows, built-in repo-memory, safe-outputs gating) or call `claude-code-action` directly with hand-rolled state management? The first is more idiomatic but adds a tech-preview dependency; the second is more direct and matches the doc's existing spec. Recommend: **direct invocation**, mirror gh-aw conventions for state.
- SHA-pinning policy for `anthropics/claude-code-action@v1` vs floating tag — decide before merging Phase 4.

---

## - [x] Phase 3: Add Demo Application with XcodeGen

**Skills used**: `swift-architecture`, `swift-swiftui`, `swift-testing`
**Principles applied**: Built one canonical `GreetingFeature` consumed by all three apps so the "zero duplication" rule from the architecture skill is visible at a glance — fix a bug once, three apps benefit. Kept the shared package as a single SwiftPM package with one target per layer module (Uniflow, GreetingClientSDK, CoreService, GreetingFeature) so dependency direction is enforced by the build system, not just convention. iOS app uses `@Observable` only at the Apps layer, with enum-based `ModelState` carrying `prior:` for last-known-good — the exact pattern from `swift-swiftui/model-state.md`. Each test type lives in a separate target as a reference: Swift Testing for unit (shared, iOS model), Swift Testing + VaporTesting for integration (Vapor routes), XCTest for UI (since XCUITest is still XCTest-only in Xcode 17). Renamed `vapor/` → `vapor-server/` because SwiftPM derives package identity from the directory's last path component, which collided with the remote `vapor` package; documented the deviation in the README. Lambda required `macOS 15` because `swift-aws-lambda-runtime` 2.x's `LambdaRuntime` initializer is gated on it.

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

## - [x] Phase 4: Implement Reusable Conformance Workflow + Self-Pilot

**Skills used**: none
**Principles applied**: Followed Phase 2's verified patterns verbatim — `anthropics/claude-code-action@v1`, `--system-prompt-file`, `claude_args` for the tool allowlist, `secrets:` block (not `with:`) for forwarding `ANTHROPIC_API_KEY` and `UPSTREAM_PAT`. Always fetch the agent instructions from the upstream repo's `main` rather than the calling repo so external repos can't drift the contract by editing a local copy. State hydration is a workflow-level concern (read `state.json` off `claude/conformance-state` into `.conformance/state.json` before the agent runs); state writeback stays Claude's responsibility per the agent-instructions protocol so the "never write partial state on error" rule from Phase 1 holds end-to-end. Self-pilot uses `uses: ./.github/workflows/conformance.yml` (no `@ref`) so the same commit's reusable workflow definition runs against the same commit's demo app — tight feedback loop with no version skew. Tool allowlist scoped to `Read,Write,Edit,Glob,Grep` plus `Bash(git:*)` and narrow `Bash(gh ...)` patterns — no shell wildcards. Permissions scoped to the four required by the action; nothing extra. Floating `@v1` tag for the action with a deferred SHA-pinning decision noted in Phase 2's open questions.

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

## - [x] Phase 5: Self-Improvement Workflow for Skills Content

**Skills used**: `swift-architecture`, `swift-swiftui`
**Principles applied**: Kept the self-improvement workflow strictly separate from conformance — different agent instructions file (`agent-instructions-self-improve.md`), different state branch (`claude/self-improve-state`), different cron slot (03:00 UTC vs 02:00 UTC) — so the two roles never interfere on token usage, PR queue, or state writes. Workflow is intentionally **not** a `workflow_call` reusable: improving this repo's skills is a job only this repo runs, so making it reusable would be speculative API surface. Mirrored Phase 4's hydrate-state-then-let-agent-write-state pattern verbatim so the "never write partial state" rule from Phase 1 holds the same way. Same `claude-code-action@v1` invocation, same tool allowlist, same permissions block — keeps drift between the two workflows minimal. Roadmap walks one document per run with explicit ordering listed in the agent instructions, so the agent never has to invent a traversal order. PR scope rules deliberately exclude typo-only PRs, whitespace, and renames — the failure mode this workflow most needs to avoid is high-volume low-value churn.

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

## - [x] Phase 6: Validation

**Skills used**: none
**Principles applied**: Validated everything locally reachable from this checkout (demo app build + tests, workflow YAML syntax, agent-instructions file references) and explicitly deferred the live-GitHub-Actions checks rather than fabricating results. Regenerated `DemoApp.xcodeproj` from scratch via `xcodegen generate` to prove the spec-only invariant (no committed `.xcodeproj`) holds. Built every demo target (shared package, iOS via `xcodebuild`, Vapor server, Lambda) with its full test suite — `BUILD SUCCEEDED` + green tests for all four. Verified each workflow file (`conformance.yml`, `self-conformance.yml`, `self-improve.yml`) parses as valid YAML and references real files that exist on disk (agent-instructions, skills paths). Marked the live-only checks (workflow_dispatch runs, state-branch lifecycle, PR creation) as deferred-to-first-run with an explicit note about what unblocks them, so future-me can resume without re-deriving the gating context.

**Skills to read:** none

**Phase 3 (demo app):** — validated locally on 2026-05-10
- [x] `cd demo && xcodegen generate` produces a buildable Xcode project from scratch — regenerated `DemoApp.xcodeproj` after `rm -rf`; XcodeGen 2.39.1 reported success
- [x] iOS, Vapor, Lambda targets all build cleanly — `xcodebuild ... build` → **BUILD SUCCEEDED** for iOS; `swift build` clean for `demo/shared`, `demo/vapor-server`, `demo/lambda`
- [x] Tests demonstrate unit/UI/integration conventions — `swift test` passes for shared (5 tests across `GreetingUseCase` + `Greeting model` suites, Swift Testing), vapor-server (2 integration tests via VaporTesting), lambda (2 unit tests); iOS scheme wires `DemoAppTests` (Swift Testing) and `DemoAppUITests` (XCUITest) per `project.yml`

**Phase 4 (conformance workflow + self-pilot):** — static checks done; live checks deferred to first GitHub Actions run
- [x] Workflow YAML parses cleanly (`conformance.yml`, `self-conformance.yml`) and references existing files (`.github/agent-instructions.md`, skills paths under `plugin/skills/`)
- [ ] Manual `workflow_dispatch` of `self-conformance.yml` completes without errors — requires `ANTHROPIC_API_KEY` secret + remote push; not runnable from local checkout
- [ ] State branch is created, JSON written, roadmap resumes correctly on second run — observable only after two live runs
- [ ] If a deliberate violation is introduced into `demo/`, a fix PR is opened — requires live run with seeded violation
- [ ] If a new-paradigm scenario is staged in `demo/`, an upstream PR is opened (when applicable) — requires live run + `SWIFT_BEST_PRACTICES_PAT` secret

**Phase 5 (self-improvement):** — static checks done; live checks deferred
- [x] Workflow YAML parses cleanly (`self-improve.yml`) and references existing `agent-instructions-self-improve.md` + `plugin/skills/`
- [ ] At least one quality improvement PR on first run — observable only after a live `workflow_dispatch`
- [ ] No spurious/low-value PRs — observable only after multiple live runs

**Unblocking the deferred checks:** push this branch to `gestrich/swift-app-architecture` on GitHub, configure the `ANTHROPIC_API_KEY` and `SWIFT_BEST_PRACTICES_PAT` repo secrets, then trigger `Self Conformance` and `Self Improve` via the Actions UI. Each PR opened, plus the contents of the `claude/conformance-state` and `claude/self-improve-state` branches, completes the remaining checkboxes.
