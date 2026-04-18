# Agent standard — reference

Criteria, frontmatter, and templates for **create / update / review** of agents under AI Dev Garage. Examples and long samples belong here or in **`assets/`**, not in the agent’s main markdown when avoidable.

## Purpose

Agents are **orchestrators** (or **subagents**): they own multi-step flow, when to ask the user vs proceed, optional **review gates**, and delegation to **skills** or other agents. They are **not** stateless transforms (skills) and not thin palette entries alone (commands).

## Caller-supplied paths (create / update / review)

| Input | Use |
|-------|-----|
| **`TARGET_AGENT_FILE`** | Absolute path to the agent markdown file being created, updated, or reviewed. |
| **`${CLAUDE_PLUGIN_ROOT}`** | Absolute bundle root; agent file = **`${CLAUDE_PLUGIN_ROOT}/agents/<name>.md`**. |
| **`ASSET_SCOPE`** (optional) | `plugin` \| `project` — commands map this to **`TARGET_*`** paths. |
| **`${CLAUDE_PLUGIN_ROOT}`** (optional) | Ordered list of bundle roots for **runtime** resolution rules embedded in the drafted agent. |

Do not bake pipeline repo paths (e.g. `core/...`) or a single fixed home directory into the **standard**; installers and **`create-*` commands** own that mapping.

## Runtime resolution (wording for drafted agents)

In the agent’s **Rules**, state that loading follows plugin discovery (project overrides take precedence over installed plugins). Use **placeholders** such as “resolve from **`${CLAUDE_PLUGIN_ROOT}`** where `agents/<name>.md` exists” — the plugin system handles the actual resolution. Same idea for **`skills/<name>/`** under each root.

## Frontmatter (Garage)

| Field | Status | Purpose |
|-------|--------|---------|
| `name` | **required** | Verb-noun, hyphenated; must match filename without `.md`. |
| `description` | **required** | When to use, what it produces; shown in agent pickers. |
| `skills` | **recommended** | YAML list of skill names (directory names under `skills/`) the agent relies on. |
| `agents` | **recommended** | YAML list of sub-agent names (namespaced as `plugin:agent-name`) this agent delegates to. Runtimes use this to pre-register `subagent_type` values for nested `Agent` dispatch. Omit for leaf agents that do not spawn others. |
| `inputs` | **recommended** | What the caller passes (e.g. raw user text, `PROJECT_ROOT`, **`${CLAUDE_PLUGIN_ROOT}`**, **`TARGET_*`** from commands). |
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

Workflow steps should **name skills and agents in prose** (“Use the **normalize-intent** skill …”, “Delegate to the **implement-task** agent …”) while **`skills`** and **`agents`** in frontmatter remain the single manifest of dependencies.

## Body structure

- **Title** (`# …`) and one-line role (“You are the orchestrator for …”).
- **When invoked** (subagents only): parent, phase, inputs.
- **Workflow:** Numbered steps. Each step: **Goal**, **Action** (cite skill names in bold), **Output**.
- **Rules:** Persistence gates, path resolution, error handling, “do not duplicate command flow.”

## Secrets & credentials (agents)

- Agents must **never** instruct the user to paste secrets in chat.
- Delegate secret handling to **skills** that use: named **environment variables**, optional **`assets/<skill-name>.template.env`** (placeholders only, safe to commit), and user-local **`${CLAUDE_PLUGIN_ROOT}/skills/<skill-name>/<skill-name>.env`** with documented precedence (env → project bundle → plugin bundle unless stated otherwise).
- In **Rules**, tell the model to read config from those mechanisms only — not from user messages containing credentials.

## Nested agent dispatch

Agents that **spawn other agents** (orchestrators with subagent fan-out, phase routers, parallel workers) **must declare the `Agent` tool explicitly** in frontmatter. Tool inheritance for subagents is not guaranteed across harnesses: an orchestrator invoked via the Agent tool may run in a context where `Agent` is not automatically inherited, and nested dispatch then fails at runtime.

Minimum required form:

```yaml
tools: Agent, Bash, Edit, Glob, Grep, Read, Skill, Write, WebFetch, WebSearch, TaskCreate, TaskUpdate, TaskList
```

Also add a constraint line that names the requirement so it surfaces in the picker and is enforced during review:

```yaml
constraints:
  - requires nested Agent dispatch to <purpose>; must be invokable in a context where the Agent tool is available
```

Leaf subagents (those that do not spawn others) should omit `Agent` from `tools` when they declare `tools` at all, to reduce the risk of accidental nested dispatch from a leaf.

## Plugin boundary

- No required references to source assets outside the plugin’s own tree.
- **Cross-plugin** hard dependencies are unsupported for now. Each plugin is self-contained.
- **`skills` frontmatter** should list only skill names that the install can resolve from the same plugin — not another plugin’s exclusive skills as a required dependency.
- Install-time paths via caller-supplied **`${CLAUDE_PLUGIN_ROOT}`** / **`TARGET_AGENT_FILE`** are fine and are not out-of-plugin source dependencies.

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
agents:
  - my-plugin:sub-agent-a
  - my-plugin:sub-agent-b
inputs:
  - user raw input
  - PROJECT_ROOT (optional)
  - ${CLAUDE_PLUGIN_ROOT} or paths provided by create-* / install (optional)
outputs:
  - confirmed artifact description
model: inherit
tools: Agent, Bash, Edit, Glob, Grep, Read, Skill, Write, WebFetch, WebSearch, TaskCreate, TaskUpdate, TaskList
tags:
  - example
constraints:
  - requires nested Agent dispatch to fan out sub-agent-a and sub-agent-b; must be invokable in a context where the Agent tool is available
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

- Resolve agents and skills: walk **`${CLAUDE_PLUGIN_ROOT}`** (project → global → extensions, or order from config); first hit for `agents/<name>.md` or `skills/<name>/` wins.
- …
```

## Optional: example convention (not normative)

Plugins are discovered automatically; project-local overrides take precedence. **Drafted agents** should still refer to **plugin roots**, not copy a specific path string from this doc.

## Review checklist

- [ ] `name` matches filename
- [ ] `description` is specific
- [ ] Recommended frontmatter (`skills`, `agents`, `inputs`, `outputs`) present or consciously omitted
- [ ] No long worked examples in the agent body
- [ ] No multiline executable scripts in the agent body
- [ ] Workflow steps reference skills by name; manifest in `skills` list
- [ ] Rules state persistence / review gate and **parameterized** path resolution (bundle roots), not a single hardcoded install path
- [ ] **Secrets:** no solicitation in chat; integrations use env / bundle `.env` conventions (see **Secrets & credentials** above)
- [ ] **Plugin boundary:** no out-of-plugin source deps; no cross-plugin hard deps (see **Plugin boundary** above)
- [ ] **Nested dispatch:** if the agent spawns subagents, `tools` includes `Agent` and a matching constraint is declared (see **Nested agent dispatch** above)
- [ ] Clear boundary vs skill and vs command
