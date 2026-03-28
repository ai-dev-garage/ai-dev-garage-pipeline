# AI Dev Garage — pipeline

Portable **filesystem** AI workflow runtime for **Cursor** and **Claude Code**: agents, commands, skills, rules, and memory under one install tree, shared via symlinks.

## Repo layout

| Path | Purpose |
|------|---------|
| `core/` | Runtime agents, commands, skills, rules, memory |
| `extensions/` | Optional extensions (`manifest.yaml` + assets); enable in `garage.yaml` |
| `scripts/` | `garage.sh`, `banner.sh`, `internal/*.sh`, `internal/manifest.py` |
| `docs/` | Schemas for `garage.yaml` and `manifest.yaml` |
| `garage.yaml` | Which extensions are enabled |

## Prerequisites

- **Python 3** with **PyYAML** (`pip3 install pyyaml` or your OS package manager)
- **Git** (optional; `garage` tries to pull the latest pipeline before install/update)
- **zsh** recommended (first global install appends `AI_DEV_GARAGE` + `garage` alias to `~/.zshrc`)

## Install `garage` on your machine

1. **Clone or copy** this repo to a stable path (e.g. `~/projects/ai-dev-garage-pipeline`).

2. **Run a global install** (copies core + enabled extensions to `~/.ai-dev-garage`, symlinks `~/.cursor` and `~/.claude`, writes `~/.ai-dev-garage/manifest.yaml`):

   ```bash
   cd /path/to/ai-dev-garage-pipeline
   export AI_DEV_GARAGE="$(pwd)"
   bash scripts/internal/global-install.sh --force
   ```

   Or use the CLI (same effect; also syncs git when online):

   ```bash
   cd /path/to/ai-dev-garage-pipeline
   chmod +x scripts/garage.sh   # only if you see "permission denied"
   ./scripts/garage.sh install --force
   ```

   You can also run without execute bit: `bash scripts/garage.sh install --force`

3. **Add the `garage` command** so you can type `garage` in any terminal (pick one):

   - **Alias (recommended)** — points at `scripts/garage.sh` and sets `AI_DEV_GARAGE` to this repo’s root (replace `/path/to/ai-dev-garage-pipeline` with the real path, e.g. `~/projects/ai-dev-garage/ai-dev-garage-pipeline`):

     **zsh** (default on macOS; the first global install may append the same lines to `~/.zshrc`):

     ```bash
     echo 'export AI_DEV_GARAGE="/path/to/ai-dev-garage-pipeline"' >> ~/.zshrc
     echo 'alias garage="/path/to/ai-dev-garage-pipeline/scripts/garage.sh"' >> ~/.zshrc
     source ~/.zshrc
     ```

     **bash** — use `~/.bashrc` on Linux; on macOS Terminal often loads `~/.bash_profile` instead:

     ```bash
     echo 'export AI_DEV_GARAGE="/path/to/ai-dev-garage-pipeline"' >> ~/.bashrc
     echo 'alias garage="/path/to/ai-dev-garage-pipeline/scripts/garage.sh"' >> ~/.bashrc
     source ~/.bashrc
     ```

     After editing, **open a new terminal tab** or `source` the file you changed so the alias exists in that session. Check with `type garage` or `alias garage`.

   - **Or** invoke by path (no alias): `bash /path/to/ai-dev-garage-pipeline/scripts/garage.sh install` (or `chmod +x` that file and call it directly).

4. **Interactive menu** — run `garage` with no arguments in a terminal for the arrow-key menu; `garage install`, `garage status`, etc. run directly without the menu.

5. **Project install** (optional):

   ```bash
   garage install --project /path/to/your/repo --core --ext agile
   ```

## After install

- **Runtime:** `~/.ai-dev-garage/{agents,commands,skills,rules,memory}` + `manifest.yaml`
- **Cursor:** `~/.cursor/{agents,commands,skills,rules,memory}` → symlinks into the runtime
- **Claude Code:** `~/.claude/{agents,commands,skills,rules}` → same targets

Restart Cursor / Claude Code so they pick up the new paths.

## Project overrides

```bash
garage install --project /path/to/project --core --ext agile
```

Creates `project/.ai-dev-garage/` and symlinks `project/.cursor` / `project/.claude` (interactive prompts if those dirs already have content).

## Core flow

1. **classifier** → **planner** → **executor** → **reviewer** → **summarizer** (see `core/agents/`).
2. Entry commands: `/plan`, `/execute`, `/summarize`, `/reflect`, `/ship` (see `core/commands/`).
3. Always-on rule: `core/rules/garage-runtime.md` (installed to `~/.ai-dev-garage/rules/`).

## Extensions

- Add `extensions/<id>/manifest.yaml` and assets.
- Set `extensions.<id>.enabled: true` in `garage.yaml`.
- Re-run `garage install --force`. Installed files are **flat** with `<name>-` prefixes for extension assets.

See [docs/manifest-yaml.schema.md](docs/manifest-yaml.schema.md) and [docs/garage-yaml.schema.md](docs/garage-yaml.schema.md).

## Verify (symlinks)

```bash
./scripts/verify-install.sh
```

Uses a temporary `HOME` and checks that Cursor/Claude paths symlink to the runtime and core files exist.

## License

MIT — see [LICENSE](LICENSE).
