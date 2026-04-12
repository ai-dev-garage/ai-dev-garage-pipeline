---
name: assistant-entry-formatter
description: Stateless formatter for assistant entries. Given a type and raw content fields, emits the standard page body (Context / Key points / Sources / Next) used by every entry the assistant writes to Notion.
argument-hint: type and raw content fields (context, key_points, sources, next)
---

# Assistant entry formatter

## When to use

- Called by `session-summarizer`, `topic-investigator`, or `/assistant:capture` before handing off to `notion-publisher`.
- Anywhere an entry body needs to be shaped before it is written to Notion.

## Input

A structured object with these fields (any may be empty):

- `type` — one of `Summary`, `Investigation`, `Idea`, `Decision`, `Action`.
- `context` — 1–2 sentences describing what prompted the entry.
- `key_points` — list of strings (bullets).
- `sources` — list of strings (links, files, chat refs).
- `next` — list of strings (follow-up actions).

## Output

A single markdown string, suitable for the Notion page body. Always emits all four section headings, even when a section is empty (write `_(none)_` instead of omitting — keeps entries scannable).

## Template

```markdown
## Context
{context or "_(none)_"}

## Key points
- {key_points[0]}
- {key_points[1]}
...

## Sources
- {sources[0]}
...

## Next
- {next[0]}
...
```

When a list is empty, render a single `- _(none)_` bullet.

## Rules

- **Stateless.** No config reads, no Notion calls — pure transformation.
- **Do not invent content.** If a field is empty, render the placeholder — never fabricate.
- **Preserve user wording.** Do not rewrite or summarize bullets beyond trimming whitespace.
- **Type-specific hints** (suggestions only, caller decides):
  - `Summary`: `key_points` = decisions/outcomes; `next` = open questions and follow-ups.
  - `Investigation`: `key_points` = findings; `sources` = every URL / doc consulted.
  - `Decision`: `context` = the question; `key_points` = the choice + rationale.
  - `Action`: `next` = concrete steps with owner/date if known.
  - `Idea`: free-form; other sections optional.
