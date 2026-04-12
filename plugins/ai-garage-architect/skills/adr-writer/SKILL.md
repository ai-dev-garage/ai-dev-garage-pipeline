---
name: adr-writer
description: Render an ADR (Architecture Decision Record) that matches the project's house style. Loads 1–2 recent ADRs from the provided bundle first to detect section structure, heading style, and tone; does not hardcode the MADR template. Returns the rendered document and the chosen ADR number.
argument-hint: structured decision (title, context, decision, consequences) + doc-bundle from arch-doc-loader + default-output config
---

# ADR writer

## When to use

- Called by the **architect** orchestrator in production step 7 (direct-produce or advisory-then-produce flows).
- Any caller that has an approved decision and wants it rendered as an ADR matching an existing project's conventions.

## Input

- `decision` — structured input:
  - `title` (short, no number)
  - `context` (prose, ≤ ~10 sentences)
  - `decision` (prose; what is being decided)
  - `consequences` (object: `positive`, `negative`, `neutral` — each a list of bullets)
  - optional `status` (default `Accepted`)
  - optional `related_adrs` (list of ids)
- `doc-bundle` — output of **arch-doc-loader** (specifically its `adrs` list).
- `default-output` — `{ format: "adoc"|"md", adr-path: <dir> }` from `integrations.architect.default-output`.

## Instructions

### 1. Detect house style

- If `doc-bundle.adrs` is non-empty, pick the 1–2 most recent ADRs (highest numeric `id`). Read their content and detect: section structure (e.g. `Context` / `Decision` / `Consequences[Positive|Negative|Neutral]`), heading level conventions, tone (terse vs prose-heavy), and any conventional preamble (e.g. `Status: Accepted`).
- If no ADRs exist, fall back to the default template in [references/REFERENCE.md](references/REFERENCE.md).

### 2. Choose the next ADR number

- Scan `doc-bundle.adrs` for the max numeric id. Next id = max + 1, zero-padded to 3 digits (`ADR-006`).
- Slugify `decision.title` for the filename: `adr-NNN-<slug>.<ext>` where `<ext>` matches `default-output.format`.

### 3. Render

- Render each input field into the detected section structure. Match the existing heading style and tone — do not impose MADR if the project uses a terser shape.
- Output format is `default-output.format` (AsciiDoc or Markdown). Do not mix formats in one file.
- Include a link to related ADRs if provided.

### 4. Return

Return:

- `rendered` — the full document content (string).
- `filename` — the derived filename (no path).
- `adr_id` — e.g. `ADR-006`.
- `index_update` — a one-row entry that the publisher can append to the ADR index table, if an index was detected in the bundle.

Do not write files in this skill; that is the publisher's job.

## Rules

- **House style first.** Always prefer the detected style over any template in references. References are the fallback only.
- **No number collisions.** The computed `adr_id` must not clash with any existing id in the bundle.
- **No file writes.** Return content + metadata; the publisher writes.
- **No overwrite decisions.** If a file with the computed filename already exists, flag it in the return payload so the caller can decide.
- **Secrets:** none required; this skill is pure rendering over local data.
