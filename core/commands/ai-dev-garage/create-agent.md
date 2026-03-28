---
name: create-agent
description: Entry only — resolves the target bundle and runs the agent-standard skill in create mode to draft a new pipeline agent.
---

User input (pass through to the skill):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, output: "Creates a new pipeline agent using the **agent-standard** skill. Provide a name or description for the agent. Optionally add `scope=global` (default), `scope=extension:<name>`, or `scope=project` to control where the agent will be written." Stop.

2. Parse `scope` from arguments (default: `global`):
   - `global` → `GARAGE_BUNDLE_ROOT` = user-global garage bundle root (from install config or default)
   - `extension:<name>` → `GARAGE_BUNDLE_ROOT` = that extension's bundle root
   - `project` → `GARAGE_BUNDLE_ROOT` = `<PROJECT_ROOT>/.ai-dev-garage/` (resolve `PROJECT_ROOT` from `project=<path>` or workspace)

3. Resolve `TARGET_AGENT_FILE` = `GARAGE_BUNDLE_ROOT/agents/<name>.md` (name from user input or TBD in skill).

4. Resolve the **agent-standard** skill by walking `GARAGE_SEARCH_ROOTS` in order; load the first match at `skills/agent-standard/SKILL.md`.

5. Apply the skill in **create** mode with: user input as description, `TARGET_AGENT_FILE`, `GARAGE_BUNDLE_ROOT`, `ASSET_SCOPE`. Output the proposed agent content. Do not write files until the user confirms.
