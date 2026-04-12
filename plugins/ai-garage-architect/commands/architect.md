---
name: architect
description: Entry for architecture work — advisory discussion, design review, or producing ADRs. Delegates to the architect agent. Entry only.
argument-hint: <topic-or-request> [jira=<KEY-or-URL>] [intent=advisory|produce|review]
---

User input:

```
$ARGUMENTS
```

## Outline

1. **Help branch.** If `$ARGUMENTS` is `help`, `-h`, or `--help`, print a one-paragraph description and the argument hint, then stop. Do not run the main flow.
2. **Parse** `$ARGUMENTS` — free-form topic/request plus optional `jira=<key|url>` and `intent=<advisory|produce|review>` keys.
3. **Resolve target project.** Use `PROJECT_ROOT` from the session. If absent, ask the user once and stop if they decline.
4. **Load the orchestrator.** Resolve the `architect` agent at `${CLAUDE_PLUGIN_ROOT}/agents/architect.md`. Assume that role.
5. **Run.** Pass the parsed inputs (topic, optional Jira reference, intent hint) to the agent. The agent owns state detection, context gathering, intent framing, research fan-out, synthesis, review gate, production, and verification.
6. **Report.** When the agent finishes, surface written artifact paths and the verification result (if run).
