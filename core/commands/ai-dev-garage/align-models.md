---
name: align-models
description: Entry only — reads model effort mappings from config and patches the model field in installed agent frontmatter files.
---

User input (pass through to the skill):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, print: "Reads model effort mappings (low/medium/high) from project or global config and updates the `model` field in installed agent files. Run after `garage install/update` or when model preferences change. Usage: `/ai-dev-garage:align-models [dry-run]`"; stop.
2. Resolve `PROJECT_ROOT` from the current workspace. Set `GARAGE_SEARCH_ROOTS` per install config (project bundle, then global bundle).
3. For each bundle root in `GARAGE_SEARCH_ROOTS`, resolve path to `skills/agent-model-alignment/SKILL.md` by walking roots in order. Load that skill.
4. Pass `GARAGE_BUNDLE_ROOT` (the global install at `~/.ai-dev-garage/`) and any `dry-run` flag from `$ARGUMENTS` to the skill. Run the skill workflow.
5. Report the summary of changes to the user.
