---
name: agent-model-alignment
description: Read model effort mappings from project or global config and patch the model field in agent frontmatter files. Use when model preferences change.
argument-hint: dry-run (optional, preview changes without writing)
---

# Agent model alignment

## When to use

- After plugin installation or update resets agent files to defaults.
- When the user changes model preferences in `project-config.yaml` or `config.yaml`.
- Manually via the `/ai-dev-garage:align-models` command.

## Instructions

### 1. Load model mapping

Use the caller-provided model mapping (`models.low`, `models.medium`, `models.high`).

If no mapping is provided, apply defaults: `low: haiku`, `medium: sonnet`, `high: inherit`.

### 2. Discover installed agents

Scan agent files in the target bundle root(s):

- `{${CLAUDE_PLUGIN_ROOT}}/agents/*.md`

For each agent file, read its YAML frontmatter.

### 3. Determine effort level per agent

Check the agent's frontmatter for an `effort_level` field (values: `low`, `medium`, `high`).

- If `effort_level` is present, map it to the corresponding model from the config.
- If `effort_level` is absent, skip the agent (do not modify agents without explicit effort classification).

### 4. Patch model field

For each agent with a mapped effort level:

- If the agent's `model` field already matches the target, skip.
- Otherwise, update the `model` field in the frontmatter to the mapped value.
- Preserve all other frontmatter fields and the body unchanged.

### 5. Report changes

Output a summary:

- Agents updated (name, old model, new model).
- Agents skipped (no `effort_level` or already correct).

If `dry-run` argument is provided, report what would change without writing.

## Input

- `${CLAUDE_PLUGIN_ROOT}` — path to the bundle root containing agents to align.
- Model mapping (`models.low`, `models.medium`, `models.high`) — from caller.
- `dry-run` (optional) — preview mode, no writes.

## Output

- Summary of changes made (or previewed in dry-run mode).

## Rules

- Never modify agents without an explicit `effort_level` field.
- Preserve all frontmatter fields other than `model`.
- Preserve the full markdown body unchanged.
- Model mapping reference: see [REFERENCE.md](references/REFERENCE.md).
