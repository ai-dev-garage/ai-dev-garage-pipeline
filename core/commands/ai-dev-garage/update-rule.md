---
name: update-rule
description: Entry only — resolves the target rule file and runs the rule-standard skill in update mode to modify an existing pipeline rule.
---

User input (pass through to the skill):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, output: "Updates an existing pipeline rule using the **rule-standard** skill. Provide the rule name or file path and a description of the desired changes. Optionally add `scope=global` (default), `scope=extension:<name>`, or `scope=project` to indicate which bundle to look in." Stop.

2. Parse `scope` from arguments (default: `global`):
   - `global` → `GARAGE_BUNDLE_ROOT` = user-global garage bundle root
   - `extension:<name>` → `GARAGE_BUNDLE_ROOT` = that extension's bundle root
   - `project` → `GARAGE_BUNDLE_ROOT` = `<PROJECT_ROOT>/.ai-dev-garage/` (resolve `PROJECT_ROOT` from `project=<path>` or workspace)

3. Resolve `TARGET_RULE_FILE` from arguments: use the path directly if absolute, or resolve as `GARAGE_BUNDLE_ROOT/rules/<name>.md`.

4. Resolve the **rule-standard** skill by walking `GARAGE_SEARCH_ROOTS` in order; load the first match at `skills/rule-standard/SKILL.md`.

5. Apply the skill in **update** mode with: user input as change description, `TARGET_RULE_FILE`, `GARAGE_BUNDLE_ROOT`, `ASSET_SCOPE`. Output the proposed updated content. Do not write files until the user confirms.
