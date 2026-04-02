---
name: feature-branch-guard
description: Verify and switch to the correct feature branch for a task. Creates the branch if it does not exist. Use before any agent writes to the project repository.
argument-hint: TASK-KEY (e.g. PROJ-1234 or issue-42)
---

# Feature branch guard

## When to use

- Before any implementation phase begins writing code.
- Called by `deliver-task` or `implement-task` agents to guarantee the working branch matches the task.

## Instructions

### 1. Resolve branch pattern

Use the caller-provided `branch-prefix` and `base-branch` values.

- Branch name: `{branch-prefix}/{TASK-KEY}` (default: `feature/{TASK-KEY}`).
- Base branch: value of `base-branch` (default: `main`).

### 2. Fetch remote state

Run `git fetch origin` to sync remote branch information.

### 3. Check current branch

Run `git branch --show-current`.

- If already on the target branch, stop — nothing to do.

### 4. Stash uncommitted changes

Run `git status --porcelain`.

- If changes exist, run `git stash` and note that a pop is needed later.

### 5. Switch or create branch

Determine where the branch exists:

- Local: `git branch --list {branch-name}`
- Remote only: `git branch -r --list origin/{branch-name}`

Then:

- Local exists: `git checkout {branch-name}`
- Remote only: `git checkout --track origin/{branch-name}`
- Neither: `git checkout -b {branch-name}` from the base branch.

### 6. Restore stashed changes

If changes were stashed in step 4, run `git stash pop`.

### 7. Confirm

Report the current branch to the caller.

## Input

- `TASK-KEY` — the task identifier used in the branch name.
- `PROJECT_ROOT` — resolved project root path (for git operations).
- `branch-prefix` — branch name prefix (default: `feature`).
- `base-branch` — base branch name (default: `main`).

## Output

- Confirmation of the active branch name.

## Rules

- Never force-push or reset existing branches.
- If stash pop causes a conflict, report to the user and pause — do not auto-resolve.
- Branch pattern comes from caller-provided inputs; do not hardcode `feature/`.
