---
name: change-publisher
description: Analyze branch changes, split into logical commits, sync with upstream, and push. Use when the user asks to commit, push, publish, or save changes.
argument-hint: TASK-KEY (optional, extracted from branch name if omitted)
---

# Change publisher

## When to use

- User asks to commit, push, publish, or save their changes.
- Called by `deliver-task` or `implement-task` at the end of a phase or task.

## Instructions

### 1. Validate the build

Run the caller-provided `build-command` before staging anything.

Stop and report if the build fails.

### 2. Sync with upstream

Use the caller-provided `base-branch`. Run the **git fetch + rebase** commands in **[REFERENCE.md — Sync with upstream](references/REFERENCE.md)** (substitute `base-branch`). If conflicts occur, report to the user and pause. See REFERENCE for conflict policy.

### 3. Analyze changes

Run **`scripts/analyze-changes.sh`** from this skill’s directory against `origin/<base-branch>` — exact invocation in **[REFERENCE.md — Analyze changes](references/REFERENCE.md)**.

The script identifies whether commits exist (Case A: soft reset needed) or only uncommitted changes (Case B). See REFERENCE for output interpretation.

If Case A, run the soft-reset command printed by the script, then re-run it.

### 4. Propose a commit split

Using the script output, group files into logical commits:

- Target 300-500 lines per commit; allow up to 1000 when tightly coupled.
- Group by layer: data -> logic -> API -> tests.
- Present the proposed split and ask user to confirm/adjust.

### 5. Commit

For each agreed group:

1. Stage only that group's files. Never stage build outputs, generated sources, or IDE metadata.
2. Commit with format: `{TASK-KEY}: <imperative description>`

### 6. Push

Push to the remote using the command in **[REFERENCE.md — Push](references/REFERENCE.md)**.

If a soft reset was performed (Case A), the remote needs a force push. Confirm with the user before force-pushing.

Report the pushed branch and latest commit SHA.

## Input

- `TASK-KEY` (optional) — extracted from branch name if not provided.
- `PROJECT_ROOT` — resolved project root path.
- `build-command` — project's configured build command.
- `base-branch` — base branch name (default: `main`).

## Output

- List of commits created with SHAs.
- Pushed branch name.

## Rules

- Build must pass before committing.
- Never stage secrets, build outputs, or IDE metadata.
- Confirm with user before force-pushing.
- Commit message format and conflict policy: see [REFERENCE.md](references/REFERENCE.md).
