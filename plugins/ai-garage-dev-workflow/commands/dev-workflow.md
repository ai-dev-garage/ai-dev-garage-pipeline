---
name: dev-workflow
description: Entry only — shows all dev-workflow capabilities and routes to the deliver-task agent for task delivery.
---

User input (pass through to the agent):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, print the capability map below and stop:

   **Dev Workflow — Task Delivery Pipeline**

   | Command | Description |
   |---|---|
   | `update-constitution` | Create or update the project constitution |

   | Agent | Description |
   |---|---|
   | `deliver-task` | Full lifecycle: analyze → plan → implement → finalize |
   | `implementation-planner` | Build or update a WBS for a task |
   | `implement-task` | Execute WBS items with parallel support |
   | `finalize-task` | Produce a delta report after implementation |

   | Skill | Description |
   |---|---|
   | `project-config-resolver` | Read/recover project configuration |
   | `feature-branch-guard` | Switch to or create the task branch |
   | `test-failure-fixer` | Diagnose and fix test failures (up to 5 retries) |
   | `change-publisher` | Analyze, split, commit, and push changes |
   | `task-gap-clarification` | Interactively resolve analysis gaps |
   | `code-implementation` | Implement code with constitution compliance |

   **Usage:** Provide a task key (e.g. `PROJ-1234`) or say "deliver", "plan", "implement", "finalize" to route to the appropriate agent.

2. Resolve `PROJECT_ROOT` from `project=<path>` in user input if present; otherwise use the current workspace root.
3. Resolve the deliver-task agent from `${CLAUDE_PLUGIN_ROOT}/agents/deliver-task.md`. Assume that agent role and run its workflow, passing `$ARGUMENTS` as the task context.
