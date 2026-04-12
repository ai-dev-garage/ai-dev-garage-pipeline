---
name: assistant:summarize
description: Summarize the current session — decisions, outcomes, open questions, next steps — and publish a `Summary` entry to the Notion Assistant Inbox. Confirms the draft before writing.
argument-hint: optional `session=<name>` and/or `tags=<t1,t2>`
---

User input:

```
$ARGUMENTS
```

## Outline

1. Parse optional `session=<name>` and `tags=<csv>` from `$ARGUMENTS`.
2. Resolve the `session-summarizer` agent from `${CLAUDE_PLUGIN_ROOT}/agents/session-summarizer.md`.
3. Assume that agent role. Pass through the parsed inputs.
4. The agent drafts the entry and hands off to `notion-publisher`, which confirms the draft with the user before writing.
5. Report the created page URL when done.
