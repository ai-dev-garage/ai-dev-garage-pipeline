# AI Dev Garage — plugin marketplace

Portable AI workflow runtime for **Claude Code** and **Cursor**: agents, commands, skills, and rules distributed as native plugins.

## Plugins

| Plugin | Description |
|--------|-------------|
| `ai-garage-core` | Pipeline standards (skill, agent, command, rule), self-management commands, runtime rules |
| `ai-garage-agile` | Agile backlog management — epics, features, stories, acceptance criteria |
| `ai-garage-dev-workflow` | Task delivery pipeline — analyze, plan, implement, finalize |
| `ai-garage-jira` | Jira integration — fetch tickets, hierarchy walking, gap analysis |

## Install — Claude Code

Add the marketplace and install plugins:

```
/plugin marketplace add ai-dev-garage/ai-dev-garage-pipeline
/plugin install ai-garage-core@ai-dev-garage
/plugin install ai-garage-dev-workflow@ai-dev-garage
```

## Install — Cursor

Clone the repo and run the installer:

```bash
git clone git@github.com:ai-dev-garage/ai-dev-garage-pipeline.git
cd ai-dev-garage-pipeline
./install-cursor.sh                    # install all plugins
./install-cursor.sh ai-garage-core     # or specific plugins
```

This creates symlinks from `~/.cursor/plugins/local/` to the repo's `plugins/` directory.

## Repo layout

```
.claude-plugin/marketplace.json    # Claude Code marketplace catalog
.cursor-plugin/marketplace.json    # Cursor marketplace catalog
plugins/
  ai-garage-core/                  # Core plugin
  ai-garage-agile/                 # Agile plugin
  ai-garage-dev-workflow/          # Dev workflow plugin
  ai-garage-jira/                  # Jira plugin
install-cursor.sh                  # Cursor local install script
```

Each plugin follows the standard plugin structure:

```
ai-garage-<name>/
  .claude-plugin/plugin.json       # Plugin manifest
  agents/                          # Agent definitions (.md)
  commands/                        # Slash commands (.md)
  skills/                          # Skills (SKILL.md + references/)
  rules/                           # Always-on rules (.md)
```

## Core flow

1. **Classify** — label the task
2. **Plan** — steps, agents, success criteria; confirm with the user
3. **Execute** — implement after confirmation
4. **Review** — check against success criteria
5. **Summarize** — checkpoint

For small tasks, skip steps as appropriate.

## Project overrides

If a project has `.ai-dev-garage/` at its root, those assets take priority over plugin-provided ones for the same asset types.

## License

MIT — see [LICENSE](LICENSE).
