---
name: rule-standard
description: Create, update, or review a pipeline rule against AI Dev Garage standards. Covers frontmatter, single concern, and when to use rule vs skill vs agent. Use with /ai-dev-garage:create-rule, /ai-dev-garage:review-rule, or when editing rules by hand.
argument-hint: rule_name or path; target path or scope from create-* command
---

# Rule standard (create, update, and review)

Use this skill to **create**, **update**, or **review** a **rule**. Full criteria are in **[references/REFERENCE.md](references/REFERENCE.md)** — load that file when applying this skill.

## Input

- Rule name or path (for review or update); or a description of the new rule (for create).
- **Where the asset lives or will be written** — supplied by the caller (`create-*` / `update-*` / `review-*` command or parent agent):
  - **`TARGET_RULE_FILE`** — absolute path to the rule file, or
  - **`GARAGE_BUNDLE_ROOT`** + rule name → `GARAGE_BUNDLE_ROOT/rules/<name>.md`.
- Optional: **`ASSET_SCOPE`** (`global` | `extension` | `project`).

## Output

- **Create:** Proposed rule content (frontmatter, body).
- **Update:** Section-level edits; do not apply unless the user confirms.
- **Review:** List of issues and proposed edits; do not apply unless the user confirms.

## Mandatory checks (every create / update / review)

Apply to the target rule’s **body** (constraints the model must follow—not interactive prompts in the rule file itself):

1. **Single concern** — one topic per rule; split if mixing unrelated guidance.
2. **No multi-step workflows or user interaction** in the rule file — still applies; the rule states *what the model must do*, not a chat script.
3. **Secrets and credentials** — If the rule tells the model how to use tools, APIs, or local config, it must **not** encourage asking the user to paste passwords, tokens, or private keys in chat. It should require **environment variables** and/or **local gitignored** env files (e.g. `$BUNDLE_ROOT/skills/<skill-name>/<skill-name>.env`). This is **content** of the rule, not an exception to “no user interaction.” See [REFERENCE.md](references/REFERENCE.md) (“Secrets & credentials”).
4. **Pipeline source boundary** — Rules shipped from pipeline **`core/`** or **`extensions/<id>/`** must not require the model to load or depend on **source assets outside** **`core/`** + **`extensions/`**. **Core** rules must not hard-depend on any extension’s assets. **Extension** rules must not hard-depend on **another extension’s** bundled files as mandatory context (cross-extension unsupported for now). See [REFERENCE.md](references/REFERENCE.md) (“Pipeline source boundary”).

## Mode

- **Create:** New rule from description and REFERENCE.md criteria.
- **Update:** Align an existing rule with current standards.
- **Review:** Audit only; list gaps; do not apply unless the user confirms.

---

## Create flow

1. **Frontmatter:** `description` (when and why the rule applies). Optional: `globs` (comma-separated), `alwaysApply` (boolean).
2. **Structure:** Short title; numbered or bullet list of what to do. Single concern; split if mixing topics.
3. **Format:** `.md` with frontmatter.
4. **Boundary:** Rule = always-on or context-triggered constraint; no multi-step workflow; no user interaction. Not a skill or agent.
5. **`global` / `project`:** The **`create-rule`** / **`update-rule`** command registers the rule in **`manifest custom:`** via **bundle-custom-manifest** after writes—not here. **`extension:<name>`** skips that.

---

## Update flow

1. Read the rule file and **references/REFERENCE.md**.
2. Re-run **Mandatory checks**; fix single-concern violations or format issues.
3. Present edits; do not apply unless the user confirms.
4. After applied writes to **`global` / `project`**, the caller uses **bundle-custom-manifest** for the rule basename.

---

## Review flow

1. Read **references/REFERENCE.md** and the target rule file.
2. **Mandatory checks** from above.
3. **Frontmatter:** `description` present; `globs` / `alwaysApply` correct if used.
4. **Structure:** Single concern; short, actionable list; no workflow steps that belong in a skill/agent.
5. **Present:** Issues and proposed edits; do not apply unless the user confirms.
