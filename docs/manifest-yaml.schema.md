# manifest.yaml schema

Used in three locations — `core/`, `extensions/<id>/`, and the installed runtime — each with the same field structure.

## Component manifest (core/ and extensions/<id>/)

Describes a bundle component (core or extension) in the pipeline repo.

### Required fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Component ID; for extensions must match the directory name and the key in `garage.yaml`. |
| `version` | string | Semver string (e.g. `1.0.0`). Read at install/update time to populate the master manifest. |
| `description` | string | One-line summary for humans and AI agents. |

### Example

```yaml
name: agile
version: 1.0.0
description: Agile backlog management — define and plan features, epics, and stories.
```

---

## Master manifest (~/.ai-dev-garage/manifest.yaml or <project>/.ai-dev-garage/manifest.yaml)

Written by `garage install` / `garage update`. Tracks what is installed and at what version.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `pipeline_repo` | string | Absolute path to the pipeline repo used for install. |
| `installed_at` | string | ISO 8601 timestamp of first install. Never updated after initial write. |
| `updated_at` | string | ISO 8601 timestamp of last install or update. |
| `core.version` | string | Installed version of core. |
| `core.locked` | bool | If `true`, `garage update` will not overwrite core assets. |
| `extensions.<name>.version` | string | Installed version of the extension. |
| `extensions.<name>.locked` | bool | If `true`, `garage update` will not overwrite this extension's assets. |

### Example

```yaml
pipeline_repo: /Users/alice/projects/ai-dev-garage-pipeline
installed_at: "2026-03-28T10:00:00Z"
updated_at: "2026-03-28T14:30:00Z"

core:
  version: "1.0.0"
  locked: false

extensions:
  agile:
    version: "1.0.0"
    locked: false
  dev-common:
    version: "1.0.0"
    locked: true
```

### Lock behaviour

- `garage lock core` / `garage lock agile` — set `locked: true`, preventing updates to that component.
- `garage unlock core` — set `locked: false`, allowing updates again.
- Lock state is preserved across `garage update` and `garage install` runs.
