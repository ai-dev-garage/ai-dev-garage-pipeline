# Jira epic walker — reference

## Setup (Jira API token)

Jira Cloud REST calls need a base URL (e.g. `https://your-site.atlassian.net`), an API token, and — for Atlassian Cloud personal tokens — the token owner's email. Create a token via [Atlassian account settings](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/).

**Do not commit secrets.** Keep `secrets.env` out of git. The pipeline `.gitignore` already excludes `secrets.env` and the legacy `jira.env` repo-wide.

**Template (committed):** copy `${CLAUDE_PLUGIN_ROOT}/jira.template.env` to one of the canonical paths below and rename to `secrets.env`.

### Canonical paths (preferred)

- Global: `~/.ai-dev-garage/secrets.env`
- Project: `{PROJECT_ROOT}/.ai-dev-garage/secrets.env`

### Legacy paths (still read; deprecation warning on hit)

- Global legacy: `~/.config/ai-garage/jira.env`
- Project legacy: `{PROJECT_ROOT}/.config/ai-garage/jira.env`

## Credential precedence (overlay order)

Apply in order. Later rows override earlier rows per key. Within each file layer the canonical path is preferred and the legacy path is a read-only fallback.

| Step | Source | Keys |
|------|--------|------|
| 1 | Global env file | canonical `~/.ai-dev-garage/secrets.env` → legacy `~/.config/ai-garage/jira.env`; reads `JIRA_BASE_URL`, `JIRA_API_TOKEN`, `JIRA_USER_EMAIL` |
| 2 | Project env file | canonical `{PROJECT_ROOT}/.ai-dev-garage/secrets.env` → legacy `{PROJECT_ROOT}/.config/ai-garage/jira.env` |
| 3 | Process environment | `JIRA_BASE_URL`, `JIRA_API_TOKEN`, `JIRA_USER_EMAIL`; token fallbacks `ATLASSIAN_API_TOKEN` then `CONFLUENCE_API_TOKEN` (only if `JIRA_API_TOKEN` is unset) |
| 4 | Caller | `--jira-base-url`, `--jira-api-token` |

## Auth mode

Atlassian Cloud personal API tokens authenticate over HTTP **Basic** with `JIRA_USER_EMAIL:JIRA_API_TOKEN`. If `JIRA_USER_EMAIL` is absent the script falls back to `Authorization: Bearer <token>`, which works on self-hosted Jira Server / Data Center but rejects Cloud tokens with `Failed to parse Connect Session Auth Token`. Set `JIRA_USER_EMAIL` whenever the base URL is a `*.atlassian.net` host.

## When credentials are missing

Reply with this single block (no token prompt):

- Jira lookups need `JIRA_BASE_URL`, `JIRA_API_TOKEN`, and `JIRA_USER_EMAIL` (for Atlassian Cloud Basic auth).
- Copy `jira.template.env` to `~/.ai-dev-garage/secrets.env` (global) or `<project>/.ai-dev-garage/secrets.env` (project) and fill in values.
- Legacy paths (`~/.config/ai-garage/jira.env`, `<project>/.config/ai-garage/jira.env`) still read with a deprecation warning.

## Script contract

`scripts/fetch_epic_tree.py <EPIC_KEY> [--include-done] [--top N] [--json] [--jira-base-url ...] [--jira-api-token ...] [--project-root ...]`

- Stdout: normalized JSON (see JSON shape below).
- Stderr: warnings (legacy file hit, auth hints) and error messages.

Exit codes:

| Code | Meaning |
|------|---------|
| 0 | success |
| 2 | credentials missing after overlay |
| 3 | epic key not found (HTTP 404) |
| 4 | unauthorized (HTTP 401 / 403) |
| 5 | other HTTP / transport error |
| 6 | bad usage (could not extract a Jira key from the argument) |

## Jira REST endpoints used

- Epic header: `GET /rest/api/3/issue/{KEY}?fields=summary,description,status,priority,issuetype,assignee,reporter,parent,created,updated,issuelinks`.
- Children: `GET /rest/api/3/search/jql?jql=parent={KEY}&fields=summary,status,issuetype,priority,assignee,issuelinks,created,customfield_10019`.

The v3 search endpoint is the enhanced search path on Atlassian Cloud. The deprecated `/rest/api/2/search` endpoint returns no `issues` array on recent Cloud tenants and must not be used here.

## Rank field

Most Atlassian Cloud tenants expose Jira rank as `customfield_10019` with lexicographic-sortable string values (e.g. `0|i0002f:`). If the field is absent for a given tenant the script falls back to `created ASC`. Rank is the primary sort key for both the children table and the next-candidate shortlist.

## Next-candidate algorithm (deterministic)

1. Start from the full children list.
2. If `--include-done` is not set, drop children whose `status.statusCategory.key == "done"`.
3. Drop any remaining child that has at least one inward `is blocked by` link whose target is not itself in the done category — regardless of whether the blocking issue is a sibling of the epic.
4. Sort the survivors by rank ascending (with `created ASC` as a tie-breaker for rank-less tenants).
5. Return the first `--top N` (default `3`).

The children table in the rendered output is ordered the same way (rank ascending) so the "Next candidates" shortlist is visually traceable to specific rows.

## Output template (default markdown mode)

```markdown
## Epic [AISD-1]({jira_base_url}/browse/AISD-1)

**User Notification Infrastructure**

| Field | Value |
|-------|-------|
| **Status** | status.name |
| **Type** | issuetype.name |
| **Priority** | priority.name |
| **Assignee** | assignee.displayName |
| **Reporter** | reporter.displayName |
| **Created** | ISO8601 → YYYY-MM-DD |
| **Updated** | ISO8601 → YYYY-MM-DD |

### Children (<N>)

| Key | Type | Status | Priority | Assignee | Blocked by | Blocks |
|-----|------|--------|----------|----------|------------|--------|
| [KEY](url) | Story | To Do | Medium | name | keys | keys |

### Next candidates (<M>)

- [KEY](url) — summary — *rationale (e.g. "unblocked, earliest rank")*
```

Rules:

- Omit table rows whose value is null or empty.
- Shorten `Blocked by` / `Blocks` cells to comma-separated keys; link to each key if the renderer supports it.
- If the children list is empty, skip the children table and state "No child issues found."
- If the next-candidate list is empty, state why (e.g. "All non-done children are gated by open dependencies.").

## JSON shape (`--json` mode)

```json
{
  "epic": {
    "key": "AISD-1",
    "url": "…/browse/AISD-1",
    "summary": "…",
    "status_name": "To Do",
    "status_category": "new",
    "type": "Epic",
    "priority": "Highest",
    "assignee": null,
    "reporter": "…",
    "created": "2026-04-12T16:55:25.839+0200",
    "updated": "2026-04-12T20:23:57.340+0200"
  },
  "children": [
    {
      "key": "AISD-9",
      "summary": "…",
      "status_name": "To Do",
      "status_category": "new",
      "type": "Story",
      "priority": "Medium",
      "assignee": null,
      "rank": "0|i0002f:",
      "created": "2026-04-12T…",
      "blocks": [ { "key": "AISD-10", "summary": "…", "status_name": "To Do", "status_category": "new" } ],
      "blocked_by": [],
      "url": "…/browse/AISD-9"
    }
  ],
  "next_candidates": ["AISD-9", "AISD-158", "AISD-160"],
  "next_candidates_detail": [ /* same shape as children */ ]
}
```

## Troubleshooting

- **"Failed to parse Connect Session Auth Token":** `JIRA_USER_EMAIL` is missing and the tenant is Atlassian Cloud. Add the email to `secrets.env`.
- **HTTP 404 on the epic:** the key is correct but the account cannot see the project. Confirm project permissions with the token owner.
- **Empty `children` array but the epic clearly has stories:** some Atlassian Cloud classic projects still use the legacy "Epic Link" custom field (`customfield_10014`) rather than `parent` for epic → story relationships. Edit the JQL in `scripts/fetch_epic_tree.py` to `"Epic Link" = KEY` as a tenant-specific fallback; upstream fix is tenant configuration.
- **`rank` is always null:** the tenant stores rank in a different custom field. Identify the field key via `/rest/api/3/field` and adjust `fetch_children` accordingly; the sort will otherwise fall back to `created ASC`.
