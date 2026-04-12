---
name: session-summarizer
description: Extract decisions, outcomes, open questions, and next steps from the current Claude Code session and publish a `Summary` entry to the Notion Assistant Inbox. Use when the user asks to "summarize", "wrap up", or "what did we decide" about the current conversation.
skills:
  - ai-garage-assistant:assistant-entry-formatter
  - ai-garage-assistant:notion-publisher
  - ai-garage-dev-workflow:project-config-resolver
---

# Session summarizer

You extract a durable record of what happened in the current session and publish it to Notion.

## Input

- Optional `session` label (e.g. a project or topic name). If missing, infer from the working directory name or the dominant topic of the conversation.
- Optional `tags`.

## Instructions

### 1. Gather material

Read back over the visible conversation: user messages, your replies, and tool results. Pay attention to:

- **Decisions made** — choices the user accepted, trade-offs resolved.
- **Outcomes achieved** — code shipped, files created, PRs opened, bugs fixed.
- **Open questions** — things the user flagged as TBD.
- **Next steps** — work explicitly deferred.

Do not re-run tools or re-read files. Work from what is already in context.

### 2. Draft the entry

Compose fields:

- `type` = `"Summary"`
- `name` = short title capturing the session's theme (≤ 80 chars).
- `context` = 1–2 sentences: why this session happened.
- `key_points` = decisions + outcomes, as bullets. Be specific — include file paths, ticket keys, PR numbers where relevant.
- `sources` = references (file paths, URLs, ticket keys, PR links).
- `next` = open questions and deferred work, as bullets.
- `session`, `tags`, `links` = from caller / inferred.

Call `assistant-entry-formatter` to build the body.

### 3. Publish

Hand off to `notion-publisher` with `source = "Claude Code"`. The publisher will confirm the draft with the user before writing.

## Rules

- **Ground in evidence.** Every bullet should trace to something actually said, done, or produced in this session. Do not speculate.
- **Favor concrete over abstract.** "Fixed null-pointer in `auth.go:142`" beats "Fixed a bug."
- **Do not invent tags.** Only suggest tags the user used or that are clearly implied by the work.
- **Stop before writing.** The user approves via `notion-publisher`'s confirmation step.
