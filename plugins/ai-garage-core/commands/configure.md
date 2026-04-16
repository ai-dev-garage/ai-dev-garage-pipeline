---
name: configure
description: One-shot walk-through covering every installed AI Dev Garage plugin. Resolves project config location, invokes each plugin's configure command in turn, and registers plugins in plugins.installed as they complete. Delegates — never edits YAML directly.
---

User input (pass through):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, print what this command does and stop:

   **What:** Runs `/ai-garage-dev-workflow:configure`, then each plugin-specific configure command for plugins that are installed but not yet in `plugins.installed`. Use this once per new project; after that, invoke individual plugin configures directly when you only need to adjust one namespace.

   **When:** First-run setup in a fresh workspace; after installing a new plugin (to add its namespace).

   **Usage:** Optional `project=<path>` to target a specific project root. Optional `only=<plugin>` to restrict to one plugin (same effect as calling that plugin's configure directly, but uses the aggregator's reporting).

2. **Resolve target project**
   - Parse `project=<path>` from user input. Otherwise use the workspace root.
   - Resolve `CONFIG_PATH` via **`ai-garage-core:config-merger`** with `path --scope project`.

3. **Walk dev-workflow first**
   - Always invoke `/ai-garage-dev-workflow:configure project=<PROJECT_ROOT>` before any integration plugin. Project + models are the foundation that other plugins reference, and the dev-workflow configure seeds `plugins.installed` for the first time.

4. **Walk remaining plugins**

   Known garage plugins with a `configure` command (in order):

   1. `ai-garage-jira` → `/ai-garage-jira:configure`
   2. `ai-garage-assistant` → `/ai-garage-assistant:configure`
   3. `ai-garage-architect` → `/ai-garage-architect:configure`

   For each plugin in the list:

   - Check whether the plugin is installed in this workspace (the command is resolvable). Skip silently if not.
   - Read `plugins.installed` via `config-merger get plugins.installed`. If the plugin is already present, ask: "`<plugin>` is already configured. Re-run its configure anyway? (yes / no / skip)". Skip by default.
   - Otherwise, invoke `<plugin>:configure project=<PROJECT_ROOT>` and wait for it to return control.

5. **Post-walk summary**

   - Read `plugins.installed` again.
   - Print a one-line-per-plugin recap:
     - `configured: <plugin>` for each entry in the list.
     - `available, not configured: <plugin>` for each known plugin that is installed but still missing from the list.
   - Suggest `/ai-dev-garage:doctor` as the next step.

## Rules

- **Do not edit YAML directly.** All writes are delegated to the individual plugin configures, which use `ai-garage-core:config-merger`.
- **Do not prompt the user for plugin-specific values.** Delegate to each plugin's own configure — that is where the schema knowledge lives.
- **Idempotent.** Re-running this command without arguments should detect already-configured plugins and offer to skip them.
- **Tolerate missing plugins.** If a known plugin is not installed, skip without an error. This command does **not** install plugins.
