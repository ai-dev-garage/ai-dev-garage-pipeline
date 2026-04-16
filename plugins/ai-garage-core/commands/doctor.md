---
name: doctor
description: Run every installed AI Dev Garage plugin's doctor command and produce a combined sanity report. Read-only — delegates to plugin doctors. Never writes config or secrets.
---

User input (pass through):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, print what this command does and stop:

   **What:** Invokes `/ai-garage-dev-workflow:doctor` and each plugin-specific doctor command for plugins present in `plugins.installed`. Collects each doctor's `OK / WARN / FAIL` output and prints a single unified summary.

   **When:** After `/ai-dev-garage:configure`, before shipping on a new workspace, when debugging a silently failing workflow, or whenever you want a quick "is the garage wired up correctly?" check.

   **Usage:** Optional `project=<path>`. Optional `only=<plugin>` to restrict to one plugin.

2. **Resolve target project**
   - Parse `project=<path>`. Otherwise use the workspace root.
   - Resolve `CONFIG_PATH` via **`ai-garage-core:config-merger`** with `path --scope project`.
   - If `CONFIG_PATH` does not exist, print `FAIL: project-config.yaml not found — run /ai-dev-garage:configure first` and stop.

3. **Always run dev-workflow doctor**
   - Invoke `/ai-garage-dev-workflow:doctor project=<PROJECT_ROOT>`. Capture its output.

4. **Iterate `plugins.installed`**

   - Read `plugins.installed` via `config-merger get`. If the list is empty or the key is missing, print `WARN: no plugins registered — run /ai-dev-garage:configure` and stop.
   - For each entry that is **not** `ai-garage-dev-workflow`, resolve the corresponding doctor command using the mapping below and invoke it.

   | Plugin | Doctor command |
   |---|---|
   | `ai-garage-jira` | `/ai-garage-jira:doctor` |
   | `ai-garage-assistant` | `/ai-garage-assistant:doctor` |
   | `ai-garage-architect` | `/ai-garage-architect:doctor` |

   If a plugin is listed in `plugins.installed` but its doctor command is not resolvable, print `WARN: <plugin> registered but its doctor command is not installed` and continue.

5. **Combined summary**

   After every doctor has run, print a final three-line totals block:

   ```
   Garage doctor — <total OK> OK / <total WARN> WARN / <total FAIL> FAIL
   ```

   Then, if any FAIL appeared, list the top three failures with their source plugin. If any WARN appeared, list the first three warnings similarly. No recommendations beyond pointing at the specific `/…:configure` command for the plugin.

## Rules

- **Read-only.** This command only delegates to plugin doctors, which are themselves read-only.
- **Never print secrets.** Each plugin's doctor is responsible for redaction; this aggregator just forwards their output.
- **Tolerate missing plugins.** Skip entries in `plugins.installed` whose doctor is not resolvable; note in the summary.
- **Do not run workflows.** This is a health check, not a dispatcher.
