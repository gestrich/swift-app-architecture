---
name: swift-skill-authoring
description: Guides creation and editing of Claude skills. Use any time skills are being created, edited, or improved. Also use when understanding skill structure or learning best practices for skill authoring.
user-invocable: true
---

# Claude Skill Authoring

This skill provides guidance for creating and editing Claude skills.

## Which Document Do I Need?

| Situation | Document |
|-----------|----------|
| Creating a new skill | Start here, then [best-practices.md](best-practices.md) |
| Improving an existing skill | [best-practices.md](best-practices.md) |
| Looking for patterns to follow | [examples.md](examples.md) |

## Quick Start Template

Create a new skill at `.claude/skills/<skill-name>/SKILL.md`:

```yaml
---
name: my-skill-name
description: Does X and Y. Use when working with Z or when the user mentions A, B, or C.
user-invocable: true
---

# Skill Title

Brief overview of what this skill provides.

## Key Information

Essential content that Claude needs for most uses of this skill.

## Additional Resources

For detailed reference, see [reference.md](reference.md)
```

## Required Frontmatter Fields

| Field | Requirements |
|-------|--------------|
| `name` | Lowercase letters, numbers, hyphens only. Max 64 chars. Use gerund form (e.g., `analyzing-code`). |
| `description` | Max 1024 chars. Must explain WHAT the skill does AND WHEN to use it. Write in third person. |

## Optional Frontmatter Fields

| Field | Purpose |
|-------|---------|
| `user-invocable` | `true` (default) shows in slash menu, `false` hides it |
| `allowed-tools` | Restrict which tools Claude can use (e.g., `Read, Grep, Glob`) |
| `model` | Override the conversation model |
| `context: fork` | Run in isolated sub-agent context |

## File Organization

**Single-file skill**: Use when content fits under 500 lines
```
.claude/skills/my-skill/
└── SKILL.md
```

**Multi-file skill**: Use progressive disclosure for larger content
```
.claude/skills/my-skill/
├── SKILL.md              # Overview and navigation (under 500 lines)
├── reference.md          # Detailed API/reference content
├── examples.md           # Usage examples
└── scripts/
    └── helper.py         # Utility scripts (executed, not loaded)
```

## Checklist for New Skills

- [ ] Name uses lowercase, hyphens, gerund form preferred
- [ ] Description explains what AND when (includes trigger terms)
- [ ] Description written in third person
- [ ] SKILL.md under 500 lines
- [ ] Detailed content in separate files if needed
- [ ] Navigation table if multi-file
- [ ] Related skills/commands listed
- [ ] Tested with `/skill-name` invocation

## Key Principles

1. **Be concise** - Claude is smart; only add context it doesn't already have
2. **Progressive disclosure** - Essential info in SKILL.md, details in linked files
3. **One level deep** - Reference files should link from SKILL.md, not from other reference files
4. **Specific descriptions** - Include trigger terms users would mention

## Related Documentation

- [best-practices.md](best-practices.md) - Detailed authoring guidelines
- [examples.md](examples.md) - Annotated examples of good skills
