---
name: configure
description: Interactive walk-through of Notion settings for the AI Dev Garage personal assistant. Sets the MCP connector name, target database id, and optional defaults. Writes through ai-garage-core:config-merger; never prompts for secrets.
---

User input (pass through):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, print what this command does and stop:

   **What:** Walks through the `integrations.assistant.*` section of `<PROJECT_ROOT>/.ai-dev-garage/project-config.yaml` — Notion MCP connector, target database id, parent page for first-time DB bootstrap, default tags, session prefix. Registers `ai-garage-assistant` in `plugins.installed`.

   **When:** First time wiring the assistant into this project, or when switching Notion workspace / database.

   **Usage:** Optional `project=<path>` for `PROJECT_ROOT`; otherwise workspace root.

2. **Resolve target project**
   - Parse `project=<path>` from user input. If present, use it as `PROJECT_ROOT`; otherwise use the workspace root.
   - Resolve `CONFIG_PATH` by invoking **`ai-garage-core:config-merger`** with `path --scope project`.
   - Set `TEMPLATE_PATH` = `${CLAUDE_PLUGIN_ROOT}/project-config.template.yaml`.

3. **Seed on first run**
   - If `CONFIG_PATH` does not exist or has no `integrations.assistant` block, call `config-merger merge-fragment <TEMPLATE_PATH>` to seed the shape. Base-wins semantics means re-running never overwrites user-entered values.

4. **Walk the keys**

   For each key, read the current value with `config-merger get <key-path>`, show it (or `(unset)`), ask to confirm/change/skip, and write with `config-merger set <key-path> <value>`.

   - `integrations.assistant.notion-mcp-connector` — name of the Notion MCP connector (free text, e.g., `garage-notion`). If left null, the plugin auto-detects when exactly one matching MCP is available. Changing this writes the exact name the user's setup uses.
   - `integrations.assistant.notion-database-id` — Notion database id / UUID where assistant entries land.
   - `integrations.assistant.notion-parent-page-id` — only needed for first-time DB bootstrap; clear to `null` once the database exists.
   - `integrations.assistant.default-tags` — list of strings applied to every entry (e.g., `[work, ai-garage]`). Use `config-merger add-to-list integrations.assistant.default-tags <tag>` to append without overwriting.
   - `integrations.assistant.session-prefix` — free-form prefix prepended to the Session property (often the project name). `null` disables.

5. **Credential note (Notion MCP)**

   The assistant does not hold a Notion token — it delegates to the MCP connector configured in Claude Code / Cursor / the host. If no matching connector is installed, point the user at the assistant's README for MCP setup (do **not** attempt to configure Notion auth from this command).

6. **Register this plugin**
   - `config-merger add-to-list plugins.installed ai-garage-assistant` (idempotent).

7. **Validate**
   - Run `config-merger validate` and surface any returned errors that touch `integrations.assistant.*`.

8. **Final summary**
   - List what changed (key: old -> new).
   - If `notion-database-id` is still null, remind the user that `/assistant:setup-claude-project` bootstraps a database under `notion-parent-page-id`.

## Rules

- **Never ask the user to paste the Notion token.** Tokens live in the MCP connector configuration, not here.
- **One question at a time.** Wait for the user's answer.
- **Never hand-edit YAML.** Use `ai-garage-core:config-merger`.
- **Scope discipline.** This command owns `integrations.assistant.*` only.
