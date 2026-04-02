---
name: review-agent
description: Entry only — resolves the target agent file and runs the agent-standard skill in review mode to audit an existing pipeline agent.
---

User input (pass through to the skill):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, output: "Reviews an existing pipeline agent using the **agent-standard** skill. Provide the agent name or file path. Optionally add `scope=plugin` (default) or `scope=project` to indicate where to look." Stop.

2. Parse `scope` from arguments (default: `plugin`):
   - `plugin` → `TARGET_ROOT` = `${CLAUDE_PLUGIN_ROOT}`
   - `project` → `TARGET_ROOT` = `<PROJECT_ROOT>/.ai-dev-garage/` (resolve `PROJECT_ROOT` from `project=<path>` or workspace)

3. Resolve `TARGET_AGENT_FILE` from arguments: use the path directly if absolute, or resolve as `TARGET_ROOT/agents/<name>.md`.

4. Resolve the **agent-standard** skill relative to `${CLAUDE_PLUGIN_ROOT}`; load `skills/agent-standard/SKILL.md`.

5. Apply the skill in **review** mode with: `TARGET_AGENT_FILE`, `TARGET_ROOT`, `ASSET_SCOPE`. Output issues and proposed fixes. Do not apply changes until the user confirms.
