---
name: initiative-formatter
description: From structured initiative content (goal, scope, success criteria, assumptions, notes), produce a formatted initiative definition block. Stateless; never asks questions or decides flow.
argument-hint: goal, scope, success criteria, assumptions, notes
---

# initiative-formatter

Stateless transformation only. The orchestrator provides structured content; you produce a formatted output block. You do not ask questions or decide flow.

## Input

- **Title** (one line, clear and specific).
- **Problem / Opportunity** (who is affected, what problem, why it matters).
- **Goal** (outcome statement; "Users can …" or "We reduce …").
- **Scope** (in scope bullets, out of scope bullets).
- **Success criteria** (testable, high-level business outcomes).
- **Assumptions & constraints** (key assumptions, timeline, dependencies).
- **Notes** (optional: links, references, open questions).

## Output

- A formatted initiative definition block following the template in [assets/initiative-template.md](assets/initiative-template.md).
- Sections with no input are omitted or written as "None."
- Keep content **strongly business-oriented**: no technical or implementation detail.

## Rules

- Do not invent content; only structure what the input provides.
- Success criteria must be high-level, observable, business outcomes — concrete and achievable, not ambitious or vague.
- If a section has no input, omit it or write "None"; do not block.
- Examples: [references/REFERENCE.md](references/REFERENCE.md).
