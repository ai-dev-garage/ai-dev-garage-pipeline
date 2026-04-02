# Skill standard — reference

Criteria and templates for **create / update / review** of pipeline skills under AI Dev Garage. Examples belong **here** (or in `assets/`), not in `SKILL.md`.

## Purpose

Skills package **domain procedures** for agents. They should stay **focused**: main instructions in `SKILL.md`; depth in `references/`; execution in `scripts/`; static data in `assets/`.

## Caller-supplied paths (create / update / review)

Standards and **`create-*` / `update-*` / `review-*` flows** must not assume a fixed on-disk layout. The **command or parent agent** resolves **where** the skill package lives or should be written and passes that into this skill.

| Input | Use |
|-------|-----|
| **`TARGET_SKILL_DIR`** | Absolute path to the skill package directory (contains `SKILL.md`). Use for create, update, and review. |
| **`${CLAUDE_PLUGIN_ROOT}`** | Absolute path to a bundle root; combined with skill name → **`${CLAUDE_PLUGIN_ROOT}/skills/<name>/`**. |
| **`ASSET_SCOPE`** (optional) | `plugin` \| `project` — explains intent; **commands** map scope to concrete **`TARGET_*`** paths. |

**Plugin** vs **project**: the installer or command chooses the root (e.g. installed plugin vs project-local override). This standard does not hardcode those roots.

## Runtime loading pattern (for authored agents/commands)

When an agent **loads** a skill at runtime, assets are discovered automatically from installed plugins (project overrides take precedence). Search under each root’s **`skills/<name>/`** (or the layout your plugins use). Document **variable names** and precedence in agent **Rules**; do not embed literal home or project paths as the only truth.

## Canonical directory layout

```text
skills/<skill-name>/
├── SKILL.md                 # required — instructions only, no examples, no multiline scripts
├── scripts/                 # optional — executable code
├── references/              # optional — long docs, examples, patterns
│   └── REFERENCE.md         # typical entry (any names allowed)
└── assets/                  # optional — templates, JSON, images
```

This matches the structure described in [Cursor Agent Skills](https://cursor.com/docs/skills) (`scripts/`, `references/`, `assets/`).

## `references/` vs `assets/` (what goes where)

Use this split when moving content out of `SKILL.md`.

### Put it in `references/` (e.g. `references/REFERENCE.md`) if:

- The agent **must always know it** when applying this skill (core context for correct use).
- It **affects reasoning** (principles, rubrics, “how to think” rules).
- It **affects decision order** (precedence, branching, step ordering, gate logic).
- It **affects output format** (required sections, headings, field order—without dumping huge example payloads into `SKILL.md`).

### Put it in `assets/` if:

- The agent **may consult it** only when needed (progressive disclosure / optional depth).
- It is **large** (long tables, big appendices).
- It is **example-based** (worked samples, golden outputs, long before/after).
- It is **schema / template** (JSON Schema, OpenAPI fragments, blank forms, config templates).
- It is **lookup-style** (dictionaries, enums, ID lists, CSV-like data).

**Rule of thumb:** If skipping the file would change *how* the agent reasons or orders work → **`references/`**. If the file is mainly *material to read or copy when relevant* → **`assets/`**.

## Secrets & credentials

### No solicitation in chat

- Authored skills must **never** ask the user to paste or type passwords, API tokens, private keys, or other secrets in chat.
- Runtimes and scripts may **read** secrets from the process environment or from **local, gitignored** files; they must **not** request secret values in the conversation.

### If the skill depends on secrets

The skill must document **at least one** of:

1. **Environment variables** — list each name; tell the user to set them in the shell, IDE, CI, or deployment environment.
2. **`.env` workflow** — describe a **local** env file (gitignored), how to create it (e.g. copy from the committed template), and how tooling loads it—without asking for secret values in chat.

### `references/` vs `assets/` for secrets

| What | Where | Why |
|------|--------|-----|
| Filled env file with real secrets | **Not in the repo** | User- or machine-local only; gitignored; never committed. |
| Template (placeholders only, safe to commit) | **`assets/`** e.g. `assets/<skill-name>.template.env` | Schema/template material belongs in **`assets/`**. |
| Required variable names, precedence, copy steps, gitignore reminders | **`references/`** | Procedure and reasoning the agent must follow. |

**SKILL.md** links in one line each to the relevant `references/*` file and, if present, `assets/<skill-name>.template.env`. Do not embed secret values or multiline “example” credentials in SKILL.md.

### Installed Garage bundle: where to read `<skill-name>.env`

After plugin install, skills live under **`${CLAUDE_PLUGIN_ROOT}/skills/<skill-name>/`** or project overrides at `<PROJECT_ROOT>/.ai-dev-garage/skills/<skill-name>/`.

**Canonical dedicated file** (user-created; not shipped from the plugin): **`${CLAUDE_PLUGIN_ROOT}/skills/<skill-name>/<skill-name>.env`** next to that skill’s `SKILL.md`. Install copies only files from the package; an extra `*.env` file in that directory is not removed by current install logic, so it survives updates.

**Suggested precedence** (state explicitly in `references/`; implement consistently in scripts):

1. **Process environment** — exported variables usually **override** the same key from a file unless the skill documents otherwise.
2. **Project bundle** — if present, read `<PROJECT_ROOT>/.ai-dev-garage/skills/<skill-name>/<skill-name>.env`.
3. **Plugin bundle** — else read `${CLAUDE_PLUGIN_ROOT}/skills/<skill-name>/<skill-name>.env` when present.

Skills may also mention **`$PROJECT_ROOT/.env`** when that matches the workspace tool chain; the **Garage-native default** is still the co-located **`<skill-name>.env`** under the active bundle’s `skills/<skill-name>/`.

### Project `.gitignore` (application repos)

Ignore real env files while keeping committed templates:

- `*.env` matches names ending in `.env` (including `*.template.env`) unless negated—pair with `!*.template.env`.
- Many Git versions do **not** match the file `.env` with `*.env` (leading dot)—list **`.env`** explicitly.

Example (tune per repo; add `!.env.example` if you commit `.env.example` and a broader pattern would ignore it):

```gitignore
.env
*.env
!*.template.env
```

### Scripts

Load configuration from env or from the documented file path; do not print secret values to logs or chat; do not hardcode credentials in SKILL.md or committed files.

## Plugin boundary

Applies when authoring or reviewing skills that **ship from a plugin**.

1. **No out-of-tree source dependencies** — Do not require links, imports, or “read file at ...” targets that point **outside** the plugin’s own directory tree (e.g. another Git repo, a personal `~/skills/` tree, or a third-party bundle path as the canonical source for bundled behavior). Product docs URLs for Cursor/Claude are fine; **required** operational dependencies must live within the plugin.

2. **Cross-plugin references unsupported (for now)** — A plugin must **not** hard-depend on another plugin’s assets. Each plugin is self-contained until the project explicitly supports cross-plugin coupling.

3. **Install-time paths** — Instructions may still describe resolution using caller-supplied **`${CLAUDE_PLUGIN_ROOT}`** or **`TARGET_SKILL_DIR`** after install; that is runtime layout, not a dependency on unpublished source outside the plugin.

## Frontmatter (Garage baseline)

| Field | Required | Notes |
|-------|----------|--------|
| `name` | Yes (Garage) | Lowercase, hyphens; **must match parent folder name** (Cursor). |
| `description` | Yes | What the skill does and when to use it; drives auto-invocation where supported. |
| `argument-hint` | No | Shown for slash-style invocation; e.g. `skill_name or path`. |

Optional fields you may add when useful (see [Cursor skills frontmatter](https://cursor.com/docs/skills) and [Claude skill frontmatter](https://code.claude.com/docs/en/skills#configure-skills)):

| Field | Product | Purpose |
|-------|---------|--------|
| `license` | Cursor | License name or bundled license file. |
| `compatibility` | Cursor | Environment requirements. |
| `metadata` | Cursor | Arbitrary key-value map. |
| `disable-model-invocation` | Cursor / Claude | `true` = only explicit `/skill-name` (or equivalent), not auto-selected. |
| `user-invocable` | Claude | `false` = hide from `/` menu; Claude-only invocation. |
| `allowed-tools` | Claude | Tools usable without extra approval when skill is active. |
| `model` | Claude | Model override when skill is active. |
| `context` | Claude | e.g. `fork` for subagent execution. |
| `agent` | Claude | Subagent type with `context: fork`. |
| `paths` | Claude | Globs limiting when skill auto-loads. |

Garage does not require Claude-only fields; add them when the skill is meant for Claude Code behavior.

## SKILL.md content rules

- **Include:** Title, short “when to use”, numbered **Instructions** or **Steps**, **Input** / **Output** / **Rules**, links to `references/…` and `scripts/…`.
- **Do not include:** Worked examples, sample JSON/markdown outputs, long “before/after” blocks → move to `references/` or `assets/`.
- **Do not include:** Multiline `bash`/`python`/… fences that are meant to be executed → move to `scripts/` and cite `scripts/foo.sh`.

## Naming

- **Noun or noun phrase:** `skill-standard`, `pipeline-installer`, `task-gap-clarification`, `jira-item-fetcher`, `feature-branch-guard`, `code-implementation`.
- Avoid verb-based names (e.g. `fix-failing-tests`, `implement-code`, `align-agent-models`). Reframe as the thing the skill represents, not the action it performs.

## No skill-to-skill references

- A skill must **not** invoke, delegate to, or depend on another skill.
- If a skill needs data that another skill produces (e.g. resolved config values), declare those as explicit **Input** fields. The calling agent resolves them first and passes them in.
- This keeps skills stateless, composable, and independently testable.

## Scripts

- Self-contained, clear errors, documented args.
- Refer from SKILL.md: `Run scripts/validate.sh …` (single line; no full script body in SKILL.md).

## When to use skill vs agent vs command

- **Skill:** Stateless transform; optional auto-invocation; packaged with references/scripts/assets.
- **Agent:** Multi-step flow, user interaction, review gate, persistence, delegation.
- **Command:** User-facing entry (often thin: resolve project → load agent).

## Copy-paste: minimal new skill

Paths below are **relative** to **`TARGET_SKILL_DIR`** or to **`${CLAUDE_PLUGIN_ROOT}/skills/my-skill/`**.

**File: `skills/my-skill/SKILL.md`**

```markdown
---
name: my-skill
description: One line — what it does and when the agent should use it.
argument-hint: optional-args
---

# My skill

## When to use

- Use when …

## Instructions

1. …
2. …

## Input

- …

## Output

- …

## Rules

- …

## More detail

- Patterns and **examples**: [REFERENCE.md](references/REFERENCE.md)
```

**File: `skills/my-skill/references/REFERENCE.md`**

Put extended patterns, API notes, and **all examples** here.

## Optional: example convention (not normative)

Plugins are discovered automatically by Claude Code and Cursor. Project overrides live under `<PROJECT_ROOT>/.ai-dev-garage/`. Authored skills and standards still take **`TARGET_SKILL_DIR`** / **`${CLAUDE_PLUGIN_ROOT}`** from the caller.

## Copy-paste: review checklist

- [ ] `name` matches directory name
- [ ] `description` is specific enough for relevance
- [ ] SKILL.md has **no** worked examples (only pointers)
- [ ] SKILL.md has **no** multiline executable scripts
- [ ] `scripts/` holds runnable code; SKILL.md only references paths
- [ ] **`references/` vs `assets/`:** “always know / reasoning / decision order / output format” content is under **`references/`**; optional, large, example-heavy, schema/template, lookup content is under **`assets/`**
- [ ] Skill stays stateless unless explicitly documented otherwise
- [ ] No references to other skills — data dependencies declared as Input fields
- [ ] No hardcoded plugin/project paths as the only way to find or write the package; caller-supplied **`TARGET_SKILL_DIR`** / plugin roots respected
- [ ] **Secrets:** no chat solicitation; secret supply via env and/or documented `.env` workflow; templates only in **`assets/`**; rules in **`references/`**; see **Secrets & credentials** above
- [ ] **Plugin boundary:** no required asset references outside the plugin's own tree; no cross-plugin hard dependencies

## Do not

- Duplicate content that belongs in project rules or another skill.
- Put workflow steps in `references/`; keep the runnable workflow in SKILL.md.
- Add sections that only catalog options without decision value (bloat).
