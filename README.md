# Swift App Architecture

A plugin for Claude Code and OpenAI Codex providing architectural guidance for Swift application development.

## Installation

### Claude Code

1. Add the marketplace:
   ```bash
   claude plugin marketplace add https://github.com/gestrich/swift-app-architecture
   ```

2. Install the plugin:
   ```bash
   claude plugin install swift-app-architecture@gestrich-swift-app-architecture --scope user
   ```
   > Use `--scope user` to install system-wide for all projects.

3. Restart Claude Code if necessary.

**Uninstall:**
```bash
claude plugin uninstall swift-app-architecture@gestrich-swift-app-architecture --scope user
```

### OpenAI Codex

1. Add the marketplace:
   ```bash
   codex plugin marketplace add gestrich/swift-app-architecture
   ```

2. Open a Codex session and install via the `/plugins` menu — select **swift-app-architecture** → **Install plugin**.
   > There is no `codex plugin install` CLI command yet; installation must be done through the interactive TUI.

3. After installing, the plugin can be toggled without the TUI by editing `~/.codex/config.toml`:
   ```toml
   [plugins."swift-app-architecture"]
   enabled = true   # set to false to disable without uninstalling
   ```

**Uninstall:** Remove the `[plugins."swift-app-architecture"]` entry from `~/.codex/config.toml` and run:
```bash
codex plugin marketplace remove gestrich-swift-app-architecture
```

### Local Testing (Claude Code)

```bash
claude --plugin-dir ~/path/to/swift-app-architecture
```

## Skills

Skills are invoked via slash commands in Claude Code (e.g., `/swift-architecture`).

| Skill | Command | Description |
|-------|---------|-------------|
| Architecture | `/swift-architecture` | 4-layer Swift app architecture (Apps, Features, Services, SDKs) — layer responsibilities, dependency rules, placement guidance, feature creation, configuration, code style, and reference examples |
| SwiftUI | `/swift-swiftui` | SwiftUI Model-View patterns — enum-based state, model composition, dependency injection, view identity, and observable model conventions |
| Skill Authoring | `/swift-skill-authoring` | Guides creation and editing of Claude skills — structure, best practices, and examples |

## Troubleshooting

### Slash commands not showing in terminal

The slash commands (e.g., `/swift-architecture`) may not appear in the terminal autocomplete but will show up in the Claude Code VSCode extension. Use the VSCode extension for the best experience with slash command discovery.

### Updating the plugin

To get the latest version, update the marketplace and then uninstall and reinstall the plugin:

```
claude plugin marketplace update gestrich-swift-app-architecture
claude plugin uninstall swift-app-architecture@gestrich-swift-app-architecture
claude plugin install swift-app-architecture@gestrich-swift-app-architecture --scope user
```

Asking Claude to update the plugin via the CLI does not appear to work — it will report success but won't actually pull the latest version. The most reliable way to update is to uninstall and reinstall as shown above, or through the Claude Code UI.

### Slash commands not accessible after installation

If slash commands aren't working after installing the plugin, try uninstalling and reinstalling with explicit scope:

```
/plugin uninstall swift-app-architecture@gestrich-swift-app-architecture
/plugin install swift-app-architecture@gestrich-swift-app-architecture --scope user
```

### Plugin not available after adding marketplace

Sometimes the plugin won't appear as an installation option even after adding the marketplace. You can work around this by manually enabling the plugin in your Claude Code configuration.

Create or edit `~/.claude/config.json` and add:

```json
{
  "enabledPlugins": {
    "swift-app-architecture@gestrich-swift-app-architecture": true
  }
}
```

Then restart Claude Code.

## License

MIT License - see [LICENSE](plugin/LICENSE) for details.
