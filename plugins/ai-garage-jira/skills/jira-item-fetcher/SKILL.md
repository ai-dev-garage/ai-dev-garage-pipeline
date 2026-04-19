---
name: jira-item-fetcher
description: Fetch and display Jira ticket details via REST. Use on direct user requests (lookup URL/key) or when another agent needs issue JSON. Resolves URL and API token from caller, environment, or local env files — does not prompt for secrets.
argument-hint: Jira ticket key or URL (e.g. PROJ-1234)
---

# Jira item fetcher

## When to use

- **End user** asks to view, check, or look up a Jira ticket (slash command, chat, or paste of URL/key).
- **`jira-task-analysis`** or any other agent needs issue details or hierarchy (same skill; credentials resolve the same way).
- User provides a Jira URL or ticket key pattern.

## Instructions

### 1. Set up the Jira CLI

Set `JIRA_CLI=”${CLAUDE_PLUGIN_ROOT}/scripts/jira_cli.py”`. The script handles credential resolution internally through the same 4-layer overlay documented in **[REFERENCE.md — Credential precedence](references/REFERENCE.md)** (global env file → project env file → process environment → CLI args).

Always pass `--project-root “$PROJECT_ROOT”` when `PROJECT_ROOT` is set. If the caller supplied `jira-base-url` / `jira-api-token`, pass them as `--base-url` / `--token`. If the caller supplied `jira-user-email`, pass it as `--email`.

If the script exits with code **2** (credentials missing), read the `hint` field from the stderr JSON and surface it to the user as a one-liner. **Do not** ask the user to paste the API token into chat.

### 2. Extract the ticket key

Extract the ticket key from URL or raw input using pattern `[A-Za-z]+-\d+`. Uppercase the result.

### 3. Fetch ticket details

Run the CLI to fetch the ticket:

```bash
python3 "$JIRA_CLI" fetch "$KEY" --project-root "$PROJECT_ROOT"
```

For sibling tasks under a parent:

```bash
python3 "$JIRA_CLI" search --jql "parent=$PARENT_KEY ORDER BY created ASC" --fields "summary,status,issuetype,assignee" --project-root "$PROJECT_ROOT"
```

Parse the JSON output from stdout. Handle errors by exit code:

- **Exit 1 with `http_status: 401` or `403`:** Token invalid or expired — point user to **[REFERENCE.md — Setup](references/REFERENCE.md)** (rotate token, check env file).
- **Exit 1 with `http_status: 404`:** Ticket not found — verify the key.
- **Exit 1 (other):** Report the `error` and `http_status` from stderr JSON.
- **Exit 2:** Credentials missing — surface the `hint` from stderr JSON.

### 4. Present the summary

Format the response using the template in [REFERENCE.md](references/REFERENCE.md). Omit rows where the value is null.

## Input

- Jira ticket key or URL.
- Optional: `PROJECT_ROOT` — enables project-level `jira.env`.
- Optional: `jira-base-url`, `jira-api-token` — when the caller already resolved them (e.g. from project config).

## Output

- Formatted ticket summary (see reference for template).

## Rules

- Requires network access for the Jira REST API call.
- Never print or persist the API token in chat logs, tickets, or committed files.
- Prefer env and ignored env files over pasting secrets into prompts; full setup guide: **[references/REFERENCE.md](references/REFERENCE.md)**.
