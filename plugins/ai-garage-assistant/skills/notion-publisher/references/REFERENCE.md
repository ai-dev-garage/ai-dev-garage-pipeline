# notion-publisher — reference

## Notion property payload shapes

All calls go through `mcp__{connector}__API-post-page`. Properties are typed — use the right shape per property type.

```json
{
  "parent": { "database_id": "{notion-database-id}" },
  "properties": {
    "Name":    { "title":        [{ "text": { "content": "My entry title" } }] },
    "Type":    { "select":       { "name": "Summary" } },
    "Source":  { "select":       { "name": "Claude Code" } },
    "Status":  { "select":       { "name": "Inbox" } },
    "Tags":    { "multi_select": [{ "name": "ai" }, { "name": "notion" }] },
    "Session": { "rich_text":    [{ "text": { "content": "my-project" } }] },
    "Links":   { "url":          "https://example.com" }
  },
  "children": [ /* block array, see below */ ]
}
```

Omit optional properties rather than sending `null`. `Date` is a `created_time` property — Notion fills it automatically.

## Body blocks

The body is the templated markdown (from `assistant-entry-formatter`) converted to Notion block objects:

```json
[
  { "object": "block", "type": "heading_2",
    "heading_2": { "rich_text": [{ "text": { "content": "Context" } }] } },
  { "object": "block", "type": "paragraph",
    "paragraph": { "rich_text": [{ "text": { "content": "1–2 sentences…" } }] } },

  { "object": "block", "type": "heading_2",
    "heading_2": { "rich_text": [{ "text": { "content": "Key points" } }] } },
  { "object": "block", "type": "bulleted_list_item",
    "bulleted_list_item": { "rich_text": [{ "text": { "content": "bullet 1" } }] } },

  { "object": "block", "type": "heading_2",
    "heading_2": { "rich_text": [{ "text": { "content": "Sources" } }] } },
  { "object": "block", "type": "bulleted_list_item",
    "bulleted_list_item": { "rich_text": [{ "text": { "content": "https://…" } }] } },

  { "object": "block", "type": "heading_2",
    "heading_2": { "rich_text": [{ "text": { "content": "Next" } }] } },
  { "object": "block", "type": "bulleted_list_item",
    "bulleted_list_item": { "rich_text": [{ "text": { "content": "follow-up" } }] } }
]
```

Rich text is capped at 2000 chars per segment — split long content.

## Connector auto-detection

Searching available tools (the runtime exposes them in the turn's tool list):

```
pattern  = r"^mcp__([^_]+(?:_[^_]+)*)__API-post-page$"
notion   = [match[0] for tool in tools if "notion" in tool.lower() and (match := re.match(pattern, tool))]
```

- Exactly one → use it.
- More than one → prompt: "Multiple Notion MCP connectors available: {list}. Which should the assistant use?"
- Zero → abort: "No Notion MCP connector detected. Install one and set `integrations.assistant.notion-mcp-connector` in project config."

## Error handling

| HTTP / symptom | Meaning | Action |
|---|---|---|
| `object_not_found` on database | Wrong `notion-database-id`, or DB not shared with the integration | Ask user to verify id and share DB with the connector's integration |
| `validation_error` on property | Property name/type mismatch with DB schema | Re-read `claude-project/notion-db-template.md`; prompt user to fix schema |
| `unauthorized` | Token expired / insufficient scope | Tell user to reconnect the Notion MCP |
| Network / timeout | Transient | Retry once; on second failure, surface to user |

## Creating options on the fly

Select and multi-select accept new option names on write — Notion creates them. This is how tags grow over time without the user pre-registering every value.

## Bootstrapping the database

If the user has not yet created the DB, `notion-publisher` should not attempt it automatically. Direct them to `claude-project/notion-db-template.md`, which has both UI steps and a copy-paste `API-create-a-data-source` payload for users who prefer a programmatic setup.
