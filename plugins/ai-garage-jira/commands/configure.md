---
name: configure
description: Interactive walk-through of Jira integration settings for AI Dev Garage. Handles base URL, phase-sync opt-in with transition names, sub-task type, and points the user at the correct place to store the API token. Writes through ai-garage-core:config-merger.
---

User input (pass through):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, print what this command does and stop:

   **What:** Walks through the `integrations.jira.*` section of `<PROJECT_ROOT>/.ai-dev-garage/project-config.yaml` and guides the user to place their API token in the right file. Registers `ai-garage-jira` in `plugins.installed`.

   **When:** First time wiring Jira into this project, or when changing base URL, sub-task type, or transition names.

   **Usage:** Optional `project=<path>` for `PROJECT_ROOT`; otherwise workspace root. Optional `section=<name>` to run a subset: `base`, `sync`, or `all` (default).

2. **Resolve target project**
   - Parse `project=<path>` from user input. If present, use it as `PROJECT_ROOT`; otherwise use the workspace root.
   - Resolve `CONFIG_PATH` by invoking **`ai-garage-core:config-merger`** with `path --scope project`.

3. **Parse section filter**
   - Supported values: `base`, `sync`, `all` (default).

4. **Section: base** (skip if section filter excludes)

   Read the current value with `config-merger get <key-path>`. Show it (or `(unset)`). Ask the user to confirm or change. Write with `config-merger set <key-path> <value>`.

   - `integrations.jira.base-url` — must start with `https://`. If the user already has `JIRA_BASE_URL` in their env file (see step 7), offer to skip.
   - `integrations.jira.subtask-type` — default `"Sub-task"`; some instances use `"Subtask"` or a custom name.

5. **Section: sync** (skip if section filter excludes)

   Offer to enable WBS phase mirroring as Jira sub-tasks:

   - Describe the feature briefly: creates sub-tasks per WBS phase, transitions them through the board as phases progress, leaves `Done` to the user.
   - Ask: "Enable Jira phase sync? (yes / no)"
   - If **yes:**
     - `config-merger set integrations.jira.sync-phases true`.
     - Walk through each transition (read current, ask keep/change/`null` to skip). Case-insensitive substring matching is used against Jira's available transition names, so exact case doesn't matter.
       - `integrations.jira.transitions.phase-started` (default `"In Progress"`)
       - `integrations.jira.transitions.phase-implemented` (default `"Need Review"`)
       - `integrations.jira.transitions.review-started` (default `"In Review"`)
       - `integrations.jira.transitions.phase-ready` (default `"Ready"`)
   - If **no:** `config-merger set integrations.jira.sync-phases false` (explicit opt-out prevents future nudges).

6. **Credential placement (do not prompt to paste the token)**

   Check whether the user already has a working env file by reading it yourself from one of (in order):

   - `~/.ai-dev-garage/secrets.env` (canonical global)
   - `<PROJECT_ROOT>/.ai-dev-garage/secrets.env` (canonical project)
   - `~/.config/ai-garage/jira.env` (legacy global)
   - `<PROJECT_ROOT>/.config/ai-garage/jira.env` (legacy project)

   Also inspect process env: `JIRA_BASE_URL`, `JIRA_API_TOKEN` (fallback `ATLASSIAN_API_TOKEN`, then `CONFLUENCE_API_TOKEN`).

   If a base URL and token are both present anywhere in that overlay, report "Jira credentials detected" and stop. Do **not** echo the token.

   Otherwise, instruct the user (short):
   - "Copy `${CLAUDE_PLUGIN_ROOT}/jira.template.env` to `~/.ai-dev-garage/secrets.env` (or the project-level equivalent) and fill in `JIRA_BASE_URL` + `JIRA_API_TOKEN`."
   - Mention that `CONFLUENCE_API_TOKEN` in the environment is used as a last-resort fallback for users who already have that variable set.

7. **Register this plugin**
   - `config-merger add-to-list plugins.installed ai-garage-jira` (idempotent).

8. **Validate**
   - Run `config-merger validate` and surface any returned errors that touch `integrations.jira.*`.

9. **Final summary**
   - List what changed (key: old -> new).
   - If phase sync was enabled, remind the user to verify the transition names match their Jira board by running `/ai-garage-jira:doctor` once the token is in place.

## Rules

- **Never prompt the user to paste the API token into chat.** Point them at the env file paths instead.
- **Never write the token to `project-config.yaml`.** It stays in `secrets.env` (canonical) or `jira.env` (legacy).
- **One question at a time.** Wait for the user's answer.
- **Never hand-edit YAML.** Use `ai-garage-core:config-merger`.
- **Scope discipline.** This command owns `integrations.jira.*` only; it does not touch `project.*`, `models.*`, or any other plugin's namespace.
