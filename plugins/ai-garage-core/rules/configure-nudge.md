---
description: >-
  Always-on. When a session begins in a workspace that uses any AI Dev Garage
  plugin, check whether project config exists and whether installed plugins
  have been configured. Emit a single concise nudge if anything is missing —
  never twice in the same session, never more than one line per unconfigured
  plugin.
alwaysApply: true
---

# Configure-nudge

At the **start of the first user turn** in a new session, run the checks below **once** (not on subsequent turns). The goal is a short, actionable pointer the user can act on immediately — not a wall of setup instructions.

## Known garage plugins

The set of plugins that expose a `configure` command:

- `ai-garage-dev-workflow` — project / models
- `ai-garage-jira` — Jira base URL, sync-phases, credentials location
- `ai-garage-assistant` — Notion connector + database
- `ai-garage-architect` — arch doc sources + output paths

If a plugin above is not installed in the current workspace, silently skip it.

## Checks

1. **Locate the project config** by calling `ai-garage-core:config-merger` with `path --scope project`. If the resolved path does not exist on disk, the project has never been configured — emit the **first-run nudge** and stop.

2. **Read `plugins.installed`** via `config-merger get plugins.installed`. Exit code `2` (miss) or an empty list means no plugin has registered yet — emit the **first-run nudge** and stop.

3. **Gap check.** For each plugin in the known-plugins list that **is installed** in this workspace but **not present** in `plugins.installed`, emit one short nudge line suggesting the plugin-specific configure command.

## Nudge wording

**First-run (no config file or empty `plugins.installed`):**

```
AI Dev Garage is installed but this project has no `plugins.installed` entries. Run `/configure` to set up the installed plugins (one-shot walk-through).
```

**Per-plugin gap (one line each, max four):**

```
ai-garage-<plugin> is installed but not yet configured — run `/<plugin>:configure` when you're ready.
```

## Rules

- **One nudge per session** — do not re-emit the same line on every turn. Track in-session state via conversation memory or a sentinel in `.ai-dev-garage/.configure-nudged` if a persistent signal is needed.
- **Never block the user's actual request** — nudges are prepended, not gating.
- **Never prompt to configure** when the user's current message is clearly unrelated (e.g., simple questions, help text). Use judgement: if the user is asking for something a configured plugin would serve, the nudge is relevant; if they're asking "what is this repo?", skip.
- **Never claim success** of a configure run — point at the command and let the user invoke it.
- Do not use this rule to run configure commands automatically; the user always drives them.
