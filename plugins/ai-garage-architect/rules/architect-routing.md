---
description: >-
  Always-on when the ai-garage-architect plugin is installed. When the user's request
  references architecture work, route through the architect agent and do not write any
  architecture artifacts before the user confirms the synthesis.
alwaysApply: true
---

# Architect routing

When the user's request mentions any of: `ADR`, `architecture`, `design review`, `trade-off`, `component spec`, `diagram`, `C4`, `NFR`, `architect`, `tech design`, or matches a "compare X vs Y" intent pattern in a technical context:

1. Route the request to the `architect` agent (via `/ai-garage-architect:architect` or direct agent load).
2. Do **not** write any ADR, diagram, or architecture document before the architect agent's review gate has been passed and the user has explicitly approved the synthesis.
3. When a Jira ticket URL or key accompanies an architecture request, load the ticket context through the architect agent (step 2 of its workflow), not via a separate parallel flow.
4. Credentials for any integration used during context gathering (Jira, future GitHub / Confluence loaders) come from environment variables or gitignored env files resolved by the respective skills — never ask the user to paste tokens in chat.
