# Command standard — reference

Criteria for **create / update / review** of pipeline commands under AI Dev Garage.

## Purpose

Commands are **entry points**: invoked from the Cursor command palette (or equivalent). They pass user input through and either **(a)** resolve context and load an agent, or **(b)** run an inline numbered flow.

## Asset scope and target paths (`create-*` / `update-*` / `review-*`)

**Standard skills** do not choose where files live. **`create-*` commands** (and similar) must:

1. Parse **`ASSET_SCOPE`**: **`global`** (user-global bundle), **`extension`** (named extension’s bundle), or **`project`** (project-local bundle).
2. Resolve to concrete roots using **installer/config rules** (this REFERENCE does not hardcode directory names or pipeline `core/...` paths).
3. Pass into the loaded agent at least one of:
   - **`TARGET_SKILL_DIR`**, **`TARGET_AGENT_FILE`**, **`TARGET_COMMAND_FILE`**, etc., or
   - **`GARAGE_BUNDLE_ROOT`** + asset kind + name, or
   - **`GARAGE_SEARCH_ROOTS`** (ordered list) when the agent drafts resolution rules.

**Global** means “the bundle that corresponds to shared user install” (whatever path the installer uses). **Extension** means “the bundle subtree for that extension.” **Project** means “project-local override bundle.” Exact paths are **never** the only truth inside a standard skill.

## Path resolution in command outlines (runtime)

Thin commands typically: resolve **`PROJECT_ROOT`** (e.g. `project=<path>` or workspace), resolve **`CONFIG_PATH`** if the install defines a project config file, build **`GARAGE_SEARCH_ROOTS`** (project bundle, then global, then extensions—order from config), then load **`agents/<name>.md`** from the first root that contains it. **Spell this as an algorithm with variables**, not as a single hardcoded path.

**Memory templates / constitution paths** are deferred—do not require them in command outlines until those assets exist.

## Frontmatter (required)

| Field | Purpose |
|-------|---------|
| **name** | Verb-noun or noun, lowercase, hyphenated; align with filename. |
| **description** | One sentence: what the command does; say **entry only** when it delegates to an agent. |

## Structure

- **User input:** `$ARGUMENTS` in a code block; state whether to pass through as-is or consider before proceeding.
- **Help:** When input is **`help`**, **`-h`**, or **`--help`**, respond with descriptive notes (what/when) and usage examples; **do not** run the main flow. Document as step 0 or 1 in the outline.
- **Outline:** Numbered steps.

**Thin** (typical backlog / orchestration):

1. Help branch  
2. Resolve target project (`PROJECT_ROOT`, `CONFIG_PATH` if used, **`GARAGE_SEARCH_ROOTS`**)  
3. Load orchestrator: **resolved** agent file path + “assume that role, run workflow”; pass **`TARGET_*`** / scope into the agent when the flow creates or edits assets

**Self-contained:**

0. Help  
1. Resolve project  
2. … N. Full flow in the command (still avoid duplicating what an agent already owns unless intentional)

## Naming

- Actions: `update-pipeline-asset`, `define-feature`, `create-agent`
- Workflows: `plan`, `implement` (optional)

## Do not

- Interpret or reformat user input in **thin** commands; pass it to the agent.
- Duplicate the agent’s full workflow in a thin command.
- Omit help handling from the outline.

## Copy-paste: thin command skeleton

````markdown
---
name: my-entry
description: Entry only — resolves project and runs the my-orchestrator agent workflow.
---

User input (pass through to the agent):

```
$ARGUMENTS
```

## Outline

1. If arguments are `help`, `-h`, or `--help`, print what this command does, when to use it, and example invocations; stop.
2. Resolve `PROJECT_ROOT` (e.g. `project=<path>` or workspace). Set `CONFIG_PATH` and **`GARAGE_SEARCH_ROOTS`** per install / extension manifest.
3. Resolve path to `agents/my-orchestrator.md` by walking **`GARAGE_SEARCH_ROOTS`** in order. Assume that agent role and run its workflow; pass **`ASSET_SCOPE`** and **`TARGET_*`** when creating or updating assets under a chosen bundle root.
````

## Review checklist

- [ ] `name`, `description` present
- [ ] Help branch documented and correct
- [ ] Thin command does not embed full agent workflow
- [ ] Paths are **derived from inputs** (`PROJECT_ROOT`, **`GARAGE_SEARCH_ROOTS`**, **`TARGET_*`**) — not a single hardcoded install path
- [ ] **`create-*` / `update-*` / `review-*` style commands** pass **scope → target path** into the orchestrator when assets are written
