---
name: create-agent
description: Entry only — resolves the target location and runs the agent-standard skill in create mode to draft a new pipeline agent.
---

User input (pass through to the skill):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, output: "Creates a new pipeline agent using the **agent-standard** skill. Provide a name or description for the agent. Optionally add `scope=plugin` (default) or `scope=project` to control where the agent will be written." Stop.

2. Parse `scope` from arguments (default: `plugin`):
   - `plugin` → `TARGET_ROOT` = `${CLAUDE_PLUGIN_ROOT}`
   - `project` → `TARGET_ROOT` = `<PROJECT_ROOT>/.ai-dev-garage/` (resolve `PROJECT_ROOT` from `project=<path>` or workspace)

3. Resolve `TARGET_AGENT_FILE` = `TARGET_ROOT/agents/<name>.md` (name from user input or TBD in skill).

4. Resolve the **agent-standard** skill relative to `${CLAUDE_PLUGIN_ROOT}`; load `skills/agent-standard/SKILL.md`.

5. Apply the skill in **create** mode with: user input as description, `TARGET_AGENT_FILE`, `TARGET_ROOT`, `ASSET_SCOPE`. Output the proposed agent content. Do not write files until the user confirms.
