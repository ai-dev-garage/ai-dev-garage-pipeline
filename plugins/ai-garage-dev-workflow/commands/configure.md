---
name: configure
description: Interactive walk-through of AI Dev Garage project configuration. Reviews current values, prompts for missing or unset keys, and writes the result to .ai-dev-garage/project-config.yaml.
---

User input (pass through):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, print what this command does and stop:

   **What:** Walks through project configuration section by section (project, models, integrations.jira) and writes the result to `<PROJECT_ROOT>/.ai-dev-garage/project-config.yaml`.

   **When:** First-time project setup, after installing new plugin features, or when adjusting integration settings (e.g., enabling Jira phase sync, changing transition names).

   **Usage:** Optional `project=<path>` for `PROJECT_ROOT`; otherwise workspace root. Optional `section=<name>` to configure only one section: `project`, `models`, `jira`, or `jira-sync`.

2. **Resolve target project**
   - Parse `project=<path>` from user input. If present, use it as `PROJECT_ROOT`; otherwise use the workspace root.
   - Set `CONFIG_PATH` = `<PROJECT_ROOT>/.ai-dev-garage/project-config.yaml`.
   - Set `TEMPLATE_PATH` = `${CLAUDE_PLUGIN_ROOT}/project-config.template.yaml`.

3. **Load current state**
   - If `CONFIG_PATH` exists, load it. Otherwise inform the user that a new file will be created from the template and create `<PROJECT_ROOT>/.ai-dev-garage/` if missing.
   - Read `TEMPLATE_PATH` to know the full schema and defaults.

4. **Parse section filter**
   - Parse `section=<name>` from user input. Supported values: `project`, `models`, `jira`, `jira-sync`, `all` (default).
   - If a specific section is requested, skip the others.

5. **Section: project** (skip if section filter excludes)

   For each key, show the current value (or `(unset)`) and ask the user to confirm, change, or skip:

   - `project.name` — service identifier
   - `project.stack` — list of stack identifiers (offer auto-detection; see project-config-resolver SKILL.md)
   - `project.build-command` — shell command
   - `project.test-command` — shell command
   - `project.docs-path` — absolute path; validate it exists on disk; allow `null` if no docs
   - `project.base-branch` — default `main`
   - `project.branch-prefix` — default `feature`

   Validate each input per rules in `project-config-resolver/references/REFERENCE.md`.

6. **Section: models** (skip if section filter excludes)

   For each key, show current value and ask the user to keep or change. Valid values: `haiku`, `sonnet`, `opus`, `inherit`, or a full model ID.

   - `models.low` (default `haiku`)
   - `models.medium` (default `sonnet`)
   - `models.high` (default `inherit`)

7. **Section: jira** (skip if section filter excludes)

   - Ask: "Use Jira integration? (yes / no / skip)"
   - If **yes:**
     - `integrations.jira.base-url` — must start with `https://`. If already in `jira.env`, note that and skip.
     - `integrations.jira.api-token` — **do not prompt to paste**. Instead, instruct the user to set `JIRA_API_TOKEN` env var or place it in `~/.config/ai-garage/jira.env` or `<project>/.config/ai-garage/jira.env`. Point them at the template in the ai-garage-jira plugin root.
   - If **no / skip:** leave null.

8. **Section: jira-sync** (skip if section filter excludes; also skip if jira base-url is unset)

   Offer to enable WBS phase mirroring as Jira sub-tasks:

   - Briefly describe the feature: creates sub-tasks per WBS phase, transitions them through the board as phases progress, leaves `Done` to the user.
   - Ask: "Enable Jira phase sync? (yes / no)"
   - If **yes:**
     - Set `integrations.jira.sync-phases: true`.
     - Ask for `subtask-type` (default `Sub-task` — confirm with user; some Jira instances use `Subtask` or custom names).
     - Walk through each transition, showing the default, asking the user to keep, change, or set to `null` to skip:
       - `transitions.phase-started` (default `In Progress`)
       - `transitions.phase-implemented` (default `Need Review`)
       - `transitions.review-started` (default `In Review`)
       - `transitions.phase-ready` (default `Ready`)
     - Remind the user that transitions are case-insensitive substring matches against Jira's available transition names.
   - If **no:** set `integrations.jira.sync-phases: false` (explicit opt-out, prevents future nudges).

9. **Write the result**
   - Merge the updated values into the existing `CONFIG_PATH` content (preserve comments and unrelated keys).
   - If the file was newly created, start from `TEMPLATE_PATH` and fill in user-provided values.
   - Write the file.

10. **Final summary**
    - List what changed (key: old -> new).
    - Point the user at relevant docs: ai-garage-jira plugin README for credentials, ai-garage-dev-workflow README for command usage.
    - If Jira sync was enabled, remind the user to verify the configured transition names match their Jira board.

## Rules

- **One question at a time.** Wait for the user's answer before proceeding.
- **Never write secrets to `project-config.yaml`.** API tokens must come from env vars or `jira.env` files.
- **Preserve unknown keys** already in the config file (do not delete things this command does not know about).
- **Validate paths on disk** before writing them.
- Use the `project-config-resolver` skill's existing validation rules — do not duplicate logic.
