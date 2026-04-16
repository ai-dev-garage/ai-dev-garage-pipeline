---
name: configure
description: Interactive walk-through of architect settings for AI Dev Garage. Sets doc sources (local), default output format + paths, and an optional verification command. Writes through ai-garage-core:config-merger.
---

User input (pass through):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, print what this command does and stop:

   **What:** Walks through the `integrations.architect.*` section of `<PROJECT_ROOT>/.ai-dev-garage/project-config.yaml` — doc sources (where to find existing ADRs and diagrams), default output format/paths for new artifacts, and an optional verification command run after artifact writes. Registers `ai-garage-architect` in `plugins.installed`. All keys are optional; if everything stays `null`/empty the plugin works in greenfield mode.

   **When:** First time wiring the architect into this project, or when moving the ADR folder / switching to AsciiDoc / Markdown.

   **Usage:** Optional `project=<path>` for `PROJECT_ROOT`; otherwise workspace root.

2. **Resolve target project**
   - Parse `project=<path>` from user input. If present, use it as `PROJECT_ROOT`; otherwise use the workspace root.
   - Resolve `CONFIG_PATH` by invoking **`ai-garage-core:config-merger`** with `path --scope project`.

3. **Walk the keys**

   Read the current value with `config-merger get <key-path>` before each prompt; show it (or `(unset)`). Write confirmed answers with `config-merger set <key-path> <value>`. Use `add-to-list` for `doc-sources`.

   - **Doc source (local):** ask the user for the path to the existing architecture docs (e.g., `src/docs`). Validate it exists on disk. Append via `config-merger add-to-list integrations.architect.doc-sources '{type: local, path: <value>}'`. Multiple sources are allowed — offer to add more.
   - **Default output format:** `integrations.architect.default-output.format` — `adoc` or `md`. Default `md`. If existing ADRs were detected under the doc source, suggest matching their format.
   - **ADR path:** `integrations.architect.default-output.adr-path` — relative path where new ADRs are written. Validate the parent exists or offer to create it on first ADR write.
   - **Diagram path:** `integrations.architect.default-output.diagram-path` — relative path for PlantUML diagrams. Reserved for a future phase; still safe to set now.
   - **Verification command:** `integrations.architect.verification-command` — shell command the publisher runs after writes to validate the artifact renders (e.g., `./gradlew publishToConfluence --convertOnly`). `null` disables verification.

4. **Greenfield hint**

   If the user supplies **no** doc source and leaves output paths unset, the plugin still works — it falls back to `docs/architecture/` under project root. Mention this once so users know it is a valid state.

5. **Register this plugin**
   - `config-merger add-to-list plugins.installed ai-garage-architect` (idempotent).

6. **Validate**
   - Run `config-merger validate` and surface any errors that touch `integrations.architect.*`.

7. **Final summary**
   - List what changed (key: old -> new).
   - Point the user at `/architect` to start a session.

## Rules

- **One question at a time.** Wait for the user's answer.
- **Never hand-edit YAML.** Use `ai-garage-core:config-merger`.
- **Validate paths on disk** before writing them. If a path does not exist, offer to accept it anyway (user may plan to create it) but warn.
- **Scope discipline.** This command owns `integrations.architect.*` only.
