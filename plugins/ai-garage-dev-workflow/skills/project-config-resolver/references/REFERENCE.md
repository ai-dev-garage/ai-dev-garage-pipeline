# Resolve project config — reference

## Config file location

Canonical paths (preferred for all new installs):

- **Project:** `{PROJECT_ROOT}/.ai-dev-garage/project-config.yaml`
- **Global:** `~/.ai-dev-garage/config.yaml`

Legacy paths (still read for backwards compatibility; `config-merger` prints a one-line deprecation warning on hit and migrates the **write target** to the canonical path on next write):

- `~/.config/ai-garage/config.yaml` (global legacy)
- `{PROJECT_ROOT}/.ai-dev-garage/config.yaml` (filename variant)

Override the resolved path for tests or scripts by setting `AI_GARAGE_CONFIG` to an absolute path.

## Config file schema

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

1. **`AI_GARAGE_CONFIG` env override** (absolute path).
2. **Project config** — canonical `{PROJECT_ROOT}/.ai-dev-garage/project-config.yaml`; falls through to legacy `{PROJECT_ROOT}/.ai-dev-garage/config.yaml` on read if canonical is absent.
3. **Global config** — canonical `~/.ai-dev-garage/config.yaml`; falls through to legacy `~/.config/ai-garage/config.yaml` on read.
4. **Environment variables** — for credentials only (e.g. `JIRA_API_TOKEN`).
5. **Interactive self-recovery** — last resort; writes answer back via `config-merger set` to the canonical file.

All path resolution is delegated to `ai-garage-core:config-merger`. Consumers should not reimplement lookup order.

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
