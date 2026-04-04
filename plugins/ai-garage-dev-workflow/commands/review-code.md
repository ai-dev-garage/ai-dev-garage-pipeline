---
name: review-code
description: Review code quality — locally (file, directory) or from a GitHub PR. Applies paradigm-aware design quality checks and optionally posts findings as a PR comment.
---

User input:

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, print:

   **review-code** — Code quality review

   | Mode | Input | Example |
   |---|---|---|
   | Local | file path or directory | `src/services/UserService.ts` |
   | PR | GitHub PR URL or `owner/repo#123` | `github.com/org/repo/pull/42` or `org/repo#42` |

   Stop.

2. **Detect mode** from arguments:
   - Contains `github.com/…/pull/` or matches `owner/repo#N` pattern → **PR mode**
   - Otherwise → **Local mode**

3. **Local mode:**
   a. Resolve `PROJECT_ROOT` from `project=<path>` in arguments, or use current workspace root.
   b. Resolve target path(s) from arguments relative to `PROJECT_ROOT`.
   c. Resolve `project.stack` by reading `${PROJECT_ROOT}/.ai-dev-garage/config.yml` if present.
   d. Read `CONSTITUTION.md` from `PROJECT_ROOT` if present; extract architecture rules.
   e. Load `code-quality-review` skill from `${CLAUDE_PLUGIN_ROOT}/skills/code-quality-review/SKILL.md`.
   f. Apply the skill with: target path(s), `project.stack`, constitution rules.

4. **PR mode:**
   a. Parse the PR reference into `OWNER`, `REPO`, `PR_NUMBER`.
   b. Fetch PR metadata: `gh pr view <PR_NUMBER> --repo <OWNER>/<REPO> --json title,headRefName,baseRefName`
   c. Get the list of changed files: `gh pr diff <PR_NUMBER> --repo <OWNER>/<REPO> --name-only`
   d. Verify each changed file exists in the local working tree. If any are missing, stop and tell the user:
      > Some changed files are not present locally. Run `gh pr checkout <PR_NUMBER>` first, then re-run this command.
   e. Resolve `project.stack` and constitution rules as in local mode (steps 3c–3d).
   f. Load and apply the `code-quality-review` skill with: changed file paths, `project.stack`, constitution rules, PR title as additional context.
   g. Present the review report.
   h. Ask the user: **Post findings as a PR comment?** (yes / no)
   i. If yes: post via `gh pr comment <PR_NUMBER> --repo <OWNER>/<REPO> --body <report>`.
