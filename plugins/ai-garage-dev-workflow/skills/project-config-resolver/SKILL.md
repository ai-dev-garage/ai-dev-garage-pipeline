---
name: project-config-resolver
description: Read project-config.yaml and resolve requested config values (build command, test command, docs path, branch settings, model mappings, integration credentials). Self-recovering — if a value is missing or invalid, asks the user interactively and writes the answer back. Use whenever any agent or skill needs project configuration.
argument-hint: key names to resolve (e.g. build-command, docs-path, jira)
---

# Project config resolver

## When to use

- Any agent or skill needs project-level settings (build command, test command, docs path, branch prefix, model mapping, integration credentials).
- First run on a project where `.ai-dev-garage/project-config.yaml` does not yet exist.
- A previously configured value has become invalid (path no longer exists, etc.).

## Instructions

### 1. Locate the config file

Resolve the target path by calling **`ai-garage-core:config-merger`** with subcommand `path` (do **not** read YAML directly — the helper owns path resolution and format preservation). Precedence applied by the helper:

1. `$AI_GARAGE_CONFIG` env override (absolute path).
2. `{PROJECT_ROOT}/.ai-dev-garage/project-config.yaml` — **canonical** project path.
3. `~/.ai-dev-garage/config.yaml` — **canonical** global fallback (when no project root or no project file).
4. **Legacy fallback** (read-only; triggers a one-line deprecation warning on stderr):
   - `~/.config/ai-garage/config.yaml`
   - `{PROJECT_ROOT}/.ai-dev-garage/config.yaml` (filename variant)

If no config exists yet, proceed to self-recovery for requested keys; `config-merger set` will create the canonical file on first write.

### 2. Parse caller request

The caller specifies which value(s) they need. Supported keys:

- `project.name`
- `project.stack`
- `project.build-command`
- `project.test-command`
- `project.docs-path`
- `project.base-branch`
- `project.branch-prefix`
- `models.low` / `models.medium` / `models.high`
- `integrations.jira.base-url` / `integrations.jira.api-token`
- `integrations.jira.sync-phases`
- `integrations.jira.subtask-type`
- `integrations.jira.transitions.phase-started`
- `integrations.jira.transitions.phase-implemented`
- `integrations.jira.transitions.review-started`
- `integrations.jira.transitions.phase-ready`
- `integrations.assistant.notion-mcp-connector`
- `integrations.assistant.notion-database-id`
- `integrations.assistant.notion-parent-page-id`
- `integrations.assistant.default-tags`
- `integrations.assistant.session-prefix`

Resolve only the requested keys. Callers must handle a `null` return gracefully.

### 3. Resolve each requested value

For each requested key:

1. Read the value with `config-merger get <key-path>`. Exit code `2` means miss — treat as absent.
2. If present and non-empty, validate it (path keys: verify path exists on disk; other keys: verify non-placeholder).
3. If valid, return the value.
4. If absent, empty, or invalid, enter **self-recovery** for that key.

### 4. Self-recovery

Ask the user one question at a time. Wait for their answer before proceeding.

All writes go through **`config-merger set <key-path> <value>`** (preserves comments + unknown keys + atomic write). Do **not** hand-edit YAML.

For **path-based keys** (`docs-path`):
- Ask if the resource exists. If no, return `null` with a note.
- If yes, ask for the absolute path. Validate on disk. `config-merger set project.docs-path <absolute-path>` on success.

For **command keys** (`build-command`, `test-command`):
- Ask the user for the command. `config-merger set project.build-command '<value>'`.

For **credential keys** (`integrations.jira.api-token`):
- Check environment variable first (`JIRA_API_TOKEN`).
- Then check global config via `config-merger --scope global get integrations.jira.api-token`.
- If still missing, ask the user. Prefer instructing them to place the token in `~/.ai-dev-garage/secrets.env` (canonical) or `<project>/.ai-dev-garage/secrets.env`; only fall back to writing to project config if they insist.

For **stack keys** (`project.stack`):
- Auto-detect from project files at `PROJECT_ROOT`:

  | File / Pattern | Detected Stack |
  |---|---|
  | `pom.xml` or `build.gradle` / `build.gradle.kts` | `java` |
  | `package.json` | `node` |
  | `requirements.txt` / `pyproject.toml` | `python` |
  | `go.mod` | `go` |
  | `Cargo.toml` | `rust` |
  | `*.xcodeproj` / `Package.swift` | `ios` |

- Multiple stacks can be detected (e.g., `[java, spring]` if `pom.xml` contains `spring-boot`).
- If auto-detection is ambiguous or finds nothing, ask the user.
- Write the detected/confirmed value back to config as a list.

For **model keys** (`models.low`, `models.medium`, `models.high`):
- If missing, apply defaults: `low: haiku`, `medium: sonnet`, `high: inherit`.
- Write defaults back to config.

### 5. Return resolved values

Return resolved values to the caller. For any value that could not be resolved, return `null` with a short note.

## Input

- Requested key names (one or more from the supported keys list).
- `PROJECT_ROOT` — resolved project root path.

## Output

- Map of requested keys to resolved values (or `null` with note).

## Rules

- **Interactive skill** — prompts the user when values are missing or invalid; not stateless.
- **One question at a time.** Wait for the user's answer before asking the next.
- **Never overwrite existing valid values.** Only write keys that were missing or broken.
- **Never block the workflow.** Optional values return `null` + note rather than stopping.
- **Credential precedence:** env var > project config > global config > interactive recovery.
- **Never hand-edit YAML.** All reads/writes go through `ai-garage-core:config-merger` to preserve comments, unknown keys, and atomic write guarantees.
- Config schema and defaults: see [REFERENCE.md](references/REFERENCE.md).
