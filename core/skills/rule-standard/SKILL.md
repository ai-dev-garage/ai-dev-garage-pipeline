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
2. Re-run mandatory checks; fix single-concern violations or format issues.
3. Present edits; do not apply unless the user confirms.
4. After applied writes to **`global` / `project`**, the caller uses **bundle-custom-manifest** for the rule basename.

---

## Review flow

1. Read **references/REFERENCE.md** and the target rule file.
2. **Frontmatter:** `description` present; `globs` / `alwaysApply` correct if used.
3. **Structure:** Single concern; short, actionable list; no workflow steps that belong in a skill/agent.
4. **Present:** Issues and proposed edits; do not apply unless the user confirms.
