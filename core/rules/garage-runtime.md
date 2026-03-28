---
description: AI Dev Garage runtime — discover shared agents/commands/skills, load memory, prefer project overrides. Applies in Cursor and Claude Code when rules are symlinked from ~/.ai-dev-garage/rules.
alwaysApply: true
---

# AI Dev Garage runtime

When assisting in a workspace that uses **AI Dev Garage**:

## Layout (after install)

- Global runtime: `~/.ai-dev-garage/` with `agents/`, `commands/`, `skills/`, `rules/`, `memory/`.
- Cursor and Claude Code use **symlinks** from `~/.cursor/*` and `~/.claude/*` into those folders (same content).

## Project overrides

If the project has `.ai-dev-garage/`, treat it as **higher priority** than global for the same asset types when paths exist under the project.

## Memory priority

1. `<PROJECT_ROOT>/.ai-dev-garage/memory/*.md` (if present)
2. `~/.ai-dev-garage/memory/*.md`

Later layers override earlier where they conflict.

## Suggested flow (complex tasks)

1. **Classify** — use agent `classifier.md` (or `/plan` entry) to label the task.
2. **Plan** — use `planner.md` for steps, agents, success criteria; confirm with the user.
3. **Execute** — use `executor.md` after confirmation.
4. **Review** — use `reviewer.md` against success criteria.
5. **Summarize** — use `summarizer.md` for checkpoints.

For small tasks, skip steps as appropriate.

## Skills

- Use **task-router** (`skills/task-router/SKILL.md`) for stateless classification hints when invoked by `classifier.md`.

## Rules

- Prefer **markdown + YAML frontmatter** assets only; no tool-specific JSON schemas required for garage assets.
- Do not overwrite `memory/decision-log.md` unless the user explicitly asks (append-only).
