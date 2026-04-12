---
name: assistant:investigate
description: Research a topic via web search, external docs, and synthesis of chat context, and publish an `Investigation` entry to the Notion Assistant Inbox. Confirms the draft before writing.
argument-hint: <topic> [depth=quick|standard|deep] [sources=<url1,url2>] [tags=<t1,t2>]
---

User input:

```
$ARGUMENTS
```

## Outline

1. Parse the free-form `topic` and optional `depth`, `sources`, `tags` keys from `$ARGUMENTS`.
2. If no topic is present, prompt the user for one and stop.
3. Resolve the `topic-investigator` agent from `${CLAUDE_PLUGIN_ROOT}/agents/topic-investigator.md`.
4. Assume that agent role. Pass the parsed inputs.
5. The agent researches, drafts the entry, and hands off to `notion-publisher` for confirm-first publish.
6. Report the created page URL when done.
