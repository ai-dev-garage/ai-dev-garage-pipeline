# Publish changes — reference

## Commit message format

```
{TASK-KEY}: <imperative description>
```

- Use imperative mood ("Add", "Fix", "Refactor", not "Added", "Fixes").
- Keep the first line under 72 characters.
- Optional body after a blank line for longer explanations.

## Commit size targets

| Total lines changed | Recommendation |
|---|---|
| 0 | Nothing to commit |
| 1-500 | Single commit |
| 501-1000 | Consider 2 commits (~500 lines each) |
| 1000+ | Split into multiple commits (300-500 lines each) |

## Layering order for commit splits

When splitting, prefer this order:

1. Data models / types / schemas
2. Business logic / services
3. API contracts / handlers
4. Tests

## Base branch convention

The base branch for rebasing comes from `project.base-branch` in project config (default: `main`).

## Sync with upstream

Substitute your `base-branch` (e.g. `main`). Run from the project git root:

```bash
git fetch origin
git rebase "origin/${base-branch}"
```

## Analyze changes

`TARGET_SKILL_DIR` is the directory containing this skill’s `SKILL.md`. Run from the project git root:

```bash
bash "${TARGET_SKILL_DIR}/scripts/analyze-changes.sh" "origin/${base-branch}"
```

## Push

```bash
git push -u origin HEAD
```

## Conflict policy

- If rebase produces conflicts, stop and report to the user.
- Never auto-resolve merge conflicts.
- Never force-push without explicit user confirmation.

## analyze-changes.sh output

The script prints:

- **Case A:** Feature commits exist locally — recommends soft reset to recommit cleanly.
- **Case B:** Only uncommitted changes — proceed directly to staging.
- Per-file line counts (staged and unstaged).
- Total lines changed and split recommendation.

## Files to never stage

- Build outputs (`target/`, `dist/`, `build/`, `node_modules/`)
- Generated sources
- IDE metadata (`.idea/`, `.vscode/`, `*.iml`)
- Environment files (`.env`, `.env.local`)
- OS files (`.DS_Store`, `Thumbs.db`)
