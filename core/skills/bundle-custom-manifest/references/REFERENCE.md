# bundle-custom-manifest — reference

## `garage custom` CLI

Global manifest (default):

```bash
garage custom add    --category agents   --entry my-agent.md
garage custom add    --category skills   --entry my-skill-dir
garage custom add    --category commands --entry ai-dev-garage/my-command.md
garage custom add    --category memory   --entry my-memory.md
garage custom add    --category rules    --entry my-rule.md
garage custom remove --category agents   --entry my-agent.md
garage custom list
```

Project bundle:

```bash
garage custom add --category skills --entry my-skill --project /path/to/repo
```

Requires **`manifest.yaml`** at `$GARAGE_BUNDLE_ROOT/manifest.yaml`. If missing, run **`garage install`** (global or `--project`) first.

## Category → entry shape

| Category   | Entry value |
|------------|-------------|
| agents     | File basename: `foo.md` |
| rules      | `foo.md` or `foo.mdc` |
| memory     | `foo.md` |
| commands   | Top-level: `foo.md`. Under `ai-dev-garage/`: `ai-dev-garage/foo.md` |
| skills     | Top-level **directory** name under `skills/` (not a file path) |

## Rename

1. `garage custom remove --category <cat> --entry <old>`
2. Apply filesystem rename / new file writes.
3. `garage custom add --category <cat> --entry <new>`

## `garage doctor`

After installs or manual edits:

```bash
garage doctor
garage doctor --project /path/to/repo --strict
garage doctor --fix   # prompts before deleting UNTRACKED paths only
```

## Manifest preservation

`garage install` / `garage update` merge **`custom:`** from the existing manifest; they do not strip registered entries.
