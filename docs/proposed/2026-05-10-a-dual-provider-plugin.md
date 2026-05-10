# Dual-Provider Plugin: Claude Code + OpenAI Codex

## Relevant Skills

Neither `swift-architecture` nor `swift-swiftui` applies here — this plan is about repository packaging, not Swift code. No skills are required.

---

## Background

This repo currently ships a Claude Code plugin at `plugin/` with two skills (`swift-architecture`, `swift-swiftui`). OpenAI Codex recently added a plugin system that uses the same **Agent Skills** specification (`agentskills.io`) as Claude Code. The `SKILL.md` files are already in the correct format and require no changes.

The goal is to add vendor-specific manifests (`.claude-plugin/plugin.json` and `.codex-plugin/plugin.json`) at the repo root so the repo can be installed as a plugin from either tool. The skills themselves are shared and unchanged.

### Key insight from research

`SKILL.md` content is fully portable across both tools. The only additions needed are:
1. Two small JSON manifests (one per tool) pointing at the existing skill paths.
2. An `AGENTS.md` file for Codex (equivalent to `CLAUDE.md`).
3. Plugin discovery paths differ: Claude reads `.claude-plugin/`, Codex reads `.codex-plugin/`.

**Important difference in install model:**
- Claude Code: `claude plugin install` directly installs from a path or GitHub shorthand.
- Codex: no direct `codex plugin install <path>` command — plugins are discovered via a **marketplace JSON file** (`marketplace.json`) that points at the plugin. Local testing requires creating a marketplace file.

---

## Spec Reference

### Claude Code Plugin Spec

**Sources:**
- https://code.claude.com/docs/en/plugins
- https://code.claude.com/docs/en/plugins-reference
- https://code.claude.com/docs/en/plugin-marketplaces

**Manifest location:** `.claude-plugin/plugin.json` at the repo root. The manifest is **optional** — Claude auto-discovers skills from a `skills/` directory at the plugin root. The manifest is needed here because our skills live at `plugin/skills/`, not the default `skills/` path.

**`plugin.json` — field reference:**

| Field | Required | Type | Notes |
|---|---|---|---|
| `name` | **Yes** | string | Kebab-case; becomes the skill namespace prefix (e.g. `swift-app-architecture:swift-architecture`) |
| `version` | No | string | Semver e.g. `"1.0.0"`; defaults to git commit SHA if omitted |
| `description` | No | string | Shown in `claude plugin list` |
| `author` | No | object | `{ "name", "email", "url" }` — all sub-fields optional |
| `homepage` | No | string | Documentation URL |
| `repository` | No | string | Source code URL |
| `license` | No | string | SPDX identifier e.g. `"MIT"` |
| `keywords` | No | array of strings | Discovery tags |
| `skills` | No | string or array | Path(s) to skill container directories. **Additive** — added on top of the default `skills/` scan. Each path is a directory whose subdirectories are individual skills (each containing `SKILL.md`). |
| `commands` | No | string or array | Path(s) to flat `.md` skill files. **Replaces** default `commands/` directory. |
| `agents` | No | string or array | Path(s) to agent `.md` files. **Replaces** default `agents/` directory. |
| `mcpServers` | No | string, array, or object | MCP config paths or inline config |
| `hooks` | No | string, array, or object | Hook config paths or inline config |
| `dependencies` | No | array | Other plugins required. String `"plugin-name"` or object `{ "name", "version" }` |

**Concrete `plugin.json` for this repo:**
```json
{
  "name": "swift-app-architecture",
  "version": "1.0.0",
  "description": "Swift app architecture patterns: 4-layer architecture (Apps, Features, Services, SDKs) and SwiftUI Model-View conventions.",
  "author": { "name": "Bill Gestrich" },
  "repository": "https://github.com/gestrich/swift-app-architecture",
  "license": "MIT",
  "skills": "./plugin/skills/"
}
```

> `"skills": "./plugin/skills/"` tells Claude to scan `plugin/skills/` for subdirectories. Each subdirectory (`swift-architecture/`, `swift-swiftui/`) becomes a skill. This is **in addition to** the default `skills/` scan (which will find nothing since that directory doesn't exist here).

**CLI commands (verified against live docs):**

```bash
# Install from GitHub (public repo, user-scope by default)
claude plugin install gestrich/swift-app-architecture

# Install from a local directory
claude plugin install /path/to/swift-app-architecture

# Install at project scope (adds to project .claude/settings.json)
claude plugin install gestrich/swift-app-architecture --scope project

# List installed plugins
claude plugin list

# Uninstall (aliases: remove, rm)
claude plugin uninstall swift-app-architecture

# Uninstall at project scope
claude plugin uninstall swift-app-architecture --scope project
```

---

### OpenAI Codex Plugin Spec

**Source:** https://developers.openai.com/codex/plugins/build

**Manifest location:** `.codex-plugin/plugin.json` at the repo root. Only `plugin.json` belongs in `.codex-plugin/` — all other content (skills, `.mcp.json`, assets) lives at the plugin root.

**`plugin.json` — field reference:**

| Field | Required | Type | Notes |
|---|---|---|---|
| `name` | **Yes** | string | Kebab-case |
| `version` | **Yes** | string | Semver e.g. `"0.1.0"` |
| `description` | **Yes** | string | |
| `author` | No | object | `{ name, email, url }` |
| `homepage` | No | string | URL |
| `repository` | No | string | URL |
| `license` | No | string | e.g. `"MIT"` |
| `keywords` | No | array of strings | |
| `skills` | No | string | Path to skills container directory e.g. `"./skills/"`. Each subdirectory within it is one skill. |
| `mcpServers` | No | string | Path to `.mcp.json` |
| `apps` | No | string | Path to `.app.json` |
| `hooks` | No | string | Path to hooks config e.g. `"./hooks/hooks.json"` |
| `interface` | No | object | Display metadata: `displayName`, `shortDescription`, `brandColor`, `logo`, `defaultPrompt`, etc. |

**Concrete `plugin.json` for this repo:**
```json
{
  "name": "swift-app-architecture",
  "version": "1.0.0",
  "description": "Swift app architecture patterns: 4-layer architecture (Apps, Features, Services, SDKs) and SwiftUI Model-View conventions.",
  "author": { "name": "Bill Gestrich" },
  "repository": "https://github.com/gestrich/swift-app-architecture",
  "license": "MIT",
  "skills": "./plugin/skills/"
}
```

**Install model — Codex uses marketplaces, not direct install:**

Codex does **not** have a `codex plugin install <path>` command. Plugins are discovered through marketplace JSON files. There are three install paths:

**Option A — Project-scoped (for use in a specific repo):**
Create `.agents/plugins/marketplace.json` in the consuming project:
```json
{
  "name": "local",
  "owner": { "name": "Bill Gestrich" },
  "plugins": [
    {
      "name": "swift-app-architecture",
      "source": "./path/to/swift-app-architecture"
    }
  ]
}
```

**Option B — Personal/global (available across all projects):**
Create or append to `~/.agents/plugins/marketplace.json`:
```json
{
  "name": "gestrich",
  "owner": { "name": "Bill Gestrich" },
  "plugins": [
    {
      "name": "swift-app-architecture",
      "source": { "source": "github", "repo": "gestrich/swift-app-architecture" }
    }
  ]
}
```

**Option C — Publish as a Codex marketplace (GitHub repo):**
A GitHub repo can serve as a marketplace via its `.codex-plugin/marketplace.json`. Users then install the marketplace:
```bash
codex plugin marketplace add gestrich/swift-app-architecture
codex plugin marketplace upgrade   # pull latest versions
codex plugin marketplace remove gestrich  # uninstall the marketplace
```

> Note: Official public plugin publishing in the Codex Plugin Directory is "coming soon" per the docs. The marketplace approach is the current mechanism.

---

### Agent Skills Spec (shared between both)

**Source:** https://agentskills.io/specification

Every `SKILL.md` must begin with YAML frontmatter:

```yaml
---
name: skill-name          # required; must match directory name; lowercase-hyphen; max 64 chars
description: "..."        # required; max 1024 chars; describe what it does AND when to trigger
license: MIT              # optional
compatibility: "..."      # optional; environment requirements; max 500 chars
metadata:                 # optional; arbitrary key-value map
  author: Bill Gestrich
  version: 1.0.0
allowed-tools: "Bash Read"  # optional; space-separated pre-approved tools
---

[Markdown instructions body]
```

Both skills in this repo (`swift-architecture`, `swift-swiftui`) already comply with this spec — no changes needed.

---

## Phases

## - [x] Phase 1: Verify Specs Against Live Docs

**COMPLETED** — verified against:
- https://code.claude.com/docs/en/plugins (+ plugins-reference, plugin-marketplaces)
- https://developers.openai.com/codex/plugins/build

All schemas and commands in the Spec Reference section above are from live docs, not community guesses. Key corrections from original plan:
- Claude `skills` field is a **string path** to a directory, not an array of objects
- Claude install command is `claude plugin install` (not `add`); remove is `claude plugin uninstall`
- Codex has **no direct install-by-path command** — requires a marketplace file
- Codex `skills` field name is `skills` (not `skillsPath`)

---

## - [x] Phase 2: Add Claude Code Plugin Manifest

**COMPLETED** — Already handled. The repo has `.claude-plugin/marketplace.json` at the repo root declaring a marketplace with source `./plugin`. Claude auto-discovers skills from `plugin/skills/` without needing a `plugin.json` inside `plugin/`. No files needed.

---

## - [x] Phase 3: Add Codex Plugin Manifest

**COMPLETED** — Created `plugin/.codex-plugin/plugin.json` (plugin root is `./plugin`, not the repo root). Codex also honors `.claude-plugin/marketplace.json` for marketplace discovery, so the marketplace layer was already covered. The plugin manifest points skills at `"./skills/"` which resolves to `plugin/skills/`.

---

## - [x] Phase 4: Add AGENTS.md

**COMPLETED** — Created `AGENTS.md` at repo root mirroring `CLAUDE.md`.

---

## - [x] Phase 5: Update README / Documentation

**COMPLETED** — Updated `README.md` with install/uninstall instructions for both Claude Code and Codex. Codex section explains the marketplace file approach since there is no direct `codex plugin install` command.

---

## - [ ] Phase 6: Validation

Manual verification (automated testing not applicable for plugin packaging):

**Claude Code:**
- [ ] `claude plugin install .` installs with no errors
- [ ] `claude plugin list` shows `swift-app-architecture` with both skills
- [ ] Skills are invocable inside a Claude Code session
- [ ] `claude plugin uninstall swift-app-architecture` removes cleanly

**Codex (if Codex CLI is installed):**
- [ ] Plugin manifest validates without errors
- [ ] Skills appear when loaded via a local marketplace file
- [ ] Skills are invocable inside a Codex session

**Final repo structure:**
```
swift-app-architecture/
├── .claude-plugin/
│   └── plugin.json
├── .codex-plugin/
│   └── plugin.json
├── plugin/
│   └── skills/
│       ├── swift-architecture/
│       │   └── SKILL.md
│       └── swift-swiftui/
│           └── SKILL.md
├── AGENTS.md
├── CLAUDE.md
└── README.md
```
