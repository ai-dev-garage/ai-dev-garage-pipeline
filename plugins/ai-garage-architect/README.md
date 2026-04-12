# ai-garage-architect

Pluggable architect / techlead assistant for the AI Dev Garage ecosystem.

## Modes

- **Advisory** — discuss options, review designs, produce trade-off analyses. No artifacts written until the user confirms.
- **Producer** — generate ADRs (and later: component specs, diagrams) into the project's documentation tree.

Intent is auto-detected from the user's request; explicit direct-produce ("write an ADR for X") skips discussion.

## Components

### Agents

- **`architect`** — orchestrator. Detects intent, gathers context, fans out researchers in parallel, synthesizes, gates on user review, then produces artifacts.
- **`architecture-researcher`** — one dimension / option cluster per invocation. Enforced output schema (Options, Trade-off matrix, Per-option analysis, Recommendation, Open questions).
- **`architecture-synthesizer`** — consolidates researcher reports into one integrated design with cross-dimension tensions resolved.

### Skills

- **`arch-doc-loader`** — reads existing architecture docs (local in v1). Globs `**/*.{md,adoc,puml,txt}`. Returns `{docs, diagrams, adrs}` bundle or empty bundle for greenfield.
- **`adr-writer`** — renders an ADR matching the project's house style (loads a sample existing ADR first; does not hardcode MADR).
- **`arch-artifact-publisher`** — writes an artifact to a user-specified local path; runs an optional post-write verification command.

### Command

- **`/ai-garage-architect:architect`** — entry point; routes to the `architect` agent with parsed intent.

### Rule

- **`architect-routing`** — always-on when the plugin is installed. Keywords (`ADR`, `architecture`, `design review`, `trade-off`, `C4`, `NFR`, "compare X vs Y", etc.) route to the orchestrator.

## Configuration

Under `integrations.architect` in `project-config.yaml` (all keys optional; missing = greenfield):

```yaml
integrations:
  architect:
    doc-sources:
      - type: local
        path: src/docs          # loader globs **/*.{md,adoc,puml,txt} under here
    default-output:
      format: adoc              # adoc | md — matches existing ADR format
      adr-path: src/docs/asciidoc/index/technical/architecture-decisions
      diagram-path: src/docs/asciidoc/index/technical/architecture/diagrams
    verification-command: "./gradlew publishToConfluence --convertOnly"
```

## v1 scope

In: advisory + producer (ADR only), local doc source, local file publisher, parallel researchers + synthesizer.

Out (reserved in schema, not built): `component-spec-writer`, `diagram-generator`, `github-docs-fetcher`, Confluence loader, Notion publisher wiring, Jira mutation helpers.
