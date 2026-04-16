---
name: config-merger
description: Deterministic get, set, merge-fragment, and validate operations against AI Dev Garage YAML config files. Preserves comments and unknown keys so the model does not have to hand-edit YAML. Backed by a small Python helper (scripts/config_merger.py). Use from configure/doctor commands and any skill that needs to read or write config values.
argument-hint: subcommand (get | set | merge-fragment | validate) + key path or fragment file
---

# Config merger

## When to use

- `configure` / `doctor` commands need to read or write keys in the unified config file.
- A plugin skill needs to read its own namespace (`integrations.<plugin>.*`) without round-tripping YAML by hand.
- A plugin's install step needs to merge its per-plugin template fragment into the root config on first run.

## Input

- `subcommand` — one of `get`, `set`, `merge-fragment`, `validate`, `path`.
- `--file <path>` — target config file. Defaults to the resolved project config path (see Rules).
- Subcommand-specific args. See [references/REFERENCE.md](references/REFERENCE.md) for the full CLI contract.

## Output

- `get` — stdout: the resolved value (scalar) or JSON (for lists/maps). Exit 0 on hit, 2 on miss.
- `set` — writes the file atomically. Exit 0 on success.
- `merge-fragment` — writes the file atomically with the fragment merged. Exit 0.
- `validate` — stdout: JSON `{ ok: bool, errors: [{key, message}] }`. Exit 0 always (errors surface in payload).
- `path` — stdout: the resolved absolute path to the project or global config file. Exit 0.

## Instructions

### 1. Resolve the helper path

The helper is at `${CLAUDE_PLUGIN_ROOT}/skills/config-merger/scripts/config_merger.py`. Call it as `python3 <path> <subcommand> ...`.

### 2. Dispatch by subcommand

- `get <key-path>` — read one key (e.g. `integrations.jira.sync-phases`). Returns the value or exits 2 on miss.
- `set <key-path> <value>` — write one scalar key. Value is parsed as YAML (so `true`, `42`, `"a string"`, `null` all work). Creates missing parent maps.
- `merge-fragment <fragment-file>` — deep-merge a YAML fragment into the target file with **base-wins** semantics (existing user values are preserved; fragment fills only missing keys). Unknown keys already in the target are kept. Use this for first-run seeding and for plugin fragments that introduce new integrations; use explicit `set` calls when the caller actually wants to overwrite.
- `validate` — run schema checks against the known config schema. Caller should read the JSON payload and act on any errors.
- `path [--scope project|global]` — resolve and print the canonical config path for the current environment without reading it. Used by `doctor`.

### 3. Surface results

- Trust the helper's exit code. Do not re-parse the file after a write.
- On `get` miss (exit 2), return `null` to the upstream caller; do not treat as an error.
- On any other non-zero exit, capture stderr and surface a one-line message to the user.

## Rules

- **Never write YAML from the model directly** when `config-merger` can do it. Hand-editing loses comments and drifts formatting.
- **Never ask the user to paste secrets** — `config-merger` only touches `config.yaml`, never `secrets.env`. Credentials stay in env files.
- **Atomic writes.** The helper writes to a temp file and renames. Do not disable.
- **Path resolution.** When `--file` is omitted, the helper uses: (1) `$AI_GARAGE_CONFIG` env if set; (2) `$PROJECT_ROOT/.ai-dev-garage/project-config.yaml`; (3) legacy fallback. See [references/REFERENCE.md](references/REFERENCE.md).
- **Plugin boundary.** The helper is self-contained under this skill's `scripts/` directory. No network, no repo-relative paths.
- **Schema evolution.** New plugins add their template fragment to their own plugin bundle; call `merge-fragment` from the plugin's `configure` command to land the fragment once.
