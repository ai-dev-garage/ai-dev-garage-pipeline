---
name: notion-publisher
description: Publish a structured assistant entry to the configured Notion database. Resolves the Notion MCP connector and database id from project config (with auto-detection fallback), then creates a page with typed properties and a templated body. Confirms the draft with the user before writing.
argument-hint: entry object ({type, name, session?, tags?, links?, body}) and source ("Claude Code" | "Desktop" | "Mobile" | "Other")
---

# Notion publisher

## When to use

- Called by `session-summarizer`, `topic-investigator`, and `/assistant:capture` once a draft entry is ready.
- Any caller that needs to land a typed entry in the Assistant Inbox database.

## Input

```
entry:
  type:    "Summary" | "Investigation" | "Idea" | "Decision" | "Action"
  name:    short descriptive title (Title property)
  body:    templated markdown page body (from assistant-entry-formatter)
  session: optional rich-text (project/topic identifier)
  tags:    optional list of strings
  links:   optional URL (primary reference)
source:    "Claude Code" | "Desktop" | "Mobile" | "Other"
```

## Instructions

### 1. Resolve configuration

Call `project-config-resolver` for:

- `integrations.assistant.notion-mcp-connector`
- `integrations.assistant.notion-database-id`
- `integrations.assistant.default-tags`
- `integrations.assistant.session-prefix`

### 2. Auto-detect connector if missing

If `notion-mcp-connector` is null:

1. Enumerate currently available tools matching `mcp__*__API-post-page`.
2. Filter to names containing `notion` (case-insensitive).
3. If exactly one match → use it and write it back to config.
4. If multiple → ask the user which to use, write the choice back.
5. If none → abort with a clear error telling the user to install a Notion MCP and set `integrations.assistant.notion-mcp-connector`.

### 3. Require the database id

If `notion-database-id` is null, prompt the user for it (see `claude-project/notion-db-template.md` for how to create the DB). Write the answer back to config.

### 4. Compose properties

Build the property payload:

| Property | Value |
|---|---|
| `Name` | `entry.name` |
| `Type` | `entry.type` |
| `Source` | `source` argument |
| `Status` | `"Inbox"` |
| `Tags` | `entry.tags ∪ default-tags` (de-duplicated) |
| `Session` | `f"{session-prefix}: {entry.session}"` if prefix set, else `entry.session` |
| `Links` | `entry.links` (omit if null) |

### 5. Confirm with the user

Show the draft — properties + body — and ask for approval or edits. **Never write silently.** Loop on user edits until they approve.

### 6. Publish

Call `mcp__{connector}__API-post-page` with:

- `parent`: `{ "database_id": "{notion-database-id}" }`
- `properties`: as composed in step 4, using the correct Notion property types (see REFERENCE.md).
- `children`: block-array form of the body (paragraph / heading / bulleted_list_item blocks).

### 7. Return

Return `{ page_id, url }` to the caller. On failure, surface the error but never block the calling workflow — the user can retry.

## Rules

- **Confirm first. Never silent writes.**
- **Connector is configurable.** Never hardcode a connector name.
- **Graceful degradation.** API errors are reported, not fatal.
- **Idempotency is not guaranteed** — Notion doesn't provide natural dedup keys; retry only on explicit user request.
- **Tags are free-form.** Create new multi-select options as needed; Notion allows this on write.

## Reference

Full Notion API call shapes, property formats, and block structures: [REFERENCE.md](references/REFERENCE.md).
