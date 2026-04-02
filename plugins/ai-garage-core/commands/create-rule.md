---
name: create-rule
description: Entry only — resolves the target location and runs the rule-standard skill in create mode to draft a new pipeline rule.
---

User input (pass through to the skill):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, output: "Creates a new pipeline rule using the **rule-standard** skill. Provide a name or description for the rule. Optionally add `scope=plugin` (default) or `scope=project` to control where the rule will be written." Stop.

2. Parse `scope` from arguments (default: `plugin`):
   - `plugin` → `TARGET_ROOT` = `${CLAUDE_PLUGIN_ROOT}`
   - `project` → `TARGET_ROOT` = `<PROJECT_ROOT>/.ai-dev-garage/` (resolve `PROJECT_ROOT` from `project=<path>` or workspace)

3. Resolve `TARGET_RULE_FILE` = `TARGET_ROOT/rules/<name>.md` (name from user input or TBD in skill).

4. Resolve the **rule-standard** skill relative to `${CLAUDE_PLUGIN_ROOT}`; load `skills/rule-standard/SKILL.md`.

5. Apply the skill in **create** mode with: user input as description, `TARGET_RULE_FILE`, `TARGET_ROOT`, `ASSET_SCOPE`. Output the proposed rule content. Do not write files until the user confirms.
