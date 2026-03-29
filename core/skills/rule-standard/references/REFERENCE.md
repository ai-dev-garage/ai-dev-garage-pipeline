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

## Secrets & credentials (rule body)

Rules are **not** allowed to become interactive workflows, but their **text** may constrain how the model handles APIs and config. When a rule touches integrations or secrets:

- The rule must **not** tell the model to ask the user to paste passwords, API tokens, or private keys in chat.
- Prefer language that requires reading secrets from **environment variables** and/or **gitignored local env files** (e.g. `$BUNDLE_ROOT/skills/<skill-name>/<skill-name>.env`). Precedence: env → project bundle → global bundle (unless stated otherwise).
- Optional: remind authors that project **`.gitignore`** should ignore real env files while allowing **`*.template.env`** (e.g. `.env` + `*.env` + `!*.template.env`).

## Pipeline source boundary (rules in core and extensions)

- Rules under **`core/rules/`** or **`extensions/<id>/rules/`** must not instruct the model to treat paths or repos **outside** the pipeline’s **`core/`** and **`extensions/`** trees as required reading for Garage behavior.
- **Cross-extension** coupling is unsupported for now: a rule must not mandate loading another extension’s rules/skills as a hard dependency.

## File format

- **`.md` with frontmatter** for all Garage rules.

## Review checklist

- [ ] `description` present and specific
- [ ] Single concern (split if not)
- [ ] No workflow steps or user interaction in the body
- [ ] If the rule covers tools/APIs/config: **no** chat solicitation of secrets; align with **Secrets & credentials** above
- [ ] **Pipeline boundary:** for `core/` / `extensions/` sources, no mandatory out-of-tree or cross-extension asset references (see **Pipeline source boundary** above)
- [ ] Caller-supplied `TARGET_RULE_FILE` / `GARAGE_BUNDLE_ROOT` respected (no hardcoded path)
