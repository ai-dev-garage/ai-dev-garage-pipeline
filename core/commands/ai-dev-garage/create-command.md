---
name: create-command
description: Entry only — resolves the target bundle and runs the command-standard skill in create mode to draft a new pipeline command.
---

User input (pass through to the skill):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, output: "Creates a new pipeline command using the **command-standard** skill. Provide a name or description for the command. Optionally add `scope=global` (default), `scope=extension:<name>`, or `scope=project` to control where the command will be written." Stop.

2. Parse `scope` from arguments (default: `global`):
   - `global` → `GARAGE_BUNDLE_ROOT` = user-global garage bundle root
   - `extension:<name>` → `GARAGE_BUNDLE_ROOT` = that extension's bundle root
   - `project` → `GARAGE_BUNDLE_ROOT` = `<PROJECT_ROOT>/.ai-dev-garage/` (resolve `PROJECT_ROOT` from `project=<path>` or workspace)

3. Resolve `TARGET_COMMAND_FILE` = `GARAGE_BUNDLE_ROOT/commands/<name>.md` (name from user input or TBD in skill).

4. Resolve the **command-standard** skill by walking `GARAGE_SEARCH_ROOTS` in order; load the first match at `skills/command-standard/SKILL.md`.

5. Apply the skill in **create** mode with: user input as description, `TARGET_COMMAND_FILE`, `GARAGE_BUNDLE_ROOT`, `ASSET_SCOPE`. Output the proposed command content. Do not write files until the user confirms.

6. If `scope` is `global` or `project` and the user confirmed writes: **bundle-custom-manifest** with `CUSTOM_CATEGORY=commands`, `CUSTOM_ENTRY` = `ai-dev-garage/<basename>` if `TARGET_COMMAND_FILE` is under `.../commands/ai-dev-garage/`, else basename only. Output `garage custom add ...`. Skip for `extension:<name>`.
