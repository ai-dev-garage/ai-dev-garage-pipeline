---
name: assistant:capture
description: Quick capture — save an idea, decision, or action as a Notion entry. Confirms the draft before writing.
argument-hint: [type=idea|decision|action] <content> [tags=<t1,t2>] [links=<url>]
---

User input:

```
$ARGUMENTS
```

## Outline

1. Parse optional `type=<idea|decision|action>` (default: `idea`), `tags=<csv>`, `links=<url>` from `$ARGUMENTS`. The remaining free-form text is the entry content.
2. If no content is present, prompt the user and stop.
3. Map `type`:
   - `idea` → `Idea`
   - `decision` → `Decision`
   - `action` → `Action`
4. Compose a draft:
   - `name` — first sentence or ≤ 80 chars of the content.
   - `context` — full free-form content (or split: first line → context, rest → key points if the user used a list).
   - `key_points` — any bullet lines the user wrote, else empty.
   - `sources` — `links` arg, else empty.
   - `next` — for `Action` type: the action itself as a bullet; else empty.
5. Call `assistant-entry-formatter` to build the body.
6. Hand off to `notion-publisher` with `source="Claude Code"`. It confirms before writing.
7. Report the created page URL when done.

## Rules

- **No embellishment.** Capture is for quick, minimal save — do not expand or rephrase beyond what the user said.
- **Default type is `Idea`** — lowest-friction path for stream-of-consciousness capture.
