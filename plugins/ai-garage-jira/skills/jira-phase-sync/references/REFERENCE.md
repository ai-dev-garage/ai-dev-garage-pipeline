# Jira phase sync — reference

## CLI contract

All REST calls use the Jira CLI at `${CLAUDE_PLUGIN_ROOT}/scripts/jira_cli.py`. See **[jira-item-fetcher REFERENCE.md](../../jira-item-fetcher/references/REFERENCE.md)** for the full CLI contract (subcommand table, common options, exit codes, error output format).

## Credential precedence (overlay order)

Identical to `jira-item-fetcher`. Apply in order; **later** rows override **earlier** rows **per key** (URL and token independently). Within each file layer, the **canonical** path is preferred and the **legacy** path is a read-only fallback (triggers a one-line deprecation warning).

| Step | Source | Keys |
|------|--------|------|
| 1 | Global env file | canonical `~/.ai-dev-garage/secrets.env` → legacy `~/.config/ai-garage/jira.env`; reads `JIRA_BASE_URL`, `JIRA_API_TOKEN` |
| 2 | Project env file | canonical `{PROJECT_ROOT}/.ai-dev-garage/secrets.env` → legacy `{PROJECT_ROOT}/.config/ai-garage/jira.env` |
| 3 | Process environment | `JIRA_BASE_URL`, `JIRA_API_TOKEN`; token fallbacks `ATLASSIAN_API_TOKEN`, then `CONFLUENCE_API_TOKEN` (only if `JIRA_API_TOKEN` is unset) |
| 4 | Caller | `jira-base-url`, `jira-api-token` |

## Create sub-task

`PARENT_KEY` is the parent ticket key. `PROJECT_KEY` is extracted from `PARENT_KEY` (everything before the `-`). `SUBTASK_TYPE` is the issue type name (default `"Sub-task"`).

```bash
python3 "$JIRA_CLI" create-issue \
  --project "$PROJECT_KEY" \
  --parent "$PARENT_KEY" \
  --summary "$SUMMARY" \
  --description "$DESCRIPTION" \
  --type "$SUBTASK_TYPE" \
  --project-root "$PROJECT_ROOT"
```

**Success:** HTTP 201. Response body contains `{ "id": "...", "key": "PROJ-456", "self": "..." }`.

**Common errors:**
- **400:** Invalid fields — check `issuetype.name` matches a valid sub-task type in the project. Some Jira instances use `"Subtask"` (no hyphen) or a custom name.
- **401/403:** Token invalid or insufficient permissions.
- **404:** Parent ticket not found.

## Get transitions

Fetch available transitions for an issue. Only transitions reachable from the issue's **current status** are returned.

```bash
python3 "$JIRA_CLI" get-transitions "$KEY" --project-root "$PROJECT_ROOT"
```

**Response structure:**
```json
{
  "transitions": [
    {
      "id": "21",
      "name": "In Progress",
      "to": { "name": "In Progress", "id": "3" }
    },
    {
      "id": "31",
      "name": "Done",
      "to": { "name": "Done", "id": "10001" }
    }
  ]
}
```

**Matching logic:** Compare the config's target status name against each `transitions[].name` using **case-insensitive substring** match. If multiple transitions match, use the first one. If none match, return a warning listing the available transition names.

## Execute transition

```bash
python3 "$JIRA_CLI" transition "$KEY" --id "$TRANSITION_ID" --project-root "$PROJECT_ROOT"
```

**Success:** HTTP 204 (no content).

**Common errors:**
- **400:** Transition not valid from current status (issue may have already moved past this state).
- **404:** Issue not found.

## Sub-task summary format

When creating sub-tasks, build the summary and description from the WBS phase:

- **Summary:** Phase title in human-readable form (e.g., `"Phase 1: Domain Models"` from `phase-1-domain-models`).
- **Description:** WBS items as a bullet list:
  ```
  - Create User entity [effort:low]
  - Create Order entity [effort:low]
  ```

## Transition cache (`jira-transitions.json`)

Written by `preflight-transitions` at `.ai-dev-garage/.workflow-state-tmp/{TASK-KEY}/jira-transitions.json`. Read by every subsequent `transition` call so the skill does not re-probe the board's `/transitions` endpoint per call.

**Shape:**

```json
{
  "probed-at": "2026-04-18T12:00:00Z",
  "probe-subtask": "PROJ-456",
  "board-transitions": ["To Do", "In Progress", "To Review", "Done"],
  "mapping": {
    "phase-started":     { "configured": "In Progress", "resolved-name": "In Progress", "resolved-id": "21" },
    "phase-implemented": { "configured": "To Review",   "resolved-name": "To Review",   "resolved-id": "31" },
    "review-started":    { "configured": "To Review",   "resolved-name": "To Review",   "resolved-id": "31" },
    "phase-ready":       { "configured": "Done",        "resolved-name": "Done",        "resolved-id": "41" }
  }
}
```

- `probed-at` is ISO-8601 and used to detect stale caches across very long-running tasks.
- `probe-subtask` records which sub-task's `/transitions` endpoint was probed. If a later sub-task is in a different workflow (rare — would only happen if the project mixes issue types that each carry their own workflow), the cache is invalidated and a fresh preflight is required.
- `mapping` is keyed by the **semantic event** name (`phase-started`, `phase-implemented`, `review-started`, `phase-ready`), not by the board name — the same board name may be reused across multiple events, and the cache collapses them correctly.
- `resolved-id` is the Jira transition id used directly in the `POST /transitions` payload, skipping the name→id lookup entirely on cache hits.

**Invalidation:** The orchestrator (`deliver-task`) deletes this file when the user changes any `integrations.jira.transitions.*` value in project-config. The skill itself does not watch the config file.

## API notes

- All endpoints use Jira REST API v2.
- Auth method is auto-detected by the CLI: if `JIRA_USER_EMAIL` is resolved (env file, process env, or `--email` flag), Basic auth is used (`email:token` base64-encoded); otherwise Bearer auth. Atlassian Cloud personal API tokens require Basic auth.
- Rate limits vary by Jira tier. With `preflight-transitions` + cache, the skill makes at most **N sub-task creations + 1 preflight probe + K transitions** per task (K = phases × transitions-per-phase), versus the old flow's **N creations + K GET /transitions + K POST /transitions** — roughly 2× reduction in API calls on typical deliveries.
- The `project.key` in the create payload is derived from the parent key: split on `-` and take the first part.
