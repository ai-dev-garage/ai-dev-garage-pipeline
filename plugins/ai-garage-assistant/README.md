# ai-garage-assistant

Personal assistant for Claude Code and Claude Desktop/Mobile. Captures key outcomes from your work — session summaries, topic investigations, and quick ideas/decisions/actions — and publishes them as structured entries to a **Notion database** you control.

## What it gives you

In **Claude Code** (via this plugin):

- `/assistant` — help & capability map.
- `/assistant:summarize` — summarize the current session into a `Summary` entry.
- `/assistant:investigate <topic>` — web + chat-context research; publishes an `Investigation` entry with sources.
- `/assistant:capture [type=idea|decision|action] <content>` — quick capture.

In **Claude Desktop / Mobile** (via a Claude Project):

- Natural-language intent ("summarize this", "look into X", "save this idea") drives the same flows, using your Notion MCP connector. See [`claude-project/SETUP.md`](claude-project/SETUP.md).

All writes are **confirm-first** — you see the draft before anything lands in Notion.

## Open-source friendly — no hardcoded workspaces

Nothing in this plugin is bound to a specific Notion workspace or MCP connector. Point it at your own. The connector name is resolved from config (`integrations.assistant.notion-mcp-connector`) and can also be auto-detected if you have exactly one Notion MCP installed.

## Setup

1. Install a Notion MCP connector in Claude Code / Desktop (any implementation — the plugin talks to it via the generic `mcp__{connector}__API-*` surface).
2. Copy `project-config.template.yaml` into your project's `.ai-dev-garage/project-config.yaml` (or global `~/.config/ai-garage/config.yaml`) and fill in:
   - `integrations.assistant.notion-mcp-connector`
   - `integrations.assistant.notion-database-id`
3. Create the `Assistant Inbox` database in Notion — schema in [`claude-project/notion-db-template.md`](claude-project/notion-db-template.md). One page, one database, one-time.
4. Reload plugins and run `/assistant` to verify.

For Desktop/Mobile, follow [`claude-project/SETUP.md`](claude-project/SETUP.md) to create a Claude Project with the shared system prompt — or just run **`/assistant:setup-claude-project`** (or ask "how do I set this up for Claude Desktop?") for a guided walkthrough that fills the system prompt in for you.

## Notion schema (summary)

| Property | Type | Notes |
|---|---|---|
| Name | Title | Entry title |
| Type | Select | `Summary`, `Investigation`, `Idea`, `Decision`, `Action` |
| Source | Select | `Claude Code`, `Desktop`, `Mobile`, `Other` |
| Status | Select | `Inbox` (default), `Reviewed`, `Processed`, `Archived` |
| Tags | Multi-select | Free-form |
| Date | Created time | Auto |
| Session | Rich text | Project / topic identifier |
| Links | URL | Primary reference |

Entry body uses a fixed template: **Context / Key points / Sources / Next**.
