# ADR writer — reference

## Fallback template (used only when the project has no prior ADRs)

Terse Garage-default structure. Producer should still prefer any detected house style over this template.

### AsciiDoc (`adoc`)

```
= {{title}}

Status: {{status}}

== Context

{{context}}

== Decision

{{decision}}

== Consequences

=== Positive

- {{positive[0]}}
- {{positive[1]}}

=== Negative

- {{negative[0]}}

=== Neutral

- {{neutral[0]}}
```

### Markdown (`md`)

```
# {{title}}

**Status:** {{status}}

## Context

{{context}}

## Decision

{{decision}}

## Consequences

### Positive

- {{positive[0]}}
- {{positive[1]}}

### Negative

- {{negative[0]}}

### Neutral

- {{neutral[0]}}
```

## Number derivation

Scan the bundle's `adrs` list for the maximum numeric id. Next = max + 1, zero-padded to at least 3 digits. Filenames are `adr-NNN-<kebab-case-slug>.<ext>`.

## Index row

For an AsciiDoc index (`architecture-decisions.adoc`) with a table of ADRs, append:

```
|xref:architecture-decisions/{{filename}}[{{adr_id}}]
|{{title}}
|{{status}}
```

For a Markdown index, append a row matching the detected table header. If the index uses a bulleted list instead of a table, detect and match.

## House-style signals to copy when detected

- Whether `Status:` is a line, a block, or a property.
- Heading level for sub-sections (`==` vs `===` in AsciiDoc).
- Presence or absence of `Positive` / `Negative` / `Neutral` splits under Consequences.
- Paragraph length (terse single-sentence bullets vs multi-sentence prose).
