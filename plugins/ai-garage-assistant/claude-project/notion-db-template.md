# Assistant Inbox — Notion database template

One-time setup. Creates the Notion page + database that both the Claude Code plugin and the Claude Project write to.

## Option A — via the Notion UI (recommended)

1. In your Notion workspace, create a top-level page titled **Personal Assistant**.
2. Inside that page, add an inline database titled **Assistant Inbox**.
3. Configure the following properties (delete the defaults Notion adds, except `Name`):

| Property | Type | Options / Notes |
|---|---|---|
| `Name` | Title | Default — keep it. |
| `Type` | Select | Options: `Summary`, `Investigation`, `Idea`, `Decision`, `Action` |
| `Source` | Select | Options: `Claude Code`, `Desktop`, `Mobile`, `Other` |
| `Status` | Select | Options: `Inbox`, `Reviewed`, `Processed`, `Archived`. Set default to `Inbox`. |
| `Tags` | Multi-select | Leave empty — options grow over time. |
| `Date` | Created time | Auto. |
| `Session` | Text | Rich text. |
| `Links` | URL | |

4. Share the database with your Notion MCP integration (the same integration your MCP connector uses).
5. Copy the database id from the URL: `https://www.notion.so/{workspace}/{DB_ID}?v=...` — the 32-char id before `?v=`.
6. Put the id in `integrations.assistant.notion-database-id` in your project config (or global config).

## Option B — via the Notion API

If you prefer scripting, use `mcp__{connector}__API-create-a-data-source` with a payload along the lines of:

```json
{
  "parent": { "type": "page_id", "page_id": "{parent-page-id}" },
  "title": [{ "type": "text", "text": { "content": "Assistant Inbox" } }],
  "properties": {
    "Name":    { "title": {} },
    "Type":    { "select": { "options": [
      { "name": "Summary" }, { "name": "Investigation" },
      { "name": "Idea" }, { "name": "Decision" }, { "name": "Action" }
    ]}},
    "Source":  { "select": { "options": [
      { "name": "Claude Code" }, { "name": "Desktop" },
      { "name": "Mobile" }, { "name": "Other" }
    ]}},
    "Status":  { "select": { "options": [
      { "name": "Inbox" }, { "name": "Reviewed" },
      { "name": "Processed" }, { "name": "Archived" }
    ]}},
    "Tags":    { "multi_select": { "options": [] } },
    "Session": { "rich_text": {} },
    "Links":   { "url": {} }
  }
}
```

Notion does not let the API set a default value for `Status` — after creation, open the DB in the UI and set `Inbox` as the default.

## Verification

After setup, in Claude Code run:

```
/assistant:capture type=idea "Test entry — setup complete"
```

Approve the draft. A new row should appear in **Assistant Inbox** with `Source = Claude Code`, `Status = Inbox`, `Type = Idea`.
