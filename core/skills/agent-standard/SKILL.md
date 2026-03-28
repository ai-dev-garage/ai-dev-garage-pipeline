---
name: agent-standard
description: Create, update, or review an agent against AI Dev Garage standards. Covers frontmatter, workflow structure, naming, parameterized bundle-root resolution, and agent vs skill vs command. Caller supplies target paths (global vs extension vs project). Use with /ai-dev-garage:create-agent, /ai-dev-garage:review-agent, or when editing agents by hand.
argument-hint: agent_name or path; target path or scope from create-* command
---

# Agent standard (create, update, and review)

Use this skill to **create**, **update**, or **review** an **agent** (orchestrator or subagent). Full field tables, templates, and examples are in **[references/REFERENCE.md](references/REFERENCE.md)**—load that file when applying this skill.

## Input

- Agent name or path (for review or update); or a description of the new agent (for create).
- **Where the asset lives or will be written** — supplied by the **`create-*` / `update-*` / `review-*` command** or parent agent, not guessed from this skill:
  - **`TARGET_AGENT_FILE`** — absolute path to the agent `*.md` file, or
  - **`GARAGE_BUNDLE_ROOT`** + agent name → **`GARAGE_BUNDLE_ROOT/agents/<name>.md`**.
- Optional: **`ASSET_SCOPE`** (`global` \| `extension` \| `project`); **`GARAGE_SEARCH_ROOTS`** — ordered list of bundle roots for resolution rules in the drafted agent body.

## Output

- **Create:** Proposed agent file(s): frontmatter, body sections, rules.
- **Update:** Section-level or diff-style edits; do not apply unless the user confirms.
- **Review:** Violations and proposed fixes; do not apply unless the user confirms.

## Mandatory checks (every create / update / review)

Apply to the target agent’s **`*.md`** file:

1. **No worked examples in the agent file** — no long sample Jira bodies, pasted tickets, or golden outputs. Put samples under the agent’s repo skill package in **`references/`** or **`assets/`** if the agent ships as a folder; for a single-file agent, keep examples out of the main file or attach a sibling `references/` doc.
2. **No multiline scripts in the agent file** — automation belongs in **`scripts/`** next to the agent only if the repo packages agents that way; otherwise keep agent files prose-only.
3. **Frontmatter:** **Required:** `name`, `description`. **Recommended:** `skills`, `inputs`, `outputs`. **Optional:** `model`, `tags`, `constraints`, and tool-specific fields documented in REFERENCE.md. `name` must match the filename stem.
4. **Paths:** Drafted agents must describe resolution using **caller-defined bundle roots** (e.g. ordered **`GARAGE_SEARCH_ROOTS`** or equivalent), not a single hardcoded global path. See REFERENCE.md.
5. **`references/` vs `assets/`** for any bundled agent package — same rules as [skill-standard references/REFERENCE.md](../skill-standard/references/REFERENCE.md#references-vs-assets-what-goes-where).

## Mode

- **Create:** New orchestrator or subagent from description and REFERENCE.md template.
- **Update:** Align an existing agent with current frontmatter and workflow conventions.
- **Review:** Audit only; list gaps and misplacements (examples in body, missing recommended fields, wrong paths).

---

## Create flow

1. **Name:** Verb-noun, lowercase, hyphenated; filename `<name>.md` must match frontmatter `name`.
2. **Frontmatter:** Fill required and recommended fields per REFERENCE.md; declare **`skills`** as the authoritative list of skill dependencies.
3. **Body:** Role → **Workflow** (numbered steps: Goal, Action, Output) → **Rules** (gates, persistence, resolution). Subagents add **When invoked**.
4. **Rules:** Review gate, “do not persist until confirm” when applicable, **skill/agent search order over the bundle roots the command provides** (document variable names, not literal paths).

---

## Update flow

1. Read the agent file; open **references/REFERENCE.md** (this standard).
2. Re-run **Mandatory checks**; move examples out; add missing frontmatter keys where appropriate.
3. Align path wording with **parameterized bundle roots** from the caller.
4. Present edits; do not apply unless the user confirms.

---

## Review flow

1. Read **references/REFERENCE.md** (this standard) and the target agent.
2. **Mandatory checks** from above.
3. **Frontmatter:** required/recommended/optional completeness; `name` vs filename.
4. **Structure:** Workflow steps present; Rules cover persistence and paths.
5. **Boundaries:** Orchestration vs skill vs command (see REFERENCE.md).
6. **Caller paths:** Draft does not rely on one hardcoded install path without **`TARGET_AGENT_FILE`** / **`GARAGE_BUNDLE_ROOT`** / **`GARAGE_SEARCH_ROOTS`** from the caller.
7. **Present:** Issues and proposed edits; do not apply unless the user confirms.
