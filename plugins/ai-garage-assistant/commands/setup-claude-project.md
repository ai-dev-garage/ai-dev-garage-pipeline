---
name: assistant:setup-claude-project
description: Guide the user through setting up the Personal Assistant as a Claude Project for Claude Desktop / Mobile. Walks the one-time manual steps, resolves the connector + database id, and hands over the filled-in system prompt.
argument-hint: (no arguments)
---

## Outline

This is a **guided interactive walkthrough**. Do not dump everything at once — take it step by step, confirming with the user after each.

### 1. Frame the goal

Tell the user:

> Claude Projects don't support plugins, so the Desktop/Mobile setup is manual — about 5 minutes. You'll end up with a Claude Project whose system prompt knows how to write to the same Notion database this plugin uses. I'll walk you through it.

Ask: "Ready to start?" — wait for confirmation.

### 2. Prerequisites check

List and confirm each:

- **Claude Desktop** installed (Projects require a paid tier).
- **A Notion workspace** the user controls.
- **A Notion MCP connector** installed in Claude Desktop — ask for the **connector name** as registered (e.g. `garage-notion`). If the user doesn't know, point them to Claude Desktop → Settings → Connectors.

If any prerequisite is missing, stop and explain how to resolve it before continuing.

### 3. Create the Notion database

Read `${CLAUDE_PLUGIN_ROOT}/claude-project/notion-db-template.md` and walk the user through **Option A (UI)** — it's the reliable path.

Emphasize two easy-to-miss steps:

- **Share the database with the MCP connector's integration** (Notion → database → `...` → Connections → add your integration). Without this, every write fails with `object_not_found`.
- **Set `Inbox` as the default value** for the Status select (only possible in the UI).

Ask the user to paste back the **database id** (32-char id from the Notion URL, before `?v=`).

### 4. Offer to save to project config

Ask: "Want me to save the connector name and database id to this project's `.ai-dev-garage/project-config.yaml`? The Code plugin will use them too."

If yes, call `project-config-resolver` and write:

- `integrations.assistant.notion-mcp-connector`
- `integrations.assistant.notion-database-id`

This makes `/assistant:capture` etc. work immediately in Code.

### 5. Create the Claude Project

Guide:

1. Claude Desktop → **Projects → New project** → name it `Personal Assistant` (or whatever they prefer).
2. Open the project → **Connectors** → enable the Notion MCP connector.

Wait for confirmation before moving on.

### 6. Generate the filled-in system prompt

Read `${CLAUDE_PLUGIN_ROOT}/claude-project/system-prompt.md`. Substitute:

- `{{NOTION_DATABASE_ID}}` → the id from step 3.
- `{{NOTION_MCP_CONNECTOR}}` → the connector name from step 2.

Show the filled-in prompt to the user in a code block, then tell them:

> Paste this into the project's **Instructions** field and save.

### 7. Verify

Tell the user to run a first-time test in the new Claude Project:

> In a chat within the `Personal Assistant` project, say: **"save this idea: setup complete"**.
> Claude will show you a draft entry and ask to confirm. Approve it.
> A new `Idea` row should appear in your **Assistant Inbox** database with `Source = Desktop`.

Offer to troubleshoot if the test write fails — common causes are in `claude-project/SETUP.md` ("Troubleshooting" table); read that file and cite the matching row.

### 8. Mobile

Tell the user:

> Mobile inherits from the Desktop project. Open Claude Mobile, switch to the `Personal Assistant` project, and it just works. On first use it will ask "desktop or mobile?" — answer `mobile` and it'll tag entries accordingly.

## Rules

- **Step by step.** Wait for confirmation between numbered steps.
- **Don't skip the sharing step.** It's the #1 setup failure and worth repeating.
- **Never paste a system prompt with unresolved placeholders.** Always substitute first.
- **Offer the config save (step 4) but don't force it** — some users keep settings global.
- **Cite the source docs** — `notion-db-template.md` and `SETUP.md` — so the user has something to come back to.
