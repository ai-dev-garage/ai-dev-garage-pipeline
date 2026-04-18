# Get Jira item — reference

## Setup (Jira API token)

Jira Cloud REST calls need a **base URL** (e.g. `https://your-site.atlassian.net`) and an **API token** from Atlassian: [Create an API token](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/).

**Do not commit secrets.** Add the env file name to `.gitignore` in any repo where you commit one into the working tree (the pipeline `.gitignore` already ignores `secrets.env` and the legacy `jira.env` repo-wide).

**Template (committed):** copy **`${CLAUDE_PLUGIN_ROOT}/jira.template.env`** to one of the canonical paths below and rename to **`secrets.env`**. New optional keys may appear in the template as the extension evolves.

### Canonical paths (preferred)

- **Global:** `~/.ai-dev-garage/secrets.env`
- **Project:** `{PROJECT_ROOT}/.ai-dev-garage/secrets.env`

### Legacy paths (still read; deprecation warning on hit)

- **Global legacy:** `~/.config/ai-garage/jira.env`
- **Project legacy:** `{PROJECT_ROOT}/.config/ai-garage/jira.env`

## Credential precedence (overlay order)

Apply in order; **later** rows override **earlier** rows **per key** (URL and token independently). Within each file layer, the **canonical** path is preferred and the **legacy** path is a read-only fallback.

| Step | Source | Keys |
|------|--------|------|
| 1 | Global env file | canonical `~/.ai-dev-garage/secrets.env` → legacy `~/.config/ai-garage/jira.env`; reads `JIRA_BASE_URL`, `JIRA_API_TOKEN`, `JIRA_USER_EMAIL` |
| 2 | Project env file | canonical `{PROJECT_ROOT}/.ai-dev-garage/secrets.env` → legacy `{PROJECT_ROOT}/.config/ai-garage/jira.env` |
| 3 | Process environment | `JIRA_BASE_URL`, `JIRA_API_TOKEN`, `JIRA_USER_EMAIL`; token fallbacks `ATLASSIAN_API_TOKEN`, `CONFLUENCE_API_TOKEN` (in that order; used only if `JIRA_API_TOKEN` is unset) |
| 4 | Caller | `jira-base-url`, `jira-api-token` |

Example: token only in global file, URL only in `JIRA_BASE_URL` env → both are used after overlay.

## Env file format (`secrets.env` / legacy `jira.env`)

Plain text, one variable per line (`KEY=value`). Lines starting with `#` are comments. Optional quotes around values.

Start from **`jira.template.env`** at the plugin root (`${CLAUDE_PLUGIN_ROOT}/` in the pipeline repo); `JIRA_BASE_URL`, `JIRA_API_TOKEN`, and `JIRA_USER_EMAIL` (for Atlassian Cloud Basic auth) are required for **jira-item-fetcher** today.

No spaces around `=`. Strip trailing whitespace from values.

## When credentials are missing

Reply with a **single** short block for the user (no token prompt):

- Jira lookups need a **base URL**, **API token**, and (for Atlassian Cloud) the token owner's **email**.
- Set **`JIRA_BASE_URL`**, **`JIRA_API_TOKEN`**, and **`JIRA_USER_EMAIL`** in the environment, **or** copy **`jira.template.env`** to **`~/.ai-dev-garage/secrets.env`** (global) or **`<project>/.ai-dev-garage/secrets.env`** (project) and fill in values.
- Legacy locations (`~/.config/ai-garage/jira.env`, `<project>/.config/ai-garage/jira.env`) are still read but will be migrated on the next run.
- See Atlassian’s docs to create a token; keep the file out of git.

Extension overview: **[README.md](../../../README.md)** (this extension folder in the pipeline repo).

## Fetch single issue

`KEY` is the uppercase ticket key. `TOKEN` is the resolved API token. `EMAIL` is the token owner's email (`JIRA_USER_EMAIL`) — required for Atlassian Cloud Basic auth.

```bash
curl -s \
  -u "$EMAIL:$TOKEN" \
  -H "Accept: application/json" \
  "$JIRA_BASE_URL/rest/api/3/issue/$KEY?fields=summary,description,status,priority,issuetype,assignee,reporter,parent,created,updated,timeoriginalestimate,comment"
```

On self-hosted Jira Server / Data Center, `-u "$EMAIL:$TOKEN"` can be replaced with `-H "Authorization: Bearer $TOKEN"` when `JIRA_USER_EMAIL` is not available.

## Output template

```markdown
**[TICKET-KEY]({jira_base_url}/browse/TICKET-KEY)**

**Summary Title Here**

| Field | Value |
|-------|-------|
| **Type** | issuetype.name (add "subtask" label if issuetype.subtask is true) |
| **Parent** | [PARENT-KEY]({jira_base_url}/browse/PARENT-KEY) — parent summary |
| **Status** | status.name |
| **Priority** | priority.name |
| **Assignee** | assignee.displayName |
| **Reporter** | reporter.displayName |
| **Estimate** | timeoriginalestimate converted to hours |
| **Created** | created date |
| **Updated** | updated date |

### Description

<description text, preserving Jira formatting>

### Comments (<count>)

<Show last 5 comments max. For each: author, date, body. If none: "No comments.">
```

## API notes

- Timestamps are ISO 8601 — display as `YYYY-MM-DD`.
- `timeoriginalestimate` is in seconds — divide by 3600 for hours.
- Omit any field row where the value is null or empty.
- Atlassian Cloud personal API tokens require HTTP **Basic** auth with `JIRA_USER_EMAIL:JIRA_API_TOKEN`. Bearer auth is for self-hosted Jira Server / Data Center or for OAuth access tokens; sending a Cloud personal token as Bearer returns `Failed to parse Connect Session Auth Token`.

## JQL search endpoint

For fetching sibling tasks, epic children, or related issues. Use the **v3 enhanced search** path; the deprecated `/rest/api/2/search` returns no `issues` array on recent Atlassian Cloud tenants.

```bash
curl -s \
  -u "$EMAIL:$TOKEN" \
  -H "Accept: application/json" \
  "$JIRA_BASE_URL/rest/api/3/search/jql?jql=parent%3D{PARENT-KEY}%20ORDER%20BY%20rank%20ASC&fields=summary,status,issuetype,assignee"
```

For walking an epic's children with rank + block-graph awareness, prefer the dedicated `jira-epic-walker` skill over hand-rolling this query.
