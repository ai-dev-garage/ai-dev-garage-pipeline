---
name: review-skill
description: Entry only — resolves the target skill directory and runs the skill-standard skill in review mode to audit an existing pipeline skill.
---

User input (pass through to the skill):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, output: "Reviews an existing pipeline skill using the **skill-standard** skill. Provide the skill name or directory path. Optionally add `scope=plugin` (default) or `scope=project` to indicate where to look." Stop.

2. Parse `scope` from arguments (default: `plugin`):
   - `plugin` → `TARGET_ROOT` = `${CLAUDE_PLUGIN_ROOT}`
   - `project` → `TARGET_ROOT` = `<PROJECT_ROOT>/.ai-dev-garage/` (resolve `PROJECT_ROOT` from `project=<path>` or workspace)

3. Resolve `TARGET_SKILL_DIR` from arguments: use the path directly if absolute, or resolve as `TARGET_ROOT/skills/<name>/`.

4. Resolve the **skill-standard** skill relative to `${CLAUDE_PLUGIN_ROOT}`; load `skills/skill-standard/SKILL.md`.

5. Apply the skill in **review** mode with: `TARGET_SKILL_DIR`, `TARGET_ROOT`, `ASSET_SCOPE`. Output issues and proposed fixes. Do not apply changes until the user confirms.
