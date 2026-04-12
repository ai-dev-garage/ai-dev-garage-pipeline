---
name: jira-phase-sync
description: Create Jira sub-tasks for WBS phases and transition their statuses during delivery. Use when deliver-task needs to mirror phase progress on the Jira board. Requires sync-phases enabled in project config.
argument-hint: mode (create-subtasks | transition), parent key + phases or subtask key + event name
---

# Jira phase sync

## When to use

- **`deliver-task`** confirmed a WBS and `integrations.jira.sync-phases` is `true` — create sub-tasks for each phase.
- **`deliver-task`** changes a phase status (started, implemented, review, ready) — transition the corresponding sub-task.

## Instructions

### 1. Resolve API base URL and token

Build **`JIRA_BASE_URL`** (no trailing slash) and **`JIRA_API_TOKEN`** using the same overlay precedence as `jira-item-fetcher`. See **[REFERENCE.md — Credential precedence](references/REFERENCE.md)**.

1. Read **`~/.config/ai-garage/jira.env`** (`KEY=value` lines; skip `#` comments).
2. If **`PROJECT_ROOT`** is set, read **`{PROJECT_ROOT}/.config/ai-garage/jira.env`** (overrides global file for keys it defines).
3. Apply **process environment**: `JIRA_BASE_URL`, `JIRA_API_TOKEN`; use **`ATLASSIAN_API_TOKEN`** only if `JIRA_API_TOKEN` is unset.
4. Apply **caller-supplied** `jira-base-url` / `jira-api-token` when non-empty (wins over files and env).

If either value is still missing, warn the caller and return `{ success: false, error: "credentials missing" }`. Do **not** ask the user to paste the token.

### 2. Dispatch by mode

Accept a `mode` parameter: **`create-subtasks`** or **`transition`**.

---

### 3. Mode: `create-subtasks`

**Inputs:**
- `parent-key` — the Jira ticket key that sub-tasks are created under.
- `subtask-type` — the Jira issue type name (from config, default `"Sub-task"`).
- `phases` — list of `{ phase-key, title, items }` where `items` is a markdown bullet list of WBS items for the phase.

**For each phase:**

1. **Idempotency check:** If the caller indicates the phase already has a `[jira:KEY]` annotation, skip it.
2. **Build description** from the phase items. Use the WBS item text as the description body.
3. **Create the sub-task** using the `POST /rest/api/2/issue` endpoint — see **[REFERENCE.md — Create sub-task](references/REFERENCE.md)**.
4. **Extract** the created issue key from the response (`key` field).
5. On **error** (non-201 response): log a warning with the HTTP status and error message. Do not stop — continue to the next phase.

**Output:** A list of `{ phase-key, jira-key }` for successfully created sub-tasks, plus any warnings.

---

### 4. Mode: `transition`

**Inputs:**
- `subtask-key` — the Jira sub-task key (from the `[jira:KEY]` annotation).
- `target-status` — the Jira transition name to search for (from config `transitions.*` value).

**Steps:**

1. If `target-status` is `null` or empty, skip silently — return `{ success: true, skipped: true }`.
2. **Fetch available transitions** using `GET /rest/api/2/issue/{key}/transitions` — see **[REFERENCE.md — Get transitions](references/REFERENCE.md)**.
3. **Match** the `target-status` against available transition names using **case-insensitive substring** matching. For example, `"In Progress"` matches a transition named `"Start Progress"` or `"Move to In Progress"`.
4. If **no match found**: warn with the available transition names and return `{ success: false, warning: "no matching transition" }`. Do not fail the workflow.
5. If **match found**: execute the transition using `POST /rest/api/2/issue/{key}/transitions` — see **[REFERENCE.md — Execute transition](references/REFERENCE.md)**.
6. On **error** (non-204 response): log a warning. Do not fail the workflow.

**Output:** `{ success: true/false, warning?: string }`.

## Input

- `mode` — `create-subtasks` or `transition`.
- For `create-subtasks`: `parent-key`, `subtask-type`, `phases[]`.
- For `transition`: `subtask-key`, `target-status`.
- Optional: `PROJECT_ROOT`, `jira-base-url`, `jira-api-token` (caller overrides).

## Output

- Structured result with `success`, created keys or transition outcome, and any `warning`/`error` messages.

## Rules

- **Never block the workflow.** All Jira API failures emit warnings and return gracefully.
- **Never print or persist the API token** in chat, tickets, or committed files.
- **Idempotent on re-runs.** Phases with existing `[jira:KEY]` annotations are skipped in create mode. Transitions that are already past the target status may return "no matching transition" — that is expected and not an error.
- Credential resolution follows the same overlay as `jira-item-fetcher` — see [REFERENCE.md](references/REFERENCE.md).
