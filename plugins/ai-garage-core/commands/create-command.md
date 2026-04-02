---
name: create-command
description: Entry only — resolves the target location and runs the command-standard skill in create mode to draft a new pipeline command.
---

User input (pass through to the skill):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, output: "Creates a new pipeline command using the **command-standard** skill. Provide a name or description for the command. Optionally add `scope=plugin` (default) or `scope=project` to control where the command will be written." Stop.

2. Parse `scope` from arguments (default: `plugin`):
   - `plugin` → `TARGET_ROOT` = `${CLAUDE_PLUGIN_ROOT}`
   - `project` → `TARGET_ROOT` = `<PROJECT_ROOT>/.ai-dev-garage/` (resolve `PROJECT_ROOT` from `project=<path>` or workspace)

3. Resolve `TARGET_COMMAND_FILE` = `TARGET_ROOT/commands/<name>.md` (name from user input or TBD in skill).

4. Resolve the **command-standard** skill relative to `${CLAUDE_PLUGIN_ROOT}`; load `skills/command-standard/SKILL.md`.

5. Apply the skill in **create** mode with: user input as description, `TARGET_COMMAND_FILE`, `TARGET_ROOT`, `ASSET_SCOPE`. Output the proposed command content. Do not write files until the user confirms.
