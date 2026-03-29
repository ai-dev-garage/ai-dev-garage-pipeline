# Agent standard — reference

Criteria, frontmatter, and templates for **create / update / review** of agents under AI Dev Garage. Examples and long samples belong here or in **`assets/`**, not in the agent’s main markdown when avoidable.

## Purpose

Agents are **orchestrators** (or **subagents**): they own multi-step flow, when to ask the user vs proceed, optional **review gates**, and delegation to **skills** or other agents. They are **not** stateless transforms (skills) and not thin palette entries alone (commands).

## Caller-supplied paths (create / update / review)

| Input | Use |
|-------|-----|
| **`TARGET_AGENT_FILE`** | Absolute path to the agent markdown file being created, updated, or reviewed. |
| **`GARAGE_BUNDLE_ROOT`** | Absolute bundle root; agent file = **`GARAGE_BUNDLE_ROOT/agents/<name>.md`**. |
| **`ASSET_SCOPE`** (optional) | `global` \| `extension` \| `project` — commands map this to **`TARGET_*`** paths. |
| **`GARAGE_SEARCH_ROOTS`** (optional) | Ordered list of bundle roots for **runtime** resolution rules embedded in the drafted agent. |

Do not bake pipeline repo paths (e.g. `core/...`) or a single fixed home directory into the **standard**; installers and **`create-*` commands** own that mapping.

## Runtime resolution (wording for drafted agents)

In the agent’s **Rules**, state that loading follows an **ordered search over bundle roots** (e.g. project bundle, then user-global bundle, then extension bundles). Use **placeholders** such as “first root in **`GARAGE_SEARCH_ROOTS`** where `agents/<name>.md` exists” — the command or config file sets the actual list. Same idea for **`skills/<name>/`** under each root.

## Frontmatter (Garage)

| Field | Status | Purpose |
|-------|--------|---------|
| `name` | **required** | Verb-noun, hyphenated; must match filename without `.md`. |
| `description` | **required** | When to use, what it produces; shown in agent pickers. |
| `skills` | **recommended** | YAML list of skill names (directory names under `skills/`) the agent relies on. |
| `inputs` | **recommended** | What the caller passes (e.g. raw user text, `PROJECT_ROOT`, **`GARAGE_SEARCH_ROOTS`**, **`TARGET_*`** from commands). |
| `outputs` | **recommended** | What the agent returns or persists (e.g. definition draft, file path). |
| `model` | optional | e.g. `inherit` for subagents. |
| `tags` | optional | Discovery / grouping. |
| `constraints` | optional | Behavioral boundaries (e.g. “do not persist until user confirms”). |

Optional **tool-specific** fields (use when the product supports them):

| Field | Notes |
|-------|--------|
| `tools` | Cursor / Claude may expose tool allowlists or capability hints—document in your environment. |
| `run_in_parallel` | Cursor-only when applicable. |
| `version` | Optional metadata. |
| `author` | Optional metadata. |

Workflow steps should **name skills in prose** (“Use the **normalize-intent** skill …”) while **`skills` in frontmatter** remains the single manifest of dependencies.

## Body structure

- **Title** (`# …`) and one-line role (“You are the orchestrator for …”).
- **When invoked** (subagents only): parent, phase, inputs.
- **Workflow:** Numbered steps. Each step: **Goal**, **Action** (cite skill names in bold), **Output**.
- **Rules:** Persistence gates, path resolution, error handling, “do not duplicate command flow.”

## Secrets & credentials (agents)

- Agents must **never** instruct the user to paste secrets in chat.
- Delegate secret handling to **skills** that use: named **environment variables**, optional **`assets/<skill-name>.template.env`** (placeholders only, safe to commit), and user-local **`$BUNDLE_ROOT/skills/<skill-name>/<skill-name>.env`** with documented precedence (env → project bundle → global bundle unless stated otherwise).
- In **Rules**, tell the model to read config from those mechanisms only — not from user messages containing credentials.

## Pipeline source boundary (agents in core and extensions)

- No required references to source assets outside **`core/`** and **`extensions/`**.
- **Core** agents must not hard-depend on any extension’s assets. They may rely on **core** only.
- **Extension** agents must not hard-depend on **another extension’s** agents/skills/rules/commands (cross-extension unsupported for now). They may rely on **core** and their own **`extensions/<id>/`** subtree only.
- **`skills` frontmatter** should list only skill names that the install can resolve from **core + that agent’s extension** (or core-only for core agents) — not another extension’s exclusive skills as a required dependency.
- Install-time paths via caller-supplied **`GARAGE_BUNDLE_ROOT`** / **`TARGET_AGENT_FILE`** / **`GARAGE_SEARCH_ROOTS`** are fine and are not out-of-repo source dependencies.

## Naming

- Verb-noun: `define-feature`, `plan-epic`, `scope-clarifier`.
- Avoid two agents owning the same end-to-end workflow; split orchestrator vs subagent clearly.

## When to use agent vs skill vs command

- **Agent:** Multi-step flow, user interaction, review gate, persistence, delegation.
- **Skill:** Stateless input → output; no owning the session flow.
- **Command:** User-facing entry; often thin (resolve project → load agent).

## Copy-paste: minimal agent frontmatter + skeleton

```yaml
---
name: my-orchestrator
description: >-
  One or two sentences — when to use and what outcome (e.g. produces a confirmed plan).
skills:
  - normalize-intent
  - define-scope-boundaries
inputs:
  - user raw input
  - PROJECT_ROOT (optional)
  - GARAGE_SEARCH_ROOTS or paths provided by create-* / install (optional)
outputs:
  - confirmed artifact description
model: inherit
tags:
  - example
constraints:
  - do not write to disk until user confirms
---
```

```markdown
# My orchestrator

You are the **orchestrator** for …

## Workflow

### 1. Intake
- **Goal:** …
- **Action:** Use the **normalize-intent** skill …
- **Output:** …

## Rules

- Resolve agents and skills: walk **`GARAGE_SEARCH_ROOTS`** (project → global → extensions, or order from config); first hit for `agents/<name>.md` or `skills/<name>/` wins.
- …
```

## Optional: example convention (not normative)

Many installs use a user-global bundle directory and a project-local override directory; extensions may add more roots. **Drafted agents** should still refer to **search roots**, not copy a specific path string from this doc.

## Review checklist

- [ ] `name` matches filename
- [ ] `description` is specific
- [ ] Recommended frontmatter (`skills`, `inputs`, `outputs`) present or consciously omitted
- [ ] No long worked examples in the agent body
- [ ] No multiline executable scripts in the agent body
- [ ] Workflow steps reference skills by name; manifest in `skills` list
- [ ] Rules state persistence / review gate and **parameterized** path resolution (bundle roots), not a single hardcoded install path
- [ ] **Secrets:** no solicitation in chat; integrations use env / bundle `.env` conventions (see **Secrets & credentials** above)
- [ ] **Pipeline boundary:** for pipeline `core/` / `extensions/` sources, no out-of-tree source deps; no cross-extension hard deps (see **Pipeline source boundary** above)
- [ ] Clear boundary vs skill and vs command
