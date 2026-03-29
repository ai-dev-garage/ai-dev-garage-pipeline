# pipeline-manifest-version — reference

## Read current version (from repo root)

Component path is the directory that **contains** `manifest.yaml` (`core/` or `extensions/<id>/`).

```bash
python3 scripts/internal/manifest.py get-version --component-path core
python3 scripts/internal/manifest.py get-version --component-path extensions/agile
```

Run with `AI_DEV_GARAGE` / repo root as cwd, or pass absolute `--component-path`.

**Independent versions:** **`core`** and each **`extensions/<id>`** have their own **`manifest.yaml`**. Bump only the component(s) you changed. It is normal for the master manifest to show e.g. **core `1.1.0`** and **agile `1.0.0`** after `garage update`—do not align extension semver to core “just because.”

## When to bump patch vs minor vs major (Garage convention)

These are **defaults** for **`core/`** and **`extensions/<id>/`**; use judgment when something spans categories.

| Level | Typical trigger |
|-------|-----------------|
| **patch** | **Update-style** changes to **existing** shipped files: fixes, typos, clarifications, small workflow tweaks, dependency text, non-breaking refactors. No **new** top-level agent/command/rule/memory file and no **new** skill **folder** under **`skills/`**. |
| **minor** | **New** shipped asset: new **`.md`** under **`agents/`**, **`commands/`**, **`rules/`**, **`memory/`**, or a **new** skill directory under **`skills/`**; or additive behavior that does **not** remove/rename public entrypoints. |
| **major** | **Breaking** change for consumers of that component: **removing** or **renaming** a shipped file or skill folder users reference by path/name; changing a **slash command** name or frontmatter **`name`** in a way that breaks existing invocations; incompatible redesign (“old flow no longer valid”). |

**Gray areas:** A large rewrite of an existing agent/skill might still be **patch** if names and entrypoints stay the same; if you intentionally break compatibility or delete assets, prefer **major**. If you only **rename**, treat as **major** (or ship **remove + add** with a major if you want one semver step).

## Semver bump (MAJOR.MINOR.PATCH)

Assume current **`A.B.C`** (non-negative integers).

| BUMP  | New version   |
|-------|---------------|
| patch | `A.B.(C+1)`   |
| minor | `A.(B+1).0`   |
| major | `(A+1).0.0`   |

If **`C`**, **`B`**, or **`A`** is missing, treat missing parts as **`0`** before incrementing.

## Explicit version

If the user passes **`BUMP=1.2.3`**, set **`version:`** to that string exactly (after validating three numeric segments).

## Master manifest alignment

`~/.ai-dev-garage/manifest.yaml` (and project `.ai-dev-garage/manifest.yaml`) get **`core.version`** and **`extensions.<id>.version`** from these component files when the user runs **`garage update`** or **`garage install`** against a checkout that contains the bumped YAML. No separate sync step beyond running **`garage`**.

## UNTRACKED runtime files (separate concern)

Leftover files under **`~/.ai-dev-garage/...`** (e.g. old prefixed extension copies) are not fixed by bumping versions. After update, use **`garage doctor`** and, when satisfied, **`garage doctor --fix`** or manual deletes — see **README** (Custom assets and doctor).
