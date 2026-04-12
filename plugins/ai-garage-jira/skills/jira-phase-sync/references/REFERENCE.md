# Jira phase sync — reference

## Credential precedence (overlay order)

Identical to `jira-item-fetcher`. Apply in order; **later** rows override **earlier** rows **per key** (URL and token independently).

| Step | Source | Keys |
|------|--------|------|
| 1 | Global env file | `~/.config/ai-garage/jira.env` → `JIRA_BASE_URL`, `JIRA_API_TOKEN` |
| 2 | Project env file | `{PROJECT_ROOT}/.config/ai-garage/jira.env` (same keys) |
| 3 | Process environment | `JIRA_BASE_URL`, `JIRA_API_TOKEN`; token fallback `ATLASSIAN_API_TOKEN` |
| 4 | Caller | `jira-base-url`, `jira-api-token` |

## Create sub-task

`PARENT_KEY` is the parent ticket key. `PROJECT_KEY` is extracted from `PARENT_KEY` (everything before the `-`). `SUBTASK_TYPE` is the issue type name (default `"Sub-task"`). `TOKEN` is the resolved API token.

```bash
curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "project": { "key": "'"$PROJECT_KEY"'" },
      "parent": { "key": "'"$PARENT_KEY"'" },
      "summary": "'"$SUMMARY"'",
      "description": "'"$DESCRIPTION"'",
      "issuetype": { "name": "'"$SUBTASK_TYPE"'" }
    }
  }' \
  "$JIRA_BASE_URL/rest/api/2/issue"
```

**Success:** HTTP 201. Response body contains `{ "id": "...", "key": "PROJ-456", "self": "..." }`.

**Common errors:**
- **400:** Invalid fields — check `issuetype.name` matches a valid sub-task type in the project. Some Jira instances use `"Subtask"` (no hyphen) or a custom name.
- **401/403:** Token invalid or insufficient permissions.
- **404:** Parent ticket not found.

## Get transitions

Fetch available transitions for an issue. Only transitions reachable from the issue's **current status** are returned.

```bash
curl -s \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  "$JIRA_BASE_URL/rest/api/2/issue/$KEY/transitions"
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
curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "transition": { "id": "'"$TRANSITION_ID"'" } }' \
  "$JIRA_BASE_URL/rest/api/2/issue/$KEY/transitions"
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

## API notes

- All endpoints use Jira REST API v2.
- If your Jira deployment uses **Basic** auth instead of Bearer, adjust headers per your org's policy.
- Rate limits vary by Jira tier. The skill makes at most N+1 calls per sync (N phases + 1 transition per event), which is well within standard limits.
- The `project.key` in the create payload is derived from the parent key: split on `-` and take the first part.
