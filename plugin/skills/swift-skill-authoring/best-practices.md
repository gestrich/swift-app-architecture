# Skill Authoring Best Practices

Detailed guidelines for writing effective Claude skills.

## Writing Effective Descriptions

The `description` field is critical—Claude uses it to decide when to activate your skill from potentially 100+ available skills.

### Rules

1. **Write in third person** (injected into system prompt)
   - Good: "Processes Excel files and generates reports"
   - Bad: "I can help you process Excel files"
   - Bad: "You can use this to process Excel files"

2. **Include both WHAT and WHEN**
   - Good: "Extracts text from PDFs, fills forms, merges documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction."
   - Bad: "Helps with documents"

3. **Include trigger terms** users would mention
   - If your skill handles "feature flags", include that phrase
   - Think about synonyms and related terms

### Description Template

```
[Action verb] [what it does]. Use when [specific situations] or when the user mentions [trigger terms].
```

## Progressive Disclosure

SKILL.md shares Claude's context window with conversation history, other skills, and the user's request. Use progressive disclosure to keep context focused.

### Pattern: Navigation Table

```markdown
## Which Document Do I Need?

| Situation | Document |
|-----------|----------|
| Creating new X | [creating.md](creating.md) |
| Understanding existing X | [reference.md](reference.md) |
| Migrating from old to new | [migration.md](migration.md) |
```

### Pattern: Conditional References

```markdown
## Basic Usage

[Essential content here]

**For advanced features**: See [advanced.md](advanced.md)
**For troubleshooting**: See [troubleshooting.md](troubleshooting.md)
```

### Keep References One Level Deep

Claude may partially read deeply nested files. All reference files should link directly from SKILL.md.

Bad:
```
SKILL.md → advanced.md → details.md → actual-info.md
```

Good:
```
SKILL.md → advanced.md
SKILL.md → details.md
SKILL.md → reference.md
```

## Naming Conventions

### Skill Names

Use **gerund form** (verb + -ing) for clarity:

| Good | Acceptable | Avoid |
|------|------------|-------|
| `processing-pdfs` | `pdf-processing` | `pdf` |
| `analyzing-code` | `code-analysis` | `helper` |
| `managing-packages` | `package-manager` | `utils` |

Requirements:
- Lowercase letters, numbers, hyphens only
- Maximum 64 characters
- No reserved words: "anthropic", "claude"

### File Names

- Use lowercase with hyphens: `best-practices.md`
- Be descriptive: `form-validation-rules.md` not `doc2.md`

## Content Guidelines

### Be Concise

Claude is already very smart. Only add context it doesn't have.

Bad (150 tokens):
```markdown
PDF (Portable Document Format) files are a common file format that contains
text, images, and other content. To extract text from a PDF, you'll need to
use a library. There are many libraries available...
```

Good (50 tokens):
```markdown
## Extract PDF text

Use pdfplumber for text extraction:
\`\`\`python
import pdfplumber
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
\`\`\`
```

### Avoid Time-Sensitive Information

Bad:
```markdown
If you're doing this before August 2025, use the old API.
```

Good:
```markdown
## Current method
Use the v2 API endpoint.

## Legacy patterns
<details>
<summary>v1 API (deprecated)</summary>
The v1 API used: api.example.com/v1/messages
</details>
```

### Use Consistent Terminology

Pick one term and use it throughout:

| Good (consistent) | Bad (inconsistent) |
|-------------------|-------------------|
| Always "API endpoint" | Mix "API endpoint", "URL", "route" |
| Always "field" | Mix "field", "box", "element" |

## Degrees of Freedom

Match specificity to the task's fragility:

### High Freedom (text instructions)
Use when multiple approaches are valid:
```markdown
## Code review process
1. Analyze the code structure
2. Check for potential bugs
3. Suggest improvements
```

### Low Freedom (specific scripts)
Use when consistency is critical:
```markdown
## Database migration

Run exactly this script:
\`\`\`bash
python scripts/migrate.py --verify --backup
\`\`\`

Do not modify the command.
```

## Structuring Longer Files

For reference files over 100 lines, add a table of contents:

```markdown
# API Reference

## Contents
- Authentication
- Core methods
- Error handling
- Examples

## Authentication
...
```

## Utility Scripts

Pre-made scripts are more reliable than generated code:

```markdown
## Utility scripts

**analyze_form.py**: Extract form fields
\`\`\`bash
python scripts/analyze_form.py input.pdf > fields.json
\`\`\`

**validate.py**: Check for errors
\`\`\`bash
python scripts/validate.py fields.json
\`\`\`
```

Make clear whether Claude should execute vs read the script:
- "Run `script.py` to extract fields" (execute)
- "See `script.py` for the algorithm" (read as reference)

## Testing Skills

1. **Verify activation**: Does the skill trigger when expected?
2. **Test with real tasks**: Use actual workflows, not contrived tests
3. **Check file navigation**: Can Claude find and read reference files?
4. **Review token usage**: Is SKILL.md under 500 lines?

## Common Anti-Patterns

| Anti-Pattern | Fix |
|--------------|-----|
| Windows paths (`scripts\helper.py`) | Use forward slashes (`scripts/helper.py`) |
| Too many options ("use A or B or C or D") | Provide a default with escape hatch |
| Vague descriptions ("helps with documents") | Specific triggers ("extracts text from PDFs") |
| Deep nesting (file → file → file) | One level from SKILL.md |
| Magic numbers in scripts | Document why values are chosen |
