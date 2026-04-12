# Resolve project config — reference

## Config file schema

The project config file lives at `{PROJECT_ROOT}/.ai-dev-garage/project-config.yaml` (project-level) or `~/.config/ai-garage/config.yaml` (global fallback).

```yaml
project:
  name: "my-service"              # Project/service identifier
  stack: []                        # List of stack identifiers, e.g. [java, spring]
  build-command: "npm run build"  # Shell command to build the project
  test-command: "npm test"        # Shell command to run tests
  docs-path: null                 # Absolute path to documentation folder (HLD/PRD)
  base-branch: "main"             # Default branch for rebasing/merging
  branch-prefix: "feature"        # Branch naming: {prefix}/{TASK-KEY}

models:
  low: haiku                      # Cheap model for analysis, classification, test fixes
  medium: sonnet                  # Mid-tier for planning, finalization
  high: inherit                   # Expensive model for complex implementation

integrations:
  jira:
    base-url: null                # e.g. https://jira.example.com
    api-token: null               # Personal access token (prefer env var JIRA_API_TOKEN)
    sync-phases: false            # Mirror WBS phases as Jira sub-tasks (opt-in)
    subtask-type: "Sub-task"      # Jira issue type name for created sub-tasks
    transitions:                  # Maps dev-workflow events to Jira transition names
      phase-started: "In Progress"      # Agent starts a phase
      phase-implemented: "Need Review"  # implement-task finishes
      review-started: "In Review"       # Code quality review begins
      phase-ready: "Ready"              # Quality review passes, phase DONE in WBS
  assistant:
    notion-mcp-connector: null    # Name of your Notion MCP connector; auto-detected if unique
    notion-database-id: null      # Assistant Inbox database id
    notion-parent-page-id: null   # Used only for first-time DB bootstrap
    default-tags: []              # Tags applied to every entry
    session-prefix: null          # Prepended to the Session property (e.g. project name)
```

Each `transitions.*` value is the Jira transition **name** to search for (case-insensitive substring match). Set to `null` to skip that event. This allows adapting to any board layout.

## Resolution order

1. **Project config** (`{PROJECT_ROOT}/.ai-dev-garage/project-config.yaml`) — highest priority.
2. **Global config** (`~/.config/ai-garage/config.yaml`) — fallback for keys not in project config.
3. **Environment variables** — for credentials only (e.g. `JIRA_API_TOKEN`).
4. **Interactive self-recovery** — last resort; writes answer back to project config.

## Defaults (applied during self-recovery when user provides no preference)

| Key | Default |
|-----|---------|
| `project.base-branch` | `main` |
| `project.branch-prefix` | `feature` |
| `models.low` | `haiku` |
| `models.medium` | `sonnet` |
| `models.high` | `inherit` |
| `integrations.jira.sync-phases` | `false` |
| `integrations.jira.subtask-type` | `"Sub-task"` |
| `integrations.jira.transitions.phase-started` | `"In Progress"` |
| `integrations.jira.transitions.phase-implemented` | `"Need Review"` |
| `integrations.jira.transitions.review-started` | `"In Review"` |
| `integrations.jira.transitions.phase-ready` | `"Ready"` |

All other keys have no default and must be provided by the user or left as `null`.

## Credential handling

Secrets (`api-token`) should preferably be stored as environment variables rather than in config files. The skill checks env vars first, then config files, and only asks the user as a last resort. When writing credentials to config, suggest the user switch to env vars for security.

## Stack auto-detection

When `project.stack` is missing, auto-detect from project files:

| File / Pattern | Detected Stack |
|---|---|
| `pom.xml` or `build.gradle` / `build.gradle.kts` | `java` |
| `pom.xml` with `spring-boot` dependency | `java`, `spring` |
| `package.json` | `node` |
| `requirements.txt` / `pyproject.toml` | `python` |
| `go.mod` | `go` |
| `Cargo.toml` | `rust` |
| `*.xcodeproj` / `Package.swift` | `ios` |

Multiple stacks can coexist (e.g., `[java, spring]`). If detection is ambiguous, ask the user. Write the result back to config.

Stack identifiers are used by agents to resolve stack-specific extension skills via the naming convention `{stack}-{base-skill-name}`.

## Validation rules

| Key | Validation |
|-----|-----------|
| `project.stack` | List of lowercase identifiers |
| `project.docs-path` | Path exists on disk |
| `project.build-command` | Non-empty string |
| `project.test-command` | Non-empty string |
| `models.*` | One of: `haiku`, `sonnet`, `opus`, `inherit`, or a full model ID |
| `integrations.jira.base-url` | Starts with `https://` |
| `integrations.assistant.notion-mcp-connector` | Non-empty string matching an installed MCP connector |
| `integrations.assistant.notion-database-id` | Non-empty string (Notion database id / UUID) |
| `integrations.assistant.default-tags` | List of strings |
