---
name: github-workflow
description: Consolidated GitHub operations guide — commits, PR creation, PR review conventions, and branch sync. Use whenever an agent needs to create a commit, open a PR, review a PR, or sync a branch. Constitution overrides all defaults.
argument-hint: branch-strategy | commit | pr-create | pr-review | branch-sync
---

# GitHub workflow

## When to use

- Deciding whether to reuse the current branch or create a new one before any PR work.
- Committing changes (complement to `change-publisher` which handles analysis and splitting).
- Opening a PR after implementation is complete.
- Reviewing a PR as a human reviewer (not AI design analysis — see `code-quality-review` for that).
- Syncing a feature branch with its base branch.

## Instructions

### Mode 0 — Branch strategy

Run this before `pr-create` whenever there is an existing branch with prior PR history, or when the caller is unsure whether to reuse the current branch or start a new one.

1. Check if the current branch has an associated PR: `gh pr view --json number,state,mergedAt`.
2. Determine the branch path based on the result:

   **No PR exists** → stay on the current branch. Proceed to `pr-create` when ready.

   **PR is open** → stay on the current branch. New commits pushed to it will update the existing PR.

   **PR is merged** →
   a. Pull the latest base branch: `git fetch origin && git merge origin/<base>` on base (or `git pull origin <base>`).
   b. Create a new feature branch from the updated base: `git checkout -b <new-branch-name>`.
   c. Any uncommitted local changes carry over automatically. Staged or unstaged changes are preserved on the new branch.
   d. Proceed to `commit` then `pr-create` on the new branch.

3. Report the chosen path and the branch name to the caller before proceeding.

### Mode 1 — Commit

1. Check if the project constitution defines a commit message format. If so, use it. Otherwise default to Conventional Commits (see [REFERENCE.md](references/REFERENCE.md)).
2. Each commit must represent one atomic logical change. Do not bundle unrelated changes.
3. Write the subject line in the imperative mood, under 72 characters.
4. If the change needs explanation, add a blank line then a body (what and why, not how).
5. Run `git commit -m "..."` or use a heredoc for multi-line messages.

### Mode 2 — PR creation

1. Ensure the branch is synced with base (run Mode 4 first if needed).
2. Check if the project has a PR template at `.github/pull_request_template.md`. If present, use it as the body structure.
3. If no template, use the standard body structure from [REFERENCE.md](references/REFERENCE.md).
4. Set the PR title: `<type>: <short imperative description>` (same convention as commit subject).
5. Set metadata via `gh pr create` flags: `--reviewer`, `--label`, `--milestone`, `--project` — only if the values are known. Do not guess.
6. Open as draft (`--draft`) if implementation is not yet complete or tests are not passing.
7. Run `gh pr create --title "..." --body "..."`.

### Mode 3 — PR review

Review what the PR is doing, not just what the code looks like. Work through the checklist in [REFERENCE.md](references/REFERENCE.md):

1. **Scope** — does the PR match its stated purpose? Are there unrelated changes?
2. **Size** — is the PR reviewable? Flag if it should be split.
3. **Tests** — are new behaviours covered? Are existing tests updated where needed?
4. **Commit hygiene** — are commits atomic and well-described, or a mess of "fix" commits that should be squashed?
5. **Description** — does the PR body explain what changed and why? Would a reviewer understand the context without reading the code?
6. **Design** — for design-level findings, use `code-quality-review` skill separately; do not duplicate here.

Comment conventions:
- **Blocking:** prefix with `[BLOCKING]` — must be resolved before merge.
- **Non-blocking:** prefix with `[NIT]` or `[SUGGESTION]` — optional improvements.
- Praise good choices explicitly — it reinforces patterns.

### Mode 4 — Branch sync

1. Identify the base branch (`main`, `master`, or project-configured `base-branch`).
2. Fetch latest: `git fetch origin`.
3. **Rebase** onto base if the branch is a personal feature branch not shared with others: `git rebase origin/<base>`.
4. **Merge** (not rebase) if the branch is shared or if rebasing would rewrite public history.
5. Resolve conflicts locally. Do not push until all conflicts are resolved and build passes.
6. After rebase, force-push only to own feature branches: `git push --force-with-lease`.
7. Never force-push to base branch or any shared branch.

## Input

- **Mode** — one of: `branch-strategy`, `commit`, `pr-create`, `pr-review`, `branch-sync`.
- **Constitution rules** — project-specific conventions (optional; overrides all defaults when provided).
- **base-branch** — resolved by `project-config-resolver` (optional; defaults to `main`).

## Output

- Executed git/gh operation, or review comments structured per conventions above.

## Rules

- Constitution overrides all defaults in this skill.
- `gh` CLI is the tool for all GitHub API operations.
- Never force-push to base branch or shared branches.
- Never open a PR on an unsynced branch — always sync first.
- Do not set reviewers, labels, or milestones unless the values are explicitly known.

## More detail

- Conventional commits format, PR body template, review checklist, branch sync decision tree, `gh` CLI commands: [REFERENCE.md](references/REFERENCE.md)
