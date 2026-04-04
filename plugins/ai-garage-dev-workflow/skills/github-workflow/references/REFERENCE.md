# GitHub workflow — reference

## Conventional Commits format

```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

**Types:**

| Type | When to use |
|---|---|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or updating tests |
| `docs` | Documentation only |
| `chore` | Build process, dependency updates, tooling |
| `perf` | Performance improvement |
| `ci` | CI/CD configuration |

**Rules:**
- Subject: imperative mood, no period, under 72 characters
- Body: explain *what* and *why*, not *how*; wrap at 72 characters
- Breaking change: add `!` after type/scope (`feat!:`) and/or `BREAKING CHANGE:` footer
- Co-author: `Co-Authored-By: Name <email>`

---

## PR body template

```markdown
## Summary
- <bullet: what changed and why>
- <bullet: key design decision if non-obvious>

## Test plan
- [ ] <how to verify the primary change>
- [ ] <edge cases checked>

## Notes
<optional: migration steps, follow-up tickets, known limitations>
```

**Title format:** `<type>(<scope>): <short imperative description>` — mirrors the commit convention.

---

## PR review checklist

| Area | What to check |
|---|---|
| **Scope** | Does every change in the diff relate to the PR's stated purpose? Flag unrelated changes as `[BLOCKING]` |
| **Size** | Is the PR small enough to review meaningfully? >500 lines of logic (not generated/config) is a flag |
| **Tests** | New behaviour has tests; changed behaviour has updated tests; deleted behaviour has tests removed |
| **Commit hygiene** | Commits are atomic; no "WIP", "fix fix", "oops" commits that should be squashed before merge |
| **Description** | Title is clear; body explains context; a reviewer can understand the change without asking |
| **Design** | Use `code-quality-review` skill for design-level findings; do not duplicate here |

**Comment prefixes:**
- `[BLOCKING]` — must be resolved before merge
- `[NIT]` — minor style or preference, take it or leave it
- `[SUGGESTION]` — improvement worth considering, non-blocking
- `[QUESTION]` — needs clarification before reviewer can decide

---

## Branch sync decision tree

```
Is the branch shared with other developers?
├── Yes → merge (git merge origin/<base>), never rebase
└── No (personal feature branch)
    ├── Has the branch been pushed and reviewed already?
    │   ├── Yes → merge or rebase carefully; communicate with reviewers
    │   └── No → rebase freely (git rebase origin/<base>)
    └── After rebase → force-push with lease only:
        git push --force-with-lease
```

**Never:** `git push --force` to `main`, `master`, `develop`, or any branch others have checked out.

---

## Common `gh` CLI commands

```bash
# Create PR (interactive)
gh pr create

# Create PR (non-interactive)
gh pr create --title "feat: add payment flow" --body "$(cat <<'EOF'
## Summary
- ...
EOF
)"

# Create draft PR
gh pr create --draft --title "..." --body "..."

# View PR
gh pr view <number>

# List changed files in a PR
gh pr diff <number> --name-only

# Checkout PR branch locally
gh pr checkout <number>

# Post a review comment
gh pr comment <number> --body "..."

# Submit a formal review
gh pr review <number> --approve
gh pr review <number> --request-changes --body "..."
gh pr review <number> --comment --body "..."

# Merge PR
gh pr merge <number> --squash --delete-branch
gh pr merge <number> --merge
gh pr merge <number> --rebase

# Sync fork/branch with upstream
git fetch origin
git rebase origin/main          # personal branch
git push --force-with-lease     # after rebase only
```
