---
name: assistant
description: Entry + help for the personal assistant. Routes to summarize / investigate / capture, or prints the capability map.
---

User input (pass through to sub-commands):

```
$ARGUMENTS
```

## Outline

1. If arguments are empty, `help`, `-h`, or `--help`, print the capability map below and stop:

   **Personal Assistant — capture decisions, ideas, and research into Notion**

   | Command | Description |
   |---|---|
   | `/assistant:summarize` | Summarize the current session — decisions, outcomes, open questions — into a `Summary` entry. |
   | `/assistant:investigate <topic>` | Research a topic (web + chat context + docs) and publish an `Investigation` entry with sources. |
   | `/assistant:capture [type=idea\|decision\|action] <content>` | Quick capture of an idea, decision, or action. |
   | `/assistant:setup-claude-project` | Guided walkthrough to set up the Personal Assistant as a Claude Project for Claude Desktop / Mobile. |

   | Agent | Description |
   |---|---|
   | `session-summarizer` | Extracts decisions / outcomes / open Qs from the current session. |
   | `topic-investigator` | Web + docs research with cited sources. |

   | Skill | Description |
   |---|---|
   | `notion-publisher` | Writes a typed entry to the Notion Assistant Inbox (confirm-first). |
   | `assistant-entry-formatter` | Builds the standard entry body (Context / Key points / Sources / Next). |

   **Config:** `integrations.assistant.notion-mcp-connector` and `integrations.assistant.notion-database-id` must be set in `.ai-dev-garage/project-config.yaml`. See the plugin README for setup.

   **Confirm-first:** every write to Notion is approved by you before it lands.

2. Otherwise, treat the first token of `$ARGUMENTS` as a sub-command (`summarize`, `investigate`, `capture`, `setup-claude-project`) and load the matching command file from `${CLAUDE_PLUGIN_ROOT}/commands/{sub}.md`, passing the remaining arguments.
