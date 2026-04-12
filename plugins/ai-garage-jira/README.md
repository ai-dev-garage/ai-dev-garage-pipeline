# Jira extension

Optional AI Dev Garage extension: Jira ticket lookup and task-analysis workflow.

## Configure Jira access

REST calls need a **site base URL** and an **API token**. Full precedence (env vars, `jira.env` files, gitignore): see **`skills/jira-item-fetcher/references/REFERENCE.md`** in this extension.

**Quick start**

1. Copy **`jira.template.env`** in this folder to **`jira.env`** at **`~/.config/ai-garage/`** or **`<project>/.config/ai-garage/`**, then fill in values. The template may gain optional keys over time; merge new commented lines when you update the extension.
2. Create an Atlassian API token (link in **`skills/jira-item-fetcher/references/REFERENCE.md`**).
3. Alternatively export **`JIRA_BASE_URL`** and **`JIRA_API_TOKEN`** in the environment (no file).
4. Keep **`jira.env`** out of git (the pipeline **`.gitignore`** ignores that filename; **`jira.template.env`** is committed as documentation).

Agents such as **`jira-task-analysis`** and ad-hoc user requests both use the **`jira-item-fetcher`** skill; credential rules are the same.

## Phase sync (optional)

When enabled, the **`jira-phase-sync`** skill mirrors WBS phases as Jira sub-tasks and transitions their statuses as the delivery workflow progresses. The agent drives sub-tasks through the board; only **Done** remains human-controlled.

**Enable in `project-config.yaml`:**

```yaml
integrations:
  jira:
    sync-phases: true
    subtask-type: "Sub-task"          # match your project's sub-task issue type
    transitions:
      phase-started: "In Progress"    # agent starts a phase
      phase-implemented: "Need Review"  # implement-task finishes
      review-started: "In Review"     # code quality review begins
      phase-ready: "Ready"            # quality review passes, phase DONE in WBS
```

Set any `transitions.*` value to `null` to skip that event. This adapts to any board layout — from a simple 3-column board to a detailed review pipeline.

See **`skills/jira-phase-sync/SKILL.md`** for full details.
