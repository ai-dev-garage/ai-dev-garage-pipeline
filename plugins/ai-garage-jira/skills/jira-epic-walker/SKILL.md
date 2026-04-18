---
name: jira-epic-walker
description: Walk a Jira epic — fetch the epic plus its child stories ordered by rank with status, priority, and blocks/blocked-by links, and surface deterministic next-story candidates by filtering on status and unblocked dependency graph. Resolves credentials from environment or local env files — does not prompt for secrets.
argument-hint: Jira epic key or URL (e.g. AISD-1) [--include-done] [--json]
---

# Jira epic walker

## When to use

- **End user** asks a "what's next on this epic?" question, or pastes an epic key / URL and wants an overview of its children.
- **A planning agent** (e.g. `plan-epic`, `deliver-task`) needs the ordered child list plus a shortlist of unblocked, not-yet-done stories.
- A reviewer wants a single view of an epic's current progress: which children are done, which are in flight, which are gated by something else.

Stop at fetching and normalizing — do not transition, assign, or edit tickets here. For single-issue detail use `jira-item-fetcher`; for sub-task creation and transitions use `jira-phase-sync`.

## Instructions

### 1. Resolve API credentials

Build `JIRA_BASE_URL`, `JIRA_API_TOKEN`, and `JIRA_USER_EMAIL` by overlay. See **[REFERENCE.md — Credential precedence](references/REFERENCE.md)**. Do not ask the user to paste the token into chat. If credentials are missing after the overlay pass, stop and use the "When credentials are missing" reply in the reference.

### 2. Extract the epic key

Extract the first Jira key matching `[A-Za-z]+-\d+` from the argument and uppercase it. If nothing matches, stop and ask the user for a valid key or URL.

### 3. Fetch the epic tree

Run `scripts/fetch_epic_tree.py <KEY>` with any of the optional flags passed through from the user:

- `--include-done` keeps done/closed children in the children table and considers them when picking candidates.
- `--top N` changes the number of next candidates returned (default `3`).
- `--jira-base-url` / `--jira-api-token` override credentials already resolved upstream.
- `--project-root <path>` enables project-level env file lookup.

The script emits JSON on stdout and exits non-zero on error. Exit code meanings are listed in **[REFERENCE.md — Script contract](references/REFERENCE.md)**.

### 4. Render the result

Default response is markdown. Use the **[REFERENCE.md — Output template](references/REFERENCE.md)** shape: an epic header table, a children table ordered by Jira rank ascending, and a "Next candidates" list with one rationale line per entry. Omit null/empty rows.

If the caller passed `--json`, forward the script's JSON output unchanged instead of rendering the template.

## Input

- Jira epic key or URL (required).
- Optional: `--include-done`, `--json`, `--top <N>`.
- Optional: `PROJECT_ROOT`, `jira-base-url`, `jira-api-token` — same contract as `jira-item-fetcher`.

## Output

- Markdown (default): epic header + children table + next candidates.
- JSON (with `--json`): see **[REFERENCE.md — JSON shape](references/REFERENCE.md)**.

## Rules

- Requires network access for the Jira REST API.
- Never print or persist the API token in chat logs, tickets, or committed files.
- The candidate algorithm is deterministic (status + blocks graph + rank). Do not let the LLM "recommend" outside that output — if the user wants a different ranking, adjust inputs (e.g. `--include-done`, `--top`) or explain what the determined shortlist excludes.

## Related

- `jira-item-fetcher` — single-issue detail fetch; shares the same credential overlay.
- `jira-phase-sync` — mutates Jira state (sub-tasks, transitions); this skill is read-only.
- Follow-up: extract the credential overlay into a plugin-level `scripts/jira_creds.py` shared with `jira-item-fetcher` once both skills exercise it in production.
