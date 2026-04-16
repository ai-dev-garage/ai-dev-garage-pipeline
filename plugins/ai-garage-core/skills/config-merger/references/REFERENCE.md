# Config merger — reference

## CLI contract

```
python3 config_merger.py <subcommand> [options]
```

### Subcommands

| Subcommand | Arguments | Exit codes | Stdout |
|------------|-----------|------------|--------|
| `get` | `<key-path>` | 0 hit, 2 miss, 1 error | scalar or JSON |
| `set` | `<key-path> <value>` | 0 success, 1 error | (empty) |
| `merge-fragment` | `<fragment-file>` | 0 success, 1 error | (empty) |
| `validate` | (none) | 0 always | JSON `{ok, errors}` |
| `path` | `[--scope project\|global]` | 0 success, 1 error | absolute path |

### Common options

| Option | Purpose |
|--------|---------|
| `--file <path>` | Override target file. Skips path resolution. |
| `--project-root <path>` | Override `$PROJECT_ROOT` for path resolution. |
| `--scope project\|global` | For `path` subcommand; `project` is default. |
| `--quiet` | Suppress non-error stderr. |

### Key path syntax

Dotted path into the YAML document:

- `project.name`
- `integrations.jira.sync-phases`
- `integrations.jira.transitions.phase-started`

List indexing uses `[N]`: `integrations.architect.doc-sources[0].type`.

### Value parsing for `set`

Values are parsed as YAML scalars so these all work:

- `set project.base-branch main` → string `main`
- `set integrations.jira.sync-phases true` → bool `true`
- `set models.low haiku` → string `haiku`
- `set integrations.assistant.default-tags '[work, ai]'` → list

Use `--raw-string` to force string interpretation.

## Path resolution (when `--file` omitted)

Order — first hit wins:

1. `$AI_GARAGE_CONFIG` env var (absolute path).
2. `$PROJECT_ROOT/.ai-dev-garage/project-config.yaml` (current canonical project path).
3. Global: `~/.ai-dev-garage/config.yaml` (when `--scope global` or no project root).
4. Legacy fallback (read-only; emits a deprecation warning to stderr on hit):
   - `~/.config/ai-garage/config.yaml`
   - `$PROJECT_ROOT/.ai-dev-garage/config.yaml` (filename variant)

Writes always target the current canonical path (never the legacy fallback).

## Merge semantics (`merge-fragment`)

Deep merge with **base-wins** semantics: values already in the target file are preserved; the fragment only adds keys that are missing. This keeps plugin/template re-seeding idempotent — users who customized a value will not have it overwritten by a later template bump.

- Dicts merge recursively.
- Lists are replaced wholesale only if the key is missing in the base; if the base already has a list, the base list wins.
- `null` in base is treated as "missing" so the fragment value takes effect.

If a caller wants *overlay-wins* semantics (fragment clobbers base), they should script a sequence of explicit `set` calls instead.

## Atomic write

The helper writes to `<target>.tmp`, fsyncs, then renames over `<target>`. No partial files on crash.

## Comment + unknown-key preservation

The helper uses `ruamel.yaml` when available (preserves comments on round-trip) and falls back to `PyYAML` otherwise. On `PyYAML` fallback, a one-time stderr warning is printed; comments in the target file may be reformatted.

## Schema validation

`validate` runs the rules below. Callers read the returned JSON and surface errors.

| Key | Rule |
|-----|------|
| `project.name` | non-empty string |
| `project.stack` | list of lowercase identifiers |
| `project.docs-path` | path exists on disk (if non-null) |
| `project.build-command` | non-empty string |
| `project.test-command` | non-empty string |
| `project.base-branch` | non-empty string |
| `project.branch-prefix` | non-empty string |
| `models.low` / `medium` / `high` | one of `haiku`, `sonnet`, `opus`, `inherit`, or model ID |
| `integrations.jira.base-url` | starts with `https://` (if non-null) |
| `integrations.jira.sync-phases` | boolean |
| `integrations.jira.transitions.*` | string or null |
| `integrations.assistant.notion-database-id` | non-empty string (if non-null) |

## Dependencies

- Python 3.8+ (ships with macOS and most Linux distros).
- `ruamel.yaml` (preferred) or `PyYAML`. The helper probes both at import time.

If neither is installed, the helper prints an actionable install hint on stderr:
`pip install ruamel.yaml` (preferred) or `pip install pyyaml`.
