# Swift App Architecture

A Claude Code plugin providing architectural guidance for Swift application development.

## Installation

### Via Marketplace (Recommended)

1. Add the marketplace to Claude Code:
   ```
   /plugin marketplace add gestrich/swift-app-architecture
   ```

2. Install the plugin:
   ```
   claude plugin install swift-app-architecture@gestrich-swift-app-architecture --scope project
   ```
   > **Note:** Use `--scope user` instead of `--scope project` to install system-wide for all projects.

3. Restart Claude Code if necessary

### Local Testing

For local development or testing:
```bash
claude --plugin-dir ~/path/to/swift-app-architecture
```

## Skills

Skills are invoked via slash commands in Claude Code (e.g., `/architecture`).

| Skill | Command | Description |
|-------|---------|-------------|
| Architecture | `/architecture` | 4-layer Swift app architecture (Apps, Features, Services, SDKs) — layer responsibilities, dependency rules, placement guidance, feature creation, configuration, code style, and reference examples |
| SwiftUI | `/swiftui` | SwiftUI Model-View patterns — enum-based state, model composition, dependency injection, view identity, and observable model conventions |
| Skill Authoring | `/skill-authoring` | Guides creation and editing of Claude skills — structure, best practices, and examples |

## Troubleshooting

### Slash commands not showing in terminal

The slash commands (e.g., `/architecture`) may not appear in the terminal autocomplete but will show up in the Claude Code VSCode extension. Use the VSCode extension for the best experience with slash command discovery.

### Updating the plugin

If you need to update the plugin to a newer version, you may need to remove and re-add it:

```
/plugin uninstall swift-app-architecture@gestrich-swift-app-architecture
/plugin install swift-app-architecture@gestrich-swift-app-architecture
```

### Slash commands not accessible after installation

If slash commands aren't working after installing the plugin, try uninstalling and reinstalling with explicit scope:

```
/plugin uninstall swift-app-architecture@gestrich-swift-app-architecture
/plugin install swift-app-architecture@gestrich-swift-app-architecture --scope project
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
