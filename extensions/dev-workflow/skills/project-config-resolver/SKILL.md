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

Search for the config file in order:

1. `{PROJECT_ROOT}/.ai-dev-garage/project-config.yaml`
2. `~/.ai-dev-garage/config.yaml` (global fallback)

If neither exists, create `{PROJECT_ROOT}/.ai-dev-garage/project-config.yaml` with empty sections and proceed to self-recovery for requested keys.

### 2. Parse caller request

The caller specifies which value(s) they need. Supported keys:

- `project.name`
- `project.build-command`
- `project.test-command`
- `project.docs-path`
- `project.base-branch`
- `project.branch-prefix`
- `models.low` / `models.medium` / `models.high`
- `integrations.jira.base-url` / `integrations.jira.api-token`

Resolve only the requested keys. Callers must handle a `null` return gracefully.

### 3. Resolve each requested value

For each requested key:

1. Read the value from the config file.
2. If present and non-empty, validate it (path keys: verify path exists on disk; other keys: verify non-placeholder).
3. If valid, return the value.
4. If absent, empty, or invalid, enter **self-recovery** for that key.

### 4. Self-recovery

Ask the user one question at a time. Wait for their answer before proceeding.

For **path-based keys** (`docs-path`):
- Ask if the resource exists. If no, return `null` with a note.
- If yes, ask for the absolute path. Validate on disk. Write back to config on success.

For **command keys** (`build-command`, `test-command`):
- Ask the user for the command. Write back to config.

For **credential keys** (`integrations.jira.api-token`):
- Check environment variable first (`JIRA_API_TOKEN`).
- Then check global config `~/.ai-dev-garage/config.yaml`.
- If still missing, ask the user. Write to project config (or suggest env var for secrets).

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
- Config schema and defaults: see [REFERENCE.md](references/REFERENCE.md).
