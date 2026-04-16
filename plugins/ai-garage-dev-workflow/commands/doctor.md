---
name: doctor
description: Sanity-check AI Dev Garage project + model configuration for this workspace. Reports missing keys, unresolved paths, and schema violations. Read-only — never writes.
---

User input (pass through):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, print what this command does and stop:

   **What:** Runs the full `ai-garage-core:config-merger validate` pass and additional sanity checks over the `project.*` and `models.*` sections. Reports each finding as `OK | WARN | FAIL`. Read-only: never modifies `project-config.yaml` or any file.

   **When:** After `/ai-garage-dev-workflow:configure`, before kicking off `/deliver-task` on a new project, or when troubleshooting.

   **Usage:** Optional `project=<path>` for `PROJECT_ROOT`; otherwise workspace root.

2. **Resolve target project**
   - Parse `project=<path>`. Otherwise use the workspace root.
   - Resolve `CONFIG_PATH` by invoking **`ai-garage-core:config-merger`** with `path --scope project`.
   - If `CONFIG_PATH` does not exist, print `FAIL: project-config.yaml not found` and stop with a pointer to `/ai-garage-dev-workflow:configure`.

3. **Run schema validation**
   - Call `config-merger validate`. Parse the JSON payload. For each error returned, print `FAIL: <key> — <message>`.

4. **Project checks**

   For each key below, read with `config-merger get` and evaluate.

   | Check | Rule | Status mapping |
   |---|---|---|
   | `project.name` | non-empty string | missing → WARN, present → OK |
   | `project.stack` | non-empty list | empty → WARN ("no stack detected — run configure"), present → OK |
   | `project.build-command` | non-empty string | missing → WARN, present → OK |
   | `project.test-command` | non-empty string | missing → WARN, present → OK |
   | `project.docs-path` | path exists on disk if non-null | null → OK, missing directory → FAIL |
   | `project.base-branch` | non-empty string | default `main` → OK, other → OK |
   | `project.branch-prefix` | non-empty string | default `feature` → OK, other → OK |

5. **Models checks**

   Each of `models.low`, `models.medium`, `models.high` must resolve to `haiku`, `sonnet`, `opus`, `inherit`, or a full model ID. Report missing keys as WARN (defaults will apply), invalid values as FAIL.

6. **plugins.installed sanity**

   - Read `plugins.installed` via `config-merger get`.
   - If `ai-garage-dev-workflow` is not in the list, print `WARN: this plugin is not registered in plugins.installed — run /ai-garage-dev-workflow:configure to register`.
   - For every other entry in `plugins.installed`, print `INFO: <plugin> registered (run /<plugin>:doctor for plugin-specific checks)`.

7. **Summary**

   Print a final count line:

   ```
   Doctor: <N> OK / <M> WARN / <K> FAIL
   ```

   Exit without further action — no writes, no agent dispatch.

## Rules

- **Read-only.** Never call `config-merger set`, `add-to-list`, or `merge-fragment`. Never edit files.
- **Never prompt the user for values.** Report findings; point at `/ai-garage-dev-workflow:configure` for fixes.
- **Scope discipline.** This doctor only covers `project.*`, `models.*`, and `plugins.installed`. Each other plugin has its own `doctor` command for its own namespace.
