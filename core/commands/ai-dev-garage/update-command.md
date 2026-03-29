---
name: update-command
description: Entry only — resolves the target command file and runs the command-standard skill in update mode to modify an existing pipeline command.
---

User input (pass through to the skill):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, output: "Updates an existing pipeline command using the **command-standard** skill. Provide the command name or file path and a description of the desired changes. Optionally add `scope=global` (default), `scope=extension:<name>`, or `scope=project` to indicate which bundle to look in." Stop.

2. Parse `scope` from arguments (default: `global`):
   - `global` → `GARAGE_BUNDLE_ROOT` = user-global garage bundle root
   - `extension:<name>` → `GARAGE_BUNDLE_ROOT` = that extension's bundle root
   - `project` → `GARAGE_BUNDLE_ROOT` = `<PROJECT_ROOT>/.ai-dev-garage/` (resolve `PROJECT_ROOT` from `project=<path>` or workspace)

3. Resolve `TARGET_COMMAND_FILE` from arguments: use the path directly if absolute, or resolve as `GARAGE_BUNDLE_ROOT/commands/<name>.md`.

4. Resolve the **command-standard** skill by walking `GARAGE_SEARCH_ROOTS` in order; load the first match at `skills/command-standard/SKILL.md`.

5. Apply the skill in **update** mode with: user input as change description, `TARGET_COMMAND_FILE`, `GARAGE_BUNDLE_ROOT`, `ASSET_SCOPE`. Output the proposed updated content. Do not write files until the user confirms.

6. If `scope` is `global` or `project` and changes were applied: **bundle-custom-manifest** for `commands` (flat basename vs `ai-dev-garage/...` like create-command). Skip for `extension:<name>`.
