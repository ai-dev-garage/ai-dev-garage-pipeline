# Get Jira item — reference

## Setup (Jira API token)

Jira Cloud REST calls need a **base URL** (e.g. `https://your-site.atlassian.net`) and an **API token** from Atlassian: [Create an API token](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/).

**Do not commit secrets.** Add `jira.env` to `.gitignore` in any repo where you place it under `.ai-dev-garage/` (the pipeline `.gitignore` already ignores the filename repo-wide).

**Template (committed):** copy **`extensions/jira/jira.template.env`** from your pipeline checkout to **`jira.env`** in the target directory, then edit. New optional keys may appear in the template as the extension evolves.

## Credential precedence (overlay order)

Apply in order; **later** rows override **earlier** rows **per key** (URL and token independently).

| Step | Source | Keys |
|------|--------|------|
| 1 | Global env file | `$HOME/.ai-dev-garage/jira.env` → `JIRA_BASE_URL`, `JIRA_API_TOKEN` |
| 2 | Project env file | `{PROJECT_ROOT}/.ai-dev-garage/jira.env` (same keys) |
| 3 | Process environment | `JIRA_BASE_URL`, `JIRA_API_TOKEN`; token fallback `ATLASSIAN_API_TOKEN` |
| 4 | Caller | `jira-base-url`, `jira-api-token` |

Example: token only in global file, URL only in `JIRA_BASE_URL` env → both are used after overlay.

## Env file format (`jira.env`)

Plain text, one variable per line (`KEY=value`). Lines starting with `#` are comments. Optional quotes around values.

Start from **`jira.template.env`** at the extension root (`extensions/jira/` in the pipeline repo); only **`JIRA_BASE_URL`** and **`JIRA_API_TOKEN`** are required for **jira-item-fetcher** today.

No spaces around `=`. Strip trailing whitespace from values.

## When credentials are missing

Reply with a **single** short block for the user (no token prompt):

- Jira lookups need a **base URL** and **API token**.
- Set **`JIRA_BASE_URL`** and **`JIRA_API_TOKEN`** in the environment, **or** copy **`jira.template.env`** to **`~/.ai-dev-garage/jira.env`** or **`<project>/.ai-dev-garage/jira.env`** and fill in values.
- See Atlassian’s docs to create a token; keep the file out of git.

Extension overview: **[README.md](../../../README.md)** (this extension folder in the pipeline repo).

## Fetch single issue

`KEY` is the uppercase ticket key. `TOKEN` is the resolved API token.

```bash
curl -s \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  "$JIRA_BASE_URL/rest/api/2/issue/$KEY?fields=summary,description,status,priority,issuetype,assignee,reporter,parent,created,updated,timeoriginalestimate,comment"
```

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
- If your Jira deployment uses **Basic** auth instead of Bearer, adjust headers per your org’s policy (this skill documents Bearer + API token as the common Cloud pattern).

## JQL search endpoint

For fetching sibling tasks or related issues:

```bash
curl -s \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  "$JIRA_BASE_URL/rest/api/2/search?jql=parent%3D{PARENT-KEY}%20ORDER%20BY%20created%20ASC&fields=summary,status,issuetype,assignee"
```
