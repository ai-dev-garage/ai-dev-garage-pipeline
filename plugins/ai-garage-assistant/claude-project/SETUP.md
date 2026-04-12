# Claude Project setup — Desktop & Mobile

This sets up the Personal Assistant in **Claude Desktop** (which also powers Claude Mobile via shared projects). The plugin handles Claude Code; this Project handles desktop/mobile.

## Prerequisites

- A Notion workspace you control.
- A Notion MCP connector installed in Claude Desktop (any implementation). Note its **connector name** (e.g. `garage-notion`).
- The **Assistant Inbox** database created in Notion — see [`notion-db-template.md`](notion-db-template.md). Note its **database id**.

## Steps

1. **Open Claude Desktop → Projects → New project**. Name it `Personal Assistant`.
2. **Attach your Notion MCP connector** to the project (Project settings → Connectors).
3. **Copy [`system-prompt.md`](system-prompt.md)** into the project's **Instructions** field.
4. **Replace the placeholders** in the pasted instructions:
   - `{{NOTION_DATABASE_ID}}` → your Assistant Inbox database id.
   - `{{NOTION_MCP_CONNECTOR}}` → the connector name from step 2 (e.g. `garage-notion`).
5. **Save** the project.

That's it — the project now works on desktop. On first mobile use, open Claude Mobile and switch to the `Personal Assistant` project; it inherits instructions and connectors from desktop.

## Verify

In a new chat within the project, try each flow:

- **Summary:** have a short exchange, then say "summarize this". Approve the draft; check Notion for a new `Summary` row with `Source = Desktop`.
- **Investigation:** "research OAuth 2.1 changes". Confirm sources are listed in the entry body.
- **Capture:** "save this idea: …". Confirm the row lands as `Idea`.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Assistant writes silently (no confirmation) | System prompt not saved, or placeholders not replaced. |
| `object_not_found` on database | DB id wrong, or the database isn't shared with the MCP connector's integration. |
| `validation_error` on a property | DB schema drifted from [`notion-db-template.md`](notion-db-template.md). Reset property types. |
| Mobile shows `Source = Desktop` | Ask once: "I'm on mobile" — the assistant will remember for the rest of the conversation. |

## Keeping parity with the Code plugin

The Claude Code plugin (`ai-garage-assistant`) writes to the same database with the same schema. If you extend the schema (new Type option, new property), update:

- [`notion-db-template.md`](notion-db-template.md)
- [`system-prompt.md`](system-prompt.md) in this folder
- `plugins/ai-garage-assistant/skills/notion-publisher/SKILL.md` and its `REFERENCE.md`
