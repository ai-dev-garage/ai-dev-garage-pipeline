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

### 1. Resolve API base URL and token

Build **`JIRA_BASE_URL`** (no trailing slash) and **`JIRA_API_TOKEN`** by **overlay** (later steps override earlier ones for each field independently). See **[REFERENCE.md — Credential precedence](references/REFERENCE.md)**.

1. Read **`~/.config/ai-garage/jira.env`** (`KEY=value` lines; skip `#` comments). Users can create it by copying **`jira.template.env`** from **`${CLAUDE_PLUGIN_ROOT}/`** in the pipeline repo.
2. If **`PROJECT_ROOT`** is set, read **`{PROJECT_ROOT}/.config/ai-garage/jira.env`** the same way (overrides global file for keys it defines).
3. Apply **process environment**: `JIRA_BASE_URL`, `JIRA_API_TOKEN`; use **`ATLASSIAN_API_TOKEN`** only if `JIRA_API_TOKEN` is unset.
4. Apply **caller-supplied** `jira-base-url` / `jira-api-token` when non-empty (wins over files and env).

**Do not** ask the user to paste the API token into chat. If either value is still missing after this pass, stop and use the **“When credentials are missing”** reply from **[REFERENCE.md](references/REFERENCE.md)**.

### 2. Extract the ticket key

Extract the ticket key from URL or raw input using pattern `[A-Za-z]+-\d+`. Uppercase the result.

### 3. Fetch ticket details

Set shell variables `JIRA_BASE_URL`, `TOKEN` (from resolved API token), and `KEY`, then run the **`curl`** command in **[REFERENCE.md — Fetch single issue](references/REFERENCE.md)**.

Handle errors:

- **401/403:** Token invalid or expired — point user to **[REFERENCE.md — Setup](references/REFERENCE.md)** (rotate token, check env file).
- **404:** Ticket not found — verify the key.
- **Other:** Report HTTP status and response body.

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
