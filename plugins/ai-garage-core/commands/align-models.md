---
name: align-models
description: Entry only — reads model effort mappings from config and patches the model field in installed agent frontmatter files.
---

User input (pass through to the skill):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, print: "Reads model effort mappings (low/medium/high) from project or user config and updates the `model` field in installed agent files. Run after install/update or when model preferences change. Usage: `/ai-garage-core:align-models [dry-run]`"; stop.
2. Resolve `PROJECT_ROOT` from the current workspace.
3. Resolve path to `skills/agent-model-alignment/SKILL.md` relative to `${CLAUDE_PLUGIN_ROOT}`. Load that skill.
4. Pass `${CLAUDE_PLUGIN_ROOT}` and any `dry-run` flag from `$ARGUMENTS` to the skill. Run the skill workflow.
5. Report the summary of changes to the user.
