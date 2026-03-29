---
description: >-
  Always-on when the Jira extension is installed. When work references a Jira
  ticket (URL, key, or ticket-shaped intent), route through deliver-task with
  task_source=jira. Do not write production code before the user confirms the WBS.
alwaysApply: true
---

# Jira delivery routing

When the user provides a Jira ticket URL or key (pattern `[A-Z]+-\d+`), or uses phrases like "deliver", "work on", "implement", "continue", "analyze ticket", "plan the work", or "finalize" in the context of a Jira ticket:

1. Route to the `deliver-task` agent with `task_source=jira` and the extracted ticket key.
2. Never write production code before the WBS is confirmed by the user.
