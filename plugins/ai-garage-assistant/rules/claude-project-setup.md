---
description: >-
  Route Claude Desktop / Mobile / Claude Project setup questions for the
  personal assistant to the guided walkthrough command.
alwaysApply: false
---

# Claude Project setup discovery

When the user asks how to set up, install, or configure the Personal Assistant for **Claude Desktop**, **Claude Mobile**, **the Claude app**, or as a **Claude Project** — phrases like:

- "how do I set this up for Claude Desktop / mobile / the Claude app"
- "how do I use this on my phone"
- "configure the assistant for Claude Project"
- "set up the Notion side"
- "how does the desktop version work"

Route the user to the `/assistant:setup-claude-project` walkthrough at `{{PLUGIN_ROOT}}/commands/setup-claude-project.md`. Load that command file and assume its role — it guides the user through the one-time manual setup step by step.

If the user wants only a quick overview (not a walkthrough), summarize from `{{PLUGIN_ROOT}}/claude-project/SETUP.md` instead and offer to run the full walkthrough on request.
