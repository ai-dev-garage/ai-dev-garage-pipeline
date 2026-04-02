---
name: skill-standard
description: Create, update, or review a skill against AI Dev Garage standards. Enforces layout (SKILL.md, scripts/, references/, assets/), no examples in SKILL.md, no embedded multiline scripts, caller-supplied target paths (global vs extension vs project). Use with /ai-dev-garage:create-skill, /ai-dev-garage:review-skill, or when editing skills by hand.
argument-hint: skill_name or path; target dir or scope from create-* command
---

# Skill standard (create, update, and review)

Use this skill to **create** a new skill, **update** an existing one, or **review** one against the standards. Detailed criteria, field tables, and copy-paste templates live in **[references/REFERENCE.md](references/REFERENCE.md)**—load that file when applying this skill.

## Input

- Skill name or path (for review or update); or a description of the new skill (for create).
- **Where the asset lives or will be written** — never infer from this skill alone. The caller (**`create-*` / `update-*` / `review-*` command** or parent agent) must pass at least one of:
  - **`TARGET_SKILL_DIR`** — absolute path to the skill package root (the folder that will contain `SKILL.md`), or
  - **`${CLAUDE_PLUGIN_ROOT}`** — absolute path to a bundle root plus the skill name, so the package path is **`${CLAUDE_PLUGIN_ROOT}/skills/<name>/`**.
- Optional context: **`ASSET_SCOPE`** (`plugin` \| `project`) so explanations match intent; the command maps scope to the paths above.

## Output

- **Create:** Proposed directory layout and file contents (SKILL.md + optional `references/`, `scripts/`, `assets/`).
- **Update:** Diff-style or section-level edits; do not apply unless the user confirms.
- **Review:** List of violations and proposed fixes; do not apply unless the user confirms.

## Mandatory checks (every create / update / review)

Apply these to the target skill’s **SKILL.md** and folder layout:

1. **No worked examples in SKILL.md** — no sample outputs, no long “for example …” blocks, no pasted API responses. Put examples in **`references/`** (e.g. `references/REFERENCE.md`, `references/examples.md`) or **`assets/`** (templates, JSON, fixtures). SKILL.md may link to those files in one line each.
2. **No multiline scripts or shell in SKILL.md** — no fenced `bash`/`sh` blocks meant to be run as-is, no long inline code. Put executable or multiline logic under **`scripts/`** and reference paths like `scripts/run.sh` from SKILL.md.
3. **Canonical layout** — each skill is a directory with required **`SKILL.md`**. Prefer optional **`scripts/`**, **`references/`**, **`assets/`** as needed (same idea as `.cursor/skills/<name>/` / `.claude/skills/<name>/` in [Cursor docs](https://cursor.com/docs/skills)).
4. **`references/` vs `assets/`** — use **[references/REFERENCE.md](references/REFERENCE.md)** (“references/ vs assets/”): put material in **`references/`** when the agent must always use it and it affects reasoning, decision order, or output shape; put material in **`assets/`** when it is optional, large, example-heavy, schema/template, or lookup-style.
5. **No hardcoded install or repo roots** in proposed `SKILL.md` / layout — paths are always relative to **`TARGET_SKILL_DIR`** or **`${CLAUDE_PLUGIN_ROOT}`** from the caller (see REFERENCE.md).
6. **Secrets and credentials** — The skill must **never** ask the user to paste or type passwords, API tokens, or private keys in chat. Tooling may **read** secrets from the environment or from local files; it must **not solicit** them in conversation. If the skill depends on secrets, **`references/`** must document named **environment variables** and/or a **`.env` file workflow** (gitignored real file, copy from template). Committed templates belong only under **`assets/`** (e.g. `assets/<skill-name>.template.env`). Installed-bundle paths and precedence: **[references/REFERENCE.md](references/REFERENCE.md)** (“Secrets & credentials”).
7. **Plugin boundary** — Skills shipped from a plugin must not require or hard-depend on **source assets outside** that plugin’s tree (no other repo, vendor path, or external bundle as a required link target). **Cross-plugin references are unsupported for now:** a plugin skill must not require another plugin’s skills/agents/rules/commands. See **[references/REFERENCE.md](references/REFERENCE.md)** (“Plugin boundary”). Installed-plugin resolution via caller **`${CLAUDE_PLUGIN_ROOT}`** / **`TARGET_SKILL_DIR`** is fine and is not an out-of-plugin *source* dependency.

## Mode

- **Create:** User wants a new skill; propose layout and minimal SKILL.md plus pointers to references/scripts/assets.
- **Update:** User wants to change an existing skill; re-run mandatory checks and align with standards.
- **Review:** User points to an existing skill; report issues only (and optional fixes).

---

## Create flow

1. **Name:** Noun or noun phrase, lowercase, hyphenated. The skill folder name must match frontmatter `name` (Cursor requires this; Claude recommends it). Resolve the folder as **`TARGET_SKILL_DIR`** or **`${CLAUDE_PLUGIN_ROOT}/skills/<name>/`** per caller input.
2. **Frontmatter:** At minimum `name` and `description` (see REFERENCE.md for optional fields: `argument-hint`, `license`, `compatibility`, `metadata`, `disable-model-invocation`, and Claude-specific fields where relevant).
3. **SKILL.md:** Only operational instructions—steps, when to use, links to `references/*` and `scripts/*`. **No examples block; no multiline scripts.**
4. **references/:** Content the agent **must** apply when using the skill: reasoning rules, decision order, output shape; see REFERENCE.md for the full **`references/` vs `assets/`** criteria.
5. **scripts/:** Executable helpers; reference from SKILL.md by relative path only.
6. **assets/:** Optional, large, example-heavy, schema/template, or lookup files; see REFERENCE.md for when to prefer **`assets/`** over **`references/`**. If the skill needs secrets, add **`assets/<skill-name>.template.env`** (placeholders only) when a template helps; document the real file location in **`references/`** per **Secrets & credentials** in REFERENCE.md.
7. **Boundary:** Prefer **stateless** skills (input → output); no user prompts inside the skill unless the product docs explicitly allow and you document it. Callers (agents/commands) own flow and persistence.
8. **No skill-to-skill references** — a skill must not invoke or depend on another skill. If a skill needs data that another skill provides (e.g. config values), declare it as an **Input** and let the calling agent resolve it first. This keeps skills composable and independently testable.

---

## Update flow

1. Read the skill’s `SKILL.md`, `references/*`, and list `scripts/` / `assets/`.
2. Re-apply **Mandatory checks**. Move any examples or long scripts out of SKILL.md into `references/`, `assets/`, or `scripts/` per **references/ vs assets/** in REFERENCE.md.
3. Align frontmatter with REFERENCE.md (Garage + Cursor + Claude compatibility notes).
4. Present edits; do not apply unless the user confirms.

---

## Review flow

1. Read **references/REFERENCE.md** in this skill folder (the standard’s own reference) and the target skill’s files.
2. **Mandatory checks:** fail if examples or multiline runnable scripts live in SKILL.md.
3. **Layout:** Required `SKILL.md`; optional `scripts/`, `references/`, `assets/` used appropriately. Check **references/ vs assets/** (REFERENCE.md): “always know / reasoning / order / format” → `references/`; optional, large, examples, schema, lookup → `assets/`.
4. **Duplication:** No repeated prose across skills; no workflow steps stuck in `references/` (those belong in SKILL.md).
5. **Bloat:** No option catalogs without decision value.
6. **Caller paths:** Proposed content does not assume a fixed global/repo path without **`TARGET_SKILL_DIR`** / **`${CLAUDE_PLUGIN_ROOT}`** from the caller.
7. **Secrets:** No solicitation of secrets in chat; if secrets are required, **`references/`** vs **`assets/`** split and install-path conventions match REFERENCE.md (“Secrets & credentials”).
8. **Plugin boundary:** No required references outside the plugin's own tree; no cross-plugin hard dependencies (REFERENCE.md “Plugin boundary”).
9. **Present:** Issues and proposed edits; summarize; do not apply unless the user confirms.
