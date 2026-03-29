# Resolve project config — reference

## Config file schema

The project config file lives at `{PROJECT_ROOT}/.ai-dev-garage/project-config.yaml` (project-level) or `~/.ai-dev-garage/config.yaml` (global fallback).

```yaml
project:
  name: "my-service"              # Project/service identifier
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
```

## Resolution order

1. **Project config** (`{PROJECT_ROOT}/.ai-dev-garage/project-config.yaml`) — highest priority.
2. **Global config** (`~/.ai-dev-garage/config.yaml`) — fallback for keys not in project config.
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

All other keys have no default and must be provided by the user or left as `null`.

## Credential handling

Secrets (`api-token`) should preferably be stored as environment variables rather than in config files. The skill checks env vars first, then config files, and only asks the user as a last resort. When writing credentials to config, suggest the user switch to env vars for security.

## Validation rules

| Key | Validation |
|-----|-----------|
| `project.docs-path` | Path exists on disk |
| `project.build-command` | Non-empty string |
| `project.test-command` | Non-empty string |
| `models.*` | One of: `haiku`, `sonnet`, `opus`, `inherit`, or a full model ID |
| `integrations.jira.base-url` | Starts with `https://` |
