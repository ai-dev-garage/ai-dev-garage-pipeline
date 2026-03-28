# Skill standard — reference

Criteria and templates for **create / update / review** of pipeline skills under AI Dev Garage. Examples belong **here** (or in `assets/`), not in `SKILL.md`.

## Purpose

Skills package **domain procedures** for agents. They should stay **focused**: main instructions in `SKILL.md`; depth in `references/`; execution in `scripts/`; static data in `assets/`.

## Caller-supplied paths (create / update / review)

Standards and **`create-*` / `update-*` / `review-*` flows** must not assume a fixed on-disk layout. The **command or parent agent** resolves **where** the skill package lives or should be written and passes that into this skill.

| Input | Use |
|-------|-----|
| **`TARGET_SKILL_DIR`** | Absolute path to the skill package directory (contains `SKILL.md`). Use for create, update, and review. |
| **`GARAGE_BUNDLE_ROOT`** | Absolute path to a bundle root; combined with skill name → **`GARAGE_BUNDLE_ROOT/skills/<name>/`**. |
| **`ASSET_SCOPE`** (optional) | `global` \| `extension` \| `project` — explains intent; **commands** map scope to concrete **`TARGET_*`** paths. |

**Global** vs **extension**: the installer or command chooses the bundle root (e.g. user-global garage vs an extension’s subtree). This standard does not hardcode those roots.

## Runtime loading pattern (for authored agents/commands)

When an agent **loads** a skill at runtime, use an **ordered list of bundle roots** supplied by config or the command (project → global → extensions, or as configured). Search under each root’s **`skills/<name>/`** (or the layout your bundles use). Document **variable names** and precedence in agent **Rules**; do not embed literal home or project paths as the only truth.

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

- **Noun or noun phrase:** `normalize-intent`, `generate-acceptance-criteria`, `jira-field-mapper`.
- Avoid verb-only skill names; meta tooling uses nouns like `skill-standard`, `pipeline-installer`.

## Scripts

- Self-contained, clear errors, documented args.
- Refer from SKILL.md: `Run scripts/validate.sh …` (single line; no full script body in SKILL.md).

## When to use skill vs agent vs command

- **Skill:** Stateless transform; optional auto-invocation; packaged with references/scripts/assets.
- **Agent:** Multi-step flow, user interaction, review gate, persistence, delegation.
- **Command:** User-facing entry (often thin: resolve project → load agent).

## Copy-paste: minimal new skill

Paths below are **relative** to **`TARGET_SKILL_DIR`** or to **`GARAGE_BUNDLE_ROOT/skills/my-skill/`**.

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

Installers may symlink a user-global bundle to a path like `~/.ai-dev-garage/` and project overrides under `<PROJECT_ROOT>/<garage-dir>/`. **Extension** bundles may live beside global or under an extension-specific prefix. Treat these as **deployment examples**; authored skills and standards still take **`TARGET_SKILL_DIR`** / **`GARAGE_BUNDLE_ROOT`** from the caller.

## Copy-paste: review checklist

- [ ] `name` matches directory name
- [ ] `description` is specific enough for relevance
- [ ] SKILL.md has **no** worked examples (only pointers)
- [ ] SKILL.md has **no** multiline executable scripts
- [ ] `scripts/` holds runnable code; SKILL.md only references paths
- [ ] **`references/` vs `assets/`:** “always know / reasoning / decision order / output format” content is under **`references/`**; optional, large, example-heavy, schema/template, lookup content is under **`assets/`**
- [ ] Skill stays stateless unless explicitly documented otherwise
- [ ] No hardcoded global/project/extension paths as the only way to find or write the package; caller-supplied **`TARGET_SKILL_DIR`** / bundle roots respected

## Do not

- Duplicate content that belongs in project rules or another skill.
- Put workflow steps in `references/`; keep the runnable workflow in SKILL.md.
- Add sections that only catalog options without decision value (bloat).
