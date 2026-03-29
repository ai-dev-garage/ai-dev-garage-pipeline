---
name: review-command
description: Entry only — resolves the target command file and runs the command-standard skill in review mode to audit an existing pipeline command.
---

User input (pass through to the skill):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, output: "Reviews an existing pipeline command using the **command-standard** skill. Provide the command name or file path. Optionally add `scope=global` (default), `scope=extension:<name>`, or `scope=project` to indicate which bundle to look in." Stop.

2. Parse `scope` from arguments (default: `global`):
   - `global` → `GARAGE_BUNDLE_ROOT` = user-global garage bundle root
   - `extension:<name>` → `GARAGE_BUNDLE_ROOT` = that extension's bundle root
   - `project` → `GARAGE_BUNDLE_ROOT` = `<PROJECT_ROOT>/.ai-dev-garage/` (resolve `PROJECT_ROOT` from `project=<path>` or workspace)

3. Resolve `TARGET_COMMAND_FILE` from arguments: use the path directly if absolute, or resolve as `GARAGE_BUNDLE_ROOT/commands/<name>.md`.

4. Resolve the **command-standard** skill by walking `GARAGE_SEARCH_ROOTS` in order; load the first match at `skills/command-standard/SKILL.md`.

5. Apply the skill in **review** mode with: `TARGET_COMMAND_FILE`, `GARAGE_BUNDLE_ROOT`, `ASSET_SCOPE`. Output issues and proposed fixes. Do not apply changes until the user confirms.

6. If the user **applies** edits for `global` or `project`, finish with **bundle-custom-manifest** for `commands` (same entry rule as create-command). Skip if no writes or `extension:<name>`.
