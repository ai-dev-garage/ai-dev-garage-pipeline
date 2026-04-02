# This is ai-garage-jira playbook.

Available rules:

| Rule Path | Keywords / Triggers | Always-on |
|-----------|-------------------|-----------|
| `{{PLUGIN_ROOT}}/rules/jira-delivery.md` | jira, ticket, issue, sprint, backlog, JIRA_API_TOKEN, task_source=jira | Yes |

**Enforcement:**
- **Always-on = Yes:** These rules are loaded in full at session start (appended below). Follow them throughout the entire session regardless of context.
- **Always-on = No:** When you encounter any keyword or trigger listed above in the user's message or task context, immediately load the corresponding rule file into the current context using the Read tool and follow its instructions.
