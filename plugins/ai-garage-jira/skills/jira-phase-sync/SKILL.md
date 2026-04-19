---
name: jira-phase-sync
description: Create Jira sub-tasks for WBS phases and transition their statuses during delivery. Use when deliver-task needs to mirror phase progress on the Jira board. Requires sync-phases enabled in project config.
argument-hint: mode (create-subtasks | transition | preflight-transitions), parent key + phases or subtask key + event name
---

# Jira phase sync

## When to use

- **`deliver-task`** confirmed a WBS and `integrations.jira.sync-phases` is `true` — create sub-tasks for each phase.
- **`deliver-task`** changes a phase status (started, implemented, review, ready) — transition the corresponding sub-task.
- **`deliver-task`** is about to enter Phase 3 and wants to validate configured transition names against the live Jira board — run `preflight-transitions` once.

## Instructions

### 1. Set up the Jira CLI

Set `JIRA_CLI="${CLAUDE_PLUGIN_ROOT}/scripts/jira_cli.py"`. The script handles credential resolution internally through the same 4-layer overlay documented in **[REFERENCE.md — Credential precedence](references/REFERENCE.md)** (global env file → project env file → process environment → CLI args).

Always pass `--project-root "$PROJECT_ROOT"` when `PROJECT_ROOT` is set. If the caller supplied `jira-base-url` / `jira-api-token`, pass them as `--base-url` / `--token`. If the caller supplied `jira-user-email`, pass it as `--email`.

If the script exits with code **2** (credentials missing), read the `hint` field from the stderr JSON and surface it to the user as a one-liner. Do **not** ask the user to paste the token.

### 2. Dispatch by mode

Accept a `mode` parameter: **`create-subtasks`**, **`transition`**, or **`preflight-transitions`**.

---

### 3. Mode: `create-subtasks`

**Inputs:**
- `parent-key` — the Jira ticket key that sub-tasks are created under.
- `subtask-type` — the Jira issue type name (from config, default `"Sub-task"`).
- `phases` — list of `{ phase-key, title, items }` where `items` is a markdown bullet list of WBS items for the phase.

**For each phase:**

1. **Idempotency check:** If the caller indicates the phase already has a `[jira:KEY]` annotation, skip it.
2. **Build description** from the phase items. Use the WBS item text as the description body.
3. **Create the sub-task** using the CLI:
   ```bash
   python3 "$JIRA_CLI" create-issue --project "$PROJECT_KEY" --parent "$PARENT_KEY" --summary "$SUMMARY" --description "$DESCRIPTION" --type "$SUBTASK_TYPE" --project-root "$PROJECT_ROOT"
   ```
4. **Extract** the created issue key from the response (`key` field).
5. On **error** (non-201 response): capture a one-line `user_message` of the form `Jira sub-task create failed for <phase-key>: HTTP <status> — <error>`. Do not stop — continue to the next phase.

**Output:** A list of `{ phase-key, jira-key }` for successfully created sub-tasks, plus any per-phase `user_message` warnings the caller must surface.

---

### 4. Mode: `preflight-transitions`

Runs **once per task** to validate the configured transition names against the live Jira board before the implementation loop starts. Collapses the per-call `GET /transitions` that the old flow made into one up-front call plus a cached mapping.

**Inputs:**
- `TASK-KEY` — the parent ticket key (used to locate the per-task state folder).
- `probe-subtask-key` — any sub-task key whose workflow matches the configured transitions (typically the first sub-task created in `create-subtasks` mode). One probe is sufficient because all sub-tasks of the same parent use the same workflow.
- `configured-transitions` — the map `{ phase-started, phase-implemented, review-started, phase-ready }` from `integrations.jira.transitions.*`.

**Steps:**

1. **Cache check.** If `.ai-dev-garage/.workflow-state-tmp/{TASK-KEY}/jira-transitions.json` exists, read it and return `{ success: true, cached: true, mapping: <contents> }`. The caller does not re-prompt.
2. **Fetch available transitions** — **exactly one** API call for the whole task:
   ```bash
   python3 "$JIRA_CLI" get-transitions "$PROBE_SUBTASK_KEY" --project-root "$PROJECT_ROOT"
   ```
3. **Match** each configured name against the board's transitions using case-insensitive substring matching. Build a mapping record:

   ```json
   {
     "probed-at": "2026-04-18T12:00:00Z",
     "probe-subtask": "PROJ-456",
     "board-transitions": ["To Do", "In Progress", "To Review", "Done"],
     "mapping": {
       "phase-started": { "configured": "In Progress", "resolved-name": "In Progress", "resolved-id": "21" },
       "phase-implemented": { "configured": "Need Review", "resolved-name": null, "resolved-id": null, "mismatch": true },
       "review-started": { "configured": "In Review", "resolved-name": null, "resolved-id": null, "mismatch": true },
       "phase-ready": { "configured": "Ready", "resolved-name": null, "resolved-id": null, "mismatch": true }
     }
   }
   ```

4. **Mismatch handling.** If any entry has `mismatch: true`, return **without** writing the cache and emit a **single** user-visible block summarising the drift plus a proposed `config-merger` one-liner per missing entry. Example:

   ```
   Jira transition name mismatch — board workflow does not contain:
     - phase-implemented: configured "Need Review" — available names: To Do, In Progress, To Review, Done
     - review-started:    configured "In Review"   — available names: To Do, In Progress, To Review, Done
     - phase-ready:       configured "Ready"       — available names: To Do, In Progress, To Review, Done

   Suggested config updates (run once to repair):
     python3 <config-merger> set integrations.jira.transitions.phase-implemented "To Review"
     python3 <config-merger> set integrations.jira.transitions.review-started    "To Review"
     python3 <config-merger> set integrations.jira.transitions.phase-ready       "Done"

   This is the only interactive pause in the autonomous flow — fixing it now is cheaper than re-running N phases.
   ```

   The caller is expected to surface this block to the user and pause exactly once. After the user repairs the config (or accepts the suggestions), the caller re-invokes `preflight-transitions`, which now writes the cache and continues.

5. **Success.** When every configured name maps to a live transition, write the full mapping record to `.ai-dev-garage/.workflow-state-tmp/{TASK-KEY}/jira-transitions.json` (atomic write via temp-file + rename) and return `{ success: true, cached: false, mapping: <record> }`.

**Output:** `{ success: bool, cached: bool, mapping: <record>, mismatch?: bool, user_message?: string }`.

---

### 5. Mode: `transition`

**Inputs:**
- `TASK-KEY` — used to locate the cached mapping.
- `subtask-key` — the Jira sub-task key (from the `[jira:KEY]` annotation).
- `event` — one of `phase-started`, `phase-implemented`, `review-started`, `phase-ready` (the semantic event, not the board name).
- `target-status` — **optional fallback** if the cache is missing: the raw `integrations.jira.transitions.<event>` value, used to rebuild a preflight on the fly.

**Steps:**

1. If `event`'s configured `target-status` is `null` or empty (cache absent AND the fallback target is empty), skip silently — return `{ success: true, skipped: true }`.
2. **Cache-first resolution.** Read `.ai-dev-garage/.workflow-state-tmp/{TASK-KEY}/jira-transitions.json`. If present and the entry for `event` has a non-null `resolved-id`, proceed directly to step 5 using that id — **no `/transitions` GET**.
3. If the cache is missing for the event (e.g. first call for this task, or cache absent because the orchestrator skipped preflight), fall back to the legacy per-call flow:
   ```bash
   python3 "$JIRA_CLI" get-transitions "$SUBTASK_KEY" --project-root "$PROJECT_ROOT"
   ```
   Then case-insensitive substring match against `target-status`. Record that a fallback occurred in the work report so the next planner can see the cost.
4. If no match is found in either the cache or the fallback fetch: warn with the available transition names and return `{ success: false, warning: "no matching transition" }`. Do not fail the workflow.
5. **Execute** the transition:
   ```bash
   python3 "$JIRA_CLI" transition "$SUBTASK_KEY" --id "$TRANSITION_ID" --project-root "$PROJECT_ROOT"
   ```
6. On **error** (non-204 response): log a warning. Do not fail the workflow.

**Output:** `{ success: true/false, cache_hit: bool, warning?: string }`.

## Input

- `mode` — `create-subtasks`, `transition`, or `preflight-transitions`.
- For `create-subtasks`: `parent-key`, `subtask-type`, `phases[]`.
- For `transition`: `TASK-KEY`, `subtask-key`, `event`, optional `target-status` (fallback).
- For `preflight-transitions`: `TASK-KEY`, `probe-subtask-key`, `configured-transitions`.
- Optional: `PROJECT_ROOT`, `jira-base-url`, `jira-api-token` (caller overrides).

## Output

- Structured result with `success`, created keys or transition outcome, and any `warning`/`error` messages.

## Rules

- **Never block the workflow.** All Jira API failures emit warnings and return gracefully. The single permitted interactive pause is the transition-name mismatch in `preflight-transitions` — justified because the alternative is silently failing 4 times per phase until the user notices.
- **Never print or persist the API token** in chat, tickets, or committed files.
- **Idempotent on re-runs.** Phases with existing `[jira:KEY]` annotations are skipped in create mode. Transitions that are already past the target status may return "no matching transition" — that is expected and not an error.
- **Cache once, reuse for the whole task.** `preflight-transitions` writes `.ai-dev-garage/.workflow-state-tmp/{TASK-KEY}/jira-transitions.json` exactly once; subsequent `transition` calls read the cache and skip the per-call `/transitions` GET. On AISD-9-shaped deliveries this collapses ~20 GETs into 1.
- **Cache invalidation.** Delete `jira-transitions.json` when the user edits `integrations.jira.transitions.*` in project-config; the caller (`deliver-task`) is responsible for detecting the edit and clearing the cache. A stale cache manifests as a successful API response but the wrong target status on the board.
- Credential resolution follows the same overlay as `jira-item-fetcher` — see [REFERENCE.md](references/REFERENCE.md).
