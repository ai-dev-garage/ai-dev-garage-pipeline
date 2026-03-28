# AI Dev Garage — pipeline

Portable **filesystem** AI workflow runtime for **Cursor** and **Claude Code**: agents, commands, skills, rules, and memory under one install tree, shared via symlinks.

## Repo layout

| Path | Purpose |
|------|---------|
| `core/` | Runtime agents, commands, skills, rules, memory |
| `extensions/` | Optional extensions (`manifest.yaml` + assets); install with `garage install --ext <id>` |
| `scripts/` | `garage.sh`, `banner.sh`, `internal/*.sh`, `internal/manifest.py` |
| `docs/` | Schemas for `garage.yaml` and `manifest.yaml` |
| `garage.yaml` | Extension catalog (hints); copied to `~/.ai-dev-garage/` — does not auto-install |

## Prerequisites

- **Python 3** with **PyYAML** (`pip3 install pyyaml` or your OS package manager)
- **Git** (optional; `garage` tries to pull the latest pipeline before install/update)
- **zsh** recommended (first global install appends `AI_DEV_GARAGE` + `garage` alias to `~/.zshrc`)

## Install `garage` on your machine

1. **Clone or copy** this repo to a stable path (e.g. `~/projects/ai-dev-garage-pipeline`).

2. **Run a global install** — by default this installs **core only** (agents, commands, skills, rules, memory from `core/`) into `~/.ai-dev-garage`, symlinks `~/.cursor` and `~/.claude`, and writes `~/.ai-dev-garage/manifest.yaml`. **Extensions are opt-in.**

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

   **Add extensions** when you want them (comma-separated):

   ```bash
   garage install --ext agile
   garage install --ext agile,dev-common
   ```

   **`garage update`** refreshes core and any extensions already recorded in your manifest (respects locks). Browse IDs under `extensions/` in the repo or `~/.ai-dev-garage/garage.yaml` after install.

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

## Install vs update vs adding extensions

- **`garage install` (global)** — Copies **core** into `~/.ai-dev-garage` by default. Extensions are **not** taken from `garage.yaml` automatically; you pass them explicitly, e.g. `garage install --ext agile` or `garage install --ext agile,dev-common`. The master manifest (`~/.ai-dev-garage/manifest.yaml`) lists which extension IDs are installed.

- **`garage update` (global)** — Re-copies **core** and **only extensions that are already listed** in that master manifest (skips locked components). It does **not** install new extension IDs you never asked for. If you see `agile` / `dev-common` during update, they were already recorded from a previous `garage install --ext ...`.

- **Adding another extension later** — Run `garage install --ext <newid>` (or comma-separated list). Existing manifest rows for other extensions are **preserved**; the new ID is merged in and its files are copied.

- **Project installs** — Same idea: `--ext` selects extensions; project `manifest.yaml` tracks what is installed; `garage update --project <path>` refreshes what was already recorded for that project.

## Project overrides

```bash
garage install --project /path/to/project --core --ext agile
```

Creates `project/.ai-dev-garage/` and symlinks `project/.cursor` / `project/.claude` (interactive prompts if those dirs already have content).

## Core flow

1. **classifier** → **planner** → **executor** → **reviewer** → **summarizer** (see `core/agents/`).
2. Entry commands: `/plan`, `/execute`, `/summarize`, `/reflect`, `/ship` (see `core/commands/`).
3. Always-on rule: `core/rules/garage-runtime.md` (installed to `~/.ai-dev-garage/rules/`).

## Extensions (pipeline authors)

- Add `extensions/<id>/manifest.yaml` and assets under this repo.
- Optional: document the ID under `garage.yaml` (catalog hints; does not auto-install).
- Users install with `garage install --ext <id>`. Installed files are **flat** with `<name>-` prefixes for extension assets.

See [docs/manifest-yaml.schema.md](docs/manifest-yaml.schema.md) and [docs/garage-yaml.schema.md](docs/garage-yaml.schema.md).

## Verify (symlinks)

```bash
./scripts/verify-install.sh
```

Uses a temporary `HOME` and checks that Cursor/Claude paths symlink to the runtime and core files exist.

## License

MIT — see [LICENSE](LICENSE).
