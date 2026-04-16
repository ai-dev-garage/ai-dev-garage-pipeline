---
name: configure
description: Interactive walk-through of AI Dev Garage project + model settings. Project metadata (name, stack, commands, branch policy) and model routing (low/medium/high). Writes through ai-garage-core:config-merger so comments and unknown keys are preserved.
---

User input (pass through):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, print what this command does and stop:

   **What:** Walks through the `project` and `models` sections of `<PROJECT_ROOT>/.ai-dev-garage/project-config.yaml`. Plugin-specific integrations are configured by each plugin's own `configure` command (for example `/ai-garage-jira:configure`, `/ai-garage-assistant:configure`). For a one-shot walk-through covering every installed plugin, use `/ai-dev-garage:configure`.

   **When:** First-time project setup, after installing the plugin, or when adjusting build/test commands, branch policy, or model routing.

   **Usage:** Optional `project=<path>` for `PROJECT_ROOT`; otherwise workspace root. Optional `section=<name>` to run a subset: `project`, `models`, or `all` (default).

2. **Resolve target project**
   - Parse `project=<path>` from user input. If present, use it as `PROJECT_ROOT`; otherwise use the workspace root.
   - Resolve `CONFIG_PATH` by invoking **`ai-garage-core:config-merger`** with `path --scope project`.
   - Set `TEMPLATE_PATH` = `${CLAUDE_PLUGIN_ROOT}/project-config.template.yaml`.

3. **Seed the file on first run**
   - If `CONFIG_PATH` does not yet exist, call `config-merger merge-fragment <TEMPLATE_PATH>` once to establish the shape. `merge-fragment` uses **base-wins** semantics, so running it again later never overwrites user-entered values.

4. **Parse section filter**
   - Parse `section=<name>` from user input. Supported values: `project`, `models`, `all` (default).
   - If a specific section is requested, skip the other(s).

5. **Section: project** (skip if section filter excludes)

   For each key below, read the current value with `config-merger get <key-path>` and show it (or `(unset)`). Ask the user to confirm, change, or skip. Write confirmed answers with `config-merger set <key-path> <value>`.

   - `project.name` — service identifier
   - `project.stack` — list of stack identifiers (offer auto-detection; see project-config-resolver SKILL.md)
   - `project.build-command` — shell command
   - `project.test-command` — shell command
   - `project.docs-path` — absolute path; validate it exists on disk; allow `null` if no docs
   - `project.base-branch` — default `main`
   - `project.branch-prefix` — default `feature`

   Validate each input per rules in `project-config-resolver/references/REFERENCE.md`.

6. **Section: models** (skip if section filter excludes)

   Same read/confirm/write pattern. Valid values: `haiku`, `sonnet`, `opus`, `inherit`, or a full model ID.

   - `models.low` (default `haiku`)
   - `models.medium` (default `sonnet`)
   - `models.high` (default `inherit`)

7. **Register this plugin**
   - After any section ran successfully, call `config-merger add-to-list plugins.installed ai-garage-dev-workflow` (idempotent — no-op if already present). This lets `/ai-dev-garage:configure` and `/ai-dev-garage:doctor` know the plugin is in scope for this project.

8. **Validate the result**
   - Run `config-merger validate` and surface any returned errors to the user before concluding.

9. **Final summary**
   - List what changed (key: old -> new).
   - Point the user at Jira/assistant/architect configure commands when relevant (e.g., "to set up Jira next, run `/ai-garage-jira:configure`").

## Rules

- **One question at a time.** Wait for the user's answer before proceeding.
- **Never write secrets to `project-config.yaml`.** API tokens belong in `~/.ai-dev-garage/secrets.env` (global) or `<project>/.ai-dev-garage/secrets.env` (project). Point users at the plugin-specific configure commands for credential guidance.
- **Never hand-edit YAML.** All reads/writes go through `ai-garage-core:config-merger`; it preserves comments, keeps unknown keys, and writes atomically.
- **Validate paths on disk** before writing them.
- Use the `project-config-resolver` skill's existing validation rules — do not duplicate logic.
- **Scope discipline.** This command owns `project.*` and `models.*` only. Do **not** prompt for `integrations.*` keys; those live in each plugin's own `configure` command.
