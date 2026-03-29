# garage.yaml schema

Root file in the pipeline repo; copied to `~/.ai-dev-garage/garage.yaml` on global install.

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `version` | string | Config format version (e.g. `"1.0"`). |
| `extensions` | map | Keys are extension IDs (must match `extensions/<id>/` directory name). Values are objects with `enabled: true|false`. |

## Example

```yaml
version: "1.0"

extensions:
  agile:
    enabled: true
  dev-workflow:
    enabled: true
  telegram:
    enabled: false
```

Only extensions with `enabled: true` are merged into `~/.ai-dev-garage/` during install.

## Notes

- Extension metadata (name, version, description) lives in `extensions/<id>/manifest.yaml`, not here.
- To install only specific extensions: `garage install --ext agile,dev-workflow`.
- The installed runtime state is tracked in `~/.ai-dev-garage/manifest.yaml` (the master manifest), not in this file.
