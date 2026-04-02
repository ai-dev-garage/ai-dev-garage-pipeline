# Agent model alignment — reference

## Effort level to model mapping

The `models` section in project config defines three tiers:

| Effort level | Default model | Typical use |
|---|---|---|
| `low` | `haiku` | Analysis, classification, gap clarification, test fixes |
| `medium` | `sonnet` | Planning, finalization, code review |
| `high` | `inherit` | Complex implementation, architectural decisions |

## Valid model values

The `model` field in agent frontmatter accepts:

- **Aliases:** `haiku`, `sonnet`, `opus`
- **Full model IDs:** e.g. `claude-haiku-4-5-20251001`, `claude-sonnet-4-6`, `claude-opus-4-6`
- **`inherit`:** Use the same model as the parent conversation (default)

## Agent frontmatter example

```yaml
---
name: jira-task-analysis
description: Analyze Jira ticket hierarchy and produce task analysis.
effort_level: low
model: haiku
---
```

After running `agent-model-alignment` with `models.low: sonnet`, the frontmatter becomes:

```yaml
---
name: jira-task-analysis
description: Analyze Jira ticket hierarchy and produce task analysis.
effort_level: low
model: sonnet
---
```

## Frontmatter patching rules

- Only modify the `model` field.
- Use exact YAML replacement to avoid reformatting.
- If `model` field does not exist in frontmatter, add it after `effort_level`.
- If frontmatter uses flow style (`{key: value}`), switch to block style for the patched file.

## Config location

Model mapping is read from:

1. `{PROJECT_ROOT}/.ai-dev-garage/project-config.yaml` → `models:` section
2. `~/.config/ai-garage/config.yaml` → `models:` section (fallback)

If neither has a `models:` section, the caller applies defaults (`low: haiku`, `medium: sonnet`, `high: inherit`) before invoking this skill.
