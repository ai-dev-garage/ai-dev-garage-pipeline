---
name: pipeline-manifest-version
description: Bump semver in core or extension component manifest.yaml inside the pipeline repo checkout. Use after shipping pipeline changes so garage install/update records the new version in the user master manifest. Not for ~/.ai-dev-garage custom registration.
argument-hint: COMPONENT core|<extension-id>, BUMP patch|minor|major|1.x.y, PIPELINE_REPO_ROOT
---

# Pipeline manifest version (component semver)

## When to use

- After you change **shipped** files under **`core/`** or **`extensions/<id>/`** in the **pipeline repo** and want **`garage update`** to write a new **`core.version`** or **`extensions.<id>.version`** into **`~/.ai-dev-garage/manifest.yaml`** (or project bundle).
- **Not** for registering user-owned runtime files — use **bundle-custom-manifest** / **`garage custom`** for **`custom:`** instead.
- **Not** for hand-editing the **master** manifest on disk; the installer overwrites those version fields from component manifests on the next **`garage install`** / **`garage update`**.

## Input (caller must pass)

- **`PIPELINE_REPO_ROOT`** — Absolute path to the **ai-dev-garage-pipeline** checkout (`AI_DEV_GARAGE`).
- **`COMPONENT`** — `core` or an extension directory name under **`extensions/`** (must match **`extensions/<id>/manifest.yaml`**).
- **`BUMP`** — One of **`patch`**, **`minor`**, **`major`**, or an explicit semver string (e.g. **`1.2.0`**).

Optional: **`REASON`** — one line for the commit message or changelog.

## Instructions

1. Resolve the component directory: **`$PIPELINE_REPO_ROOT/core`** or **`$PIPELINE_REPO_ROOT/extensions/<id>`**. Confirm **`manifest.yaml`** exists.
2. Read the current **`version`** using the repo’s **`manifest.py get-version`** (see **[references/REFERENCE.md](references/REFERENCE.md)**) — do not guess.
3. If **`BUMP`** is an explicit semver, validate **`MAJOR.MINOR.PATCH`** (digits only for each part) and use it as the new version. Otherwise compute the next version from the current one per **REFERENCE** (patch / minor / major).
4. Show **`version:`** before → after and the single-line edit in **`manifest.yaml`**. Do not change **`name`** or **`description`** unless the user asked.
5. Apply the edit only after the user confirms.
6. Tell the user: after this change is in their checkout, run **`garage update`** (or **`garage install --force`** as they prefer) so **`~/.ai-dev-garage/manifest.yaml`** picks up the new numbers from **`get-version`**.

## Rules

- Default mapping **patch / minor / major** → see **REFERENCE** (“When to bump patch vs minor vs major”): **patch** for edits to existing shipped files; **minor** for new agents/commands/rules/memory files or new skill folders; **major** for removals/renames or other breaking contract changes.
- Bump **each** component you actually changed; extensions are versioned independently from **core**.
- Pre-release labels (**`1.0.0-beta.1`**) are allowed only if the user explicitly asks; default to simple **`x.y.z`**.
- Do **not** run **bundle-custom-manifest** as part of this flow.

## Output

- Clear before/after version and file path edited.
- Reminder to **`garage update`** for local runtime alignment.
