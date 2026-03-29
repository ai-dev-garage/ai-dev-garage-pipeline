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

**Version bumps are manual.** When you change shipped assets or behavior in **core** or an **extension**, edit that component’s `manifest.yaml` and increment `version` so `garage update` records the new value in the master manifest. Install scripts do not infer versions from git or file hashes. In-repo helper: **`skills/pipeline-manifest-version/SKILL.md`**.

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
| `custom` | object | Optional. User-declared assets **not** from core or extensions; preserved when the master manifest is rewritten (`write-master`). Used by **`garage doctor`** and optional tooling. |

### `custom` shape

Each key is a category; values are **lists of strings** (basenames for flat categories; for **skills**, the **top-level folder name** only).

| Key | Meaning |
|-----|---------|
| `agents` | Agent filenames (e.g. `my-agent.md`). |
| `commands` | Command filenames (e.g. `my-command.md` or `ai-dev-garage/foo.md`). |
| `skills` | Skill **directory** names under `skills/` (not nested paths). |
| `rules` | Rule filenames (`.md` or `.mdc`). |
| `memory` | Memory filenames. |

Populate with **`garage custom add --category … --entry …`** (or **`--project <path>`** for project bundles). **`garage custom list`** / **`remove`** round out the flow.

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
  dev-workflow:
    version: "1.1.0"
    locked: false

custom:
  agents: []
  commands: []
  skills: []
  rules: []
  memory: []
```

### Lock behaviour

- `garage lock core` / `garage lock agile` — set `locked: true`, preventing updates to that component.
- `garage unlock core` — set `locked: false`, allowing updates again.
- Lock state is preserved across `garage update` and `garage install` runs.
