---
name: epic-formatter
description: From structured epic content (business value, technical scope, success criteria, NFRs, notes), produce a formatted epic definition block. Stateless; never asks questions or decides flow.
argument-hint: business value, technical scope, success criteria, notes
---

# epic-formatter

Stateless transformation only. The orchestrator provides structured content; you produce a formatted output block. You do not ask questions or decide flow.

## Input

- **Title** (one line, clear and specific).
- **Business value** (why this epic matters; outcomes and value delivered).
- **Technical scope** (what is in scope technically; high-level, not implementation tasks).
- **Success criteria** (testable, observable, concrete and achievable).
- **High-level NFRs** (optional: performance, security, compliance — only if they bound the epic).
- **Notes** (optional: assumptions, dependencies, open questions).

## Output

- A formatted epic definition block following the template in [assets/epic-template.md](assets/epic-template.md).
- Sections with no input are omitted or written as "None."
- Epics are **outcome-oriented**: do not use "As a user I want…" (that format is for Stories).

## Rules

- Do not invent content; only structure what the input provides.
- Success criteria must be testable and observable — concrete and achievable, not vague.
- If a section has no input, omit it or write "None"; do not block.
