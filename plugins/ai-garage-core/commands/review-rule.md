---
name: review-rule
description: Entry only — resolves the target rule file and runs the rule-standard skill in review mode to audit an existing pipeline rule.
---

User input (pass through to the skill):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, output: "Reviews an existing pipeline rule using the **rule-standard** skill. Provide the rule name or file path. Optionally add `scope=plugin` (default) or `scope=project` to indicate where to look." Stop.

2. Parse `scope` from arguments (default: `plugin`):
   - `plugin` → `TARGET_ROOT` = `${CLAUDE_PLUGIN_ROOT}`
   - `project` → `TARGET_ROOT` = `<PROJECT_ROOT>/.ai-dev-garage/` (resolve `PROJECT_ROOT` from `project=<path>` or workspace)

3. Resolve `TARGET_RULE_FILE` from arguments: use the path directly if absolute, or resolve as `TARGET_ROOT/rules/<name>.md`.

4. Resolve the **rule-standard** skill relative to `${CLAUDE_PLUGIN_ROOT}`; load `skills/rule-standard/SKILL.md`.

5. Apply the skill in **review** mode with: `TARGET_RULE_FILE`, `TARGET_ROOT`, `ASSET_SCOPE`. Output issues and proposed fixes. Do not apply changes until the user confirms.
