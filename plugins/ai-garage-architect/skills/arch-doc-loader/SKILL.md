---
name: arch-doc-loader
description: Load existing architecture docs from configured sources and return a structured bundle (docs, diagrams, adrs). v1 supports local sources only; dispatcher shape is ready for future github and confluence sources. Greenfield returns an empty bundle, not an error.
argument-hint: doc-sources list (from integrations.architect.doc-sources) + PROJECT_ROOT
---

# Arch doc loader

## When to use

- Called by the **architect** orchestrator during context gathering (step 2).
- Any caller that needs a structured snapshot of a project's existing architecture docs.

## Input

- `doc-sources` — list of sources from `integrations.architect.doc-sources`. Each entry has a `type` and type-specific keys. v1 handles only `type: local`.
- `PROJECT_ROOT` — absolute path used to resolve any relative `path` in a `local` source.

## Instructions

### 1. Dispatch per source

For each entry in `doc-sources`:

- `type: local` — resolve the absolute directory; enumerate files matching glob `**/*.{md,adoc,puml,txt}`. Read each.
- `type: github` — **reserved for v2**; log an informational message that the source is skipped.
- `type: confluence` — **reserved for v2**; log an informational message that the source is skipped.

No sources configured → return the empty bundle in step 3 with a `greenfield: true` flag.

### 2. Classify files

For every file read:

- **ADR** — filename matches `adr-NNN-*` (case-insensitive) with extension `.md` or `.adoc`. Extract `id` (e.g. `ADR-004`), `title` (from the first heading), and `status` (look for a line matching `Status:` followed by a value, else `null`).
- **Diagram** — `.puml` files, or `.md` / `.adoc` files whose filename or path clearly identifies them as a diagram source.
- **Doc** — everything else.

AsciiDoc is not parsed; content is passed through raw. Classification is path- and filename-based.

### 3. Return

Return a JSON-shaped bundle:

- `docs` — list of `{ path, content, format }` where `format` is `md` | `adoc` | `txt`.
- `diagrams` — list of `{ path, content }`.
- `adrs` — list of `{ path, id, title, status }`.
- `greenfield` — boolean; `true` only when no sources are configured and no files were found.

See [references/REFERENCE.md](references/REFERENCE.md) for the full return shape and ADR-detection rules.

## Rules

- **Greenfield is not an error.** If no sources are configured or no files match, return an empty bundle with `greenfield: true`.
- **Read-only.** This skill never writes.
- **Secrets.** v1 sources are local disk only; no credentials needed. Future `github` and `confluence` sources will document env var names in this skill's reference when added.
- **Glob scope.** Always `**/*.{md,adoc,puml,txt}` — do not hardcode `.md`-only; real projects use AsciiDoc and PlantUML.
- **No recursion outside the configured source root.** Do not walk `PROJECT_ROOT` as a whole unless the user explicitly configured it as a source.
