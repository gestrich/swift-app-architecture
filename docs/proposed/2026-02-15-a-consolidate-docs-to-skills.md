# Consolidate docs/architecture into plugin/skills

## Relevant Skills

| Skill | Description |
|-------|-------------|
| `swift-architecture` | 4-layer Swift app architecture — layers, principles, examples, configuration, code style, feature creation |
| `swift-swiftui` | SwiftUI Model-View patterns — state, composition, dependency injection, alerts, view identity |

## Background

The repo has two sets of documentation that overlap significantly:
- `docs/architecture/` — 12 markdown files (2962 total lines)
- `plugin/skills/` — split across `swift-architecture/` (7 files, 1565 lines) and `swift-swiftui/` (9 files, 951 lines)

Currently `CLAUDE.md` says docs/architecture is the "source of truth" and skills are derived from it. We want to **reverse** this: make the skills the single source of truth and remove docs/architecture. This eliminates redundancy and ensures the Claude Code plugin always has the latest content.

Each phase removes one doc from `docs/architecture/` by merging any unique content into the corresponding skill file(s), then deleting the doc. Each phase is a separate PR.

### Effective Diff for PR Summaries

Since each PR deletes a doc and modifies a skill, the standard GitHub diff doesn't clearly show what content was lost or changed. To make reviews easy, each PR description must include an **effective diff** — a unified diff comparing the doc (old) to the skill (new):

```bash
# Run BEFORE deleting the doc, from repo root:
diff -u docs/architecture/<DocFile>.md plugin/skills/<skill-dir>/<skill-file>.md
```

Paste the full output in the PR description inside a `<details>` block:

```markdown
<details>
<summary>Effective diff (doc → skill)</summary>

\`\`\`diff
<paste diff output here>
\`\`\`
</details>
```

This lets the reviewer see exactly what was dropped, reworded, or added in the skill version relative to the original doc.

### Mapping

| docs/architecture/ | Skill counterpart | Notes |
|---|---|---|
| Principles.md (136 lines) | swift-architecture/principles.md (135 lines) | Nearly identical |
| code-style.md (119 lines) | swift-architecture/code-style.md (145 lines) | Skill is larger |
| Examples.md (358 lines) | swift-architecture/examples.md (353 lines) | Nearly identical |
| Configuration.md (215 lines) | swift-architecture/configuration.md (197 lines) | Doc slightly larger |
| Layers.md (480 lines) | swift-architecture/layers.md (198 lines) | Doc much larger — significant merge needed |
| FeatureStructure.md (242 lines) | swift-architecture/creating-features.md (338 lines) | Skill is larger |
| Dependencies.md (227 lines) | No counterpart | Content needs a new home (layers.md or new file) |
| ARCHITECTURE.md (206 lines) | swift-architecture/SKILL.md (199 lines) | Overview/index — merge into SKILL.md |
| QuickReference.md (231 lines) | No counterpart | Merge into SKILL.md or relevant files |
| alerts.md (113 lines) | swift-swiftui/alerts.md (73 lines) | Doc has more content |
| swift-ui.md (572 lines) | swift-swiftui/ (multiple files, 951 lines) | Skills already more detailed |
| documentation.md (63 lines) | No counterpart | Small — merge into SKILL.md or code-style.md |

## Phases

Start with the easiest (nearly identical pairs) and work toward the harder merges.

## - [ ] Phase 1: Remove Principles.md

**Skills to read**: `swift-architecture`

- Diff `docs/architecture/Principles.md` against `plugin/skills/swift-architecture/principles.md`
- Merge any unique content from the doc into the skill
- Delete `docs/architecture/Principles.md`
- Create PR with title: "Consolidate Principles.md into skill"

## - [ ] Phase 2: Remove code-style.md

**Skills to read**: `swift-architecture`

- Diff `docs/architecture/code-style.md` against `plugin/skills/swift-architecture/code-style.md`
- The skill is already larger (145 vs 119 lines), so likely no merge needed — verify no unique content in doc
- Delete `docs/architecture/code-style.md`
- Create PR

## - [ ] Phase 3: Remove Examples.md

**Skills to read**: `swift-architecture`

- Diff `docs/architecture/Examples.md` against `plugin/skills/swift-architecture/examples.md`
- Nearly identical line counts — verify and merge any differences
- Delete `docs/architecture/Examples.md`
- Create PR

## - [ ] Phase 4: Remove Configuration.md

**Skills to read**: `swift-architecture`

- Diff `docs/architecture/Configuration.md` against `plugin/skills/swift-architecture/configuration.md`
- Doc is slightly larger — merge unique content into skill
- Delete `docs/architecture/Configuration.md`
- Create PR

## - [ ] Phase 5: Remove FeatureStructure.md

**Skills to read**: `swift-architecture`

- Diff `docs/architecture/FeatureStructure.md` against `plugin/skills/swift-architecture/creating-features.md`
- Skill is already larger — verify no unique content lost
- Delete `docs/architecture/FeatureStructure.md`
- Create PR

## - [ ] Phase 6: Remove alerts.md

**Skills to read**: `swift-swiftui`

- Diff `docs/architecture/alerts.md` against `plugin/skills/swift-swiftui/alerts.md`
- Doc has more content (113 vs 73 lines) — merge unique parts into skill
- Delete `docs/architecture/alerts.md`
- Create PR

## - [ ] Phase 7: Remove swift-ui.md

**Skills to read**: `swift-swiftui`

- Compare `docs/architecture/swift-ui.md` (572 lines) against all files in `plugin/skills/swift-swiftui/`
- The skill directory already has more total content (951 lines) split across multiple files
- Identify any sections in the doc not covered by existing skill files
- Merge missing content into appropriate skill files (or create new ones if needed)
- Delete `docs/architecture/swift-ui.md`
- Create PR

## - [ ] Phase 8: Remove Layers.md

**Skills to read**: `swift-architecture`

- This is the biggest merge: doc is 480 lines vs skill's 198 lines
- Carefully diff and merge all unique content (diagrams, explanations, examples)
- Delete `docs/architecture/Layers.md`
- Create PR

## - [ ] Phase 9: Remove Dependencies.md

**Skills to read**: `swift-architecture`

- No direct skill counterpart exists
- Analyze content — likely fits in `layers.md` (dependency rules section) or warrants a new skill file like `dependencies.md`
- Merge content into appropriate location
- Delete `docs/architecture/Dependencies.md`
- Create PR

## - [ ] Phase 10: Remove remaining docs (ARCHITECTURE.md, QuickReference.md, documentation.md)

**Skills to read**: `swift-architecture`

- `ARCHITECTURE.md` (206 lines) — overview content, merge into `SKILL.md`
- `QuickReference.md` (231 lines) — merge into `SKILL.md` or distribute across relevant skill files
- `documentation.md` (63 lines) — small, merge into `code-style.md` or `SKILL.md`
- Delete all three
- Update `CLAUDE.md` to reflect that `plugin/skills/` is now the single source of truth
- Remove `docs/architecture/` directory
- Create final PR

## - [ ] Phase 11: Validation

- Verify `docs/architecture/` directory is fully removed
- Verify no broken cross-references in skill files
- Verify `CLAUDE.md` is updated
- Verify plugin still works: all skill files readable, no missing references
- Review total line counts in skills to confirm no content was lost
