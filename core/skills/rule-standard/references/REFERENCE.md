# Rule standard — reference

Criteria for creating, updating, or reviewing pipeline rules under AI Dev Garage.

## Purpose

Rules are **always-on or context-specific guidance**: they apply when the description/globs match. They state constraints or conventions the model must follow.

## Caller-supplied paths

| Input | Use |
|-------|-----|
| **`TARGET_RULE_FILE`** | Absolute path to the rule file. |
| **`GARAGE_BUNDLE_ROOT`** | Bundle root; rule = `GARAGE_BUNDLE_ROOT/rules/<name>.md`. |
| **`ASSET_SCOPE`** | `global` \| `extension` \| `project` — commands map this to `TARGET_*`. |

## Frontmatter

- **`description`** (required): When and why the rule applies.
- **`globs`** (optional): Comma-separated file patterns if the rule is file-scoped.
- **`alwaysApply`** (optional, boolean): If true, applied every time regardless of context.

## Structure

- Short title.
- Numbered or bullet list: what to do (e.g. check file X, read and follow, or do not create unless asked).
- Single concern per rule; split if mixing unrelated topics.

## When to use rule vs skill vs agent

- **Rule:** Always-on or context-triggered constraint; no multi-step workflow; no user interaction.
- **Skill:** Reusable transformation or procedure invoked by an agent/command.
- **Agent:** Full flow, user interaction, persistence.

## File format

- **`.md` with frontmatter** for all Garage rules.

## Review checklist

- [ ] `description` present and specific
- [ ] Single concern (split if not)
- [ ] No workflow steps or user interaction in the body
- [ ] Caller-supplied `TARGET_RULE_FILE` / `GARAGE_BUNDLE_ROOT` respected (no hardcoded path)
