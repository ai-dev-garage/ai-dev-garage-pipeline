---
description: AI Dev Garage runtime — discover shared agents/commands/skills from installed plugins, load memory, prefer project overrides. Applies in Claude Code and Cursor when the ai-garage-core plugin is installed.
alwaysApply: true
---

# AI Dev Garage runtime

When assisting in a workspace that uses **AI Dev Garage**:

## Layout (plugin model)

- Assets (agents, commands, skills, rules) are **discovered automatically** from installed plugins.
- No symlinks needed — Claude Code and Cursor discover plugins natively.
- Each plugin contributes its own `agents/`, `commands/`, `skills/`, `rules/` directories; the host resolves them at startup.

## Project overrides

If the project has `.ai-dev-garage/`, treat it as **higher priority** than plugin-provided assets for the same asset types when paths exist under the project.

## Memory priority

1. `<PROJECT_ROOT>/.ai-dev-garage/memory/*.md` (if present)
2. Plugin-provided memory (if any)

Later layers override earlier where they conflict.

## Suggested flow (complex tasks)

1. **Classify** — use agent `classifier.md` (or `/plan` entry) to label the task.
2. **Plan** — use `planner.md` for steps, agents, success criteria; confirm with the user.
3. **Execute** — use `executor.md` after confirmation.
4. **Review** — use `reviewer.md` against success criteria.
5. **Summarize** — use `summarizer.md` for checkpoints.

For small tasks, skip steps as appropriate.

## Skills

- Use **task-router** (`skills/task-router/SKILL.md`) for stateless classification hints when invoked by `classifier.md`. Resolved from installed plugins automatically.

## Rules

- Prefer **markdown + YAML frontmatter** assets only; no tool-specific JSON schemas required for garage assets.
- Do not overwrite `memory/decision-log.md` unless the user explicitly asks (append-only).
