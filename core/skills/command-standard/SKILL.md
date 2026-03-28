---
name: command-standard
description: Create, update, or review a command against AI Dev Garage standards. Covers frontmatter, thin vs self-contained flow, help handling, entry-point only, and passing asset target paths (global vs extension) into agents. Use with /ai-dev-garage:create-command, /ai-dev-garage:review-command, or when editing commands by hand.
argument-hint: command_name or path
---

# Command standard (create, update, and review)

Use this skill to **create**, **update**, or **review** a **command** (palette entry). Full criteria, path tables, and templates are in **[references/REFERENCE.md](references/REFERENCE.md)**—load that file when applying this skill.

## Input

- Command name or path (for review or update); or a description of the new command (for create).
- For **authoring** `create-*` / `update-*` / `review-*` commands: how the command resolves **`ASSET_SCOPE`** (`global` \| `extension` \| `project`) into **`TARGET_*`** paths and passes them into the loaded agent (see REFERENCE.md).

## Output

- **Create:** Proposed command content (frontmatter, outline).
- **Update:** Section-level or diff-style edits; do not apply unless the user confirms.
- **Review:** Violations and proposed fixes; do not apply unless the user confirms.

## Mandatory checks (every create / update / review)

Apply to the target command’s **`*.md`**:

1. **No worked examples in the command file** — no long sample invocations or pasted outputs; put usage samples in **`references/`** beside the command only if the repo packages commands as folders (Garage default is a single markdown file per command).
2. **No multiline runnable scripts in the command file** — prose outline only; automation lives in install scripts or **`scripts/`** outside the command body.
3. **Frontmatter:** **Required:** `name`, `description`. Description should say **entry only** when the command delegates to an agent.
4. **Help:** The outline must document handling **`help`**, **`-h`**, **`--help`** (descriptive notes + usage; do not run the main flow).
5. **Thin commands:** Only resolve project, load agent, pass **`$ARGUMENTS`** through—no duplicate agent workflow.
6. **Paths:** Outlines must **derive paths from explicit inputs** (`PROJECT_ROOT`, config path if any, **`GARAGE_SEARCH_ROOTS`** or per-step resolved paths). **No hardcoded** home directory or repo `core/...` strings as the only way to load agents—commands map **scope → bundle root → file path** per REFERENCE.md. (Memory-specific paths remain **out of scope** until memory assets return.)

## Mode

- **Create:** New palette command from description and REFERENCE.md patterns.
- **Update:** Align an existing command with help, paths, and thin vs self-contained rules.
- **Review:** Audit only; list gaps; do not apply unless the user confirms.

---

## Create flow

1. **Name:** Verb-noun or noun, lowercase, hyphenated; align with filename.
2. **Frontmatter:** `name`, `description` (one sentence; “entry only” when delegating).
3. **Structure:** User input (`$ARGUMENTS`) → numbered outline. **Thin:** (1) Help branch, (2) Resolve target project, (3) Load orchestrator (agent path, assume role, run workflow). **Self-contained:** (0) Help, (1) Resolve project, (2)…(N) full flow.
4. **`create-*` / `update-*` / `review-*`:** The command must **compute and pass** the target location (e.g. **`TARGET_SKILL_DIR`**, **`TARGET_AGENT_FILE`**, **`GARAGE_BUNDLE_ROOT`**) into the orchestrator prompt or agent inputs. **Global** vs **extension** is resolved here, not inside the standard skills.

---

## Update flow

1. Read the command file and **references/REFERENCE.md** (this standard).
2. Re-run **Mandatory checks**; fix help, paths, and thin-command leakage.
3. Present edits; do not apply unless the user confirms.

---

## Review flow

1. Read **references/REFERENCE.md** and the target command.
2. **Mandatory checks** from above.
3. **Frontmatter** and **structure** (thin vs self-contained).
4. **Paths** and **no duplicated agent flow**.
5. **Present:** Issues and proposed edits; do not apply unless the user confirms.
