---
name: bundle-custom-manifest
description: Register or unregister user-owned assets in the master manifest custom section after writes to a global or project Garage bundle. Use as the final step of /ai-dev-garage create-* / update-* when scope=global or scope=project. Outputs exact garage custom CLI for the executor.
argument-hint: MANIFEST_PATH, GARAGE_BUNDLE_ROOT, CUSTOM_CATEGORY, CUSTOM_ENTRY, ACTION add|remove
---

# Bundle custom manifest (register user assets)

## When to use

- After **global** or **project** bundle **writes** from `/ai-dev-garage:create-*` / `update-*` (or hand edits the user confirmed), so **`manifest custom:`** matches disk and **`garage doctor`** can classify untracked vs declared assets.
- When **removing** a user-owned asset, or around **rename** (remove old manifest entry, then add new—order in **[references/REFERENCE.md](references/REFERENCE.md)**).
- **Skip** master-manifest registration for **`extension:<name>`** pipeline targets (git is source of truth).

**manifest `custom:`** should reflect intentional user-owned paths only—do not hand-edit YAML in normal flow.

Load **[references/REFERENCE.md](references/REFERENCE.md)** for exact `garage custom` flags, category → entry shapes, rename steps, and **`garage doctor`** invocations.

## Input (caller must pass)

- **`MANIFEST_PATH`** — `$GARAGE_BUNDLE_ROOT/manifest.yaml` (global `~/.ai-dev-garage/manifest.yaml` or project `.ai-dev-garage/manifest.yaml`).
- **`GARAGE_BUNDLE_ROOT`** — Absolute bundle root (same as create/update commands).
- **`CUSTOM_CATEGORY`** — `agents` | `commands` | `skills` | `rules` | `memory`.
- **`CUSTOM_ENTRY`** — Basename for flat categories (e.g. `my-agent.md`). **Skills:** top-level folder name only. **Commands** under `commands/ai-dev-garage/`: use `ai-dev-garage/<basename>.md`.
- **`ACTION`** — `add` (after confirmed write) or `remove` (after delete or before rename; see REFERENCE).

Optional: **`ASSET_SCOPE`** — `global` | `project` | `extension:…` for messaging only.

## Scope rules

- **`global` / `project`:** After the user confirms **file writes** for the asset, run **add** (or **remove** when appropriate). Ensure the path exists on disk before **add** (`manifest.py` validates).
- **`extension:<name>`:** **Do not** update the user/project **master** manifest `custom:` for assets authored in the pipeline repo extension tree—source control is the authority. Skip this skill for master-manifest registration.

## Output

- Print the exact **`garage custom add`** or **`garage custom remove`** line for the executor: correct **`--category`**, **`--entry`**, and **`--project <path>`** when the bundle is project-scoped. Full examples and edge cases: **[references/REFERENCE.md](references/REFERENCE.md)**.
- Repeating **add** for the same entry is idempotent (safe no-op).

## Integration

**Create/update/review commands** that write to a global or project bundle should **chain this skill** as the **final step** after the asset standard skill (agent-standard, skill-standard, command-standard, rule-standard). **Review-only** runs skip registration unless the user **applies** changes to disk.

Only write agreed targets elsewhere; do **not** bulk-delete bundle directories from this skill.
