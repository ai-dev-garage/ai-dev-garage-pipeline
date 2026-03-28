---
name: user-story-generation
description: From persona, capability, benefit, and context, produce a story title and a structured story description block following Agile/Scrum best practices. Stateless; never asks questions or decides flow.
argument-hint: persona, capability, benefit, context
---

# user-story-generation

Stateless transformation only. The orchestrator provides input; you produce output. You do not ask questions or decide flow.

## Input

- **Persona** (role or user type).
- **Capability** (what they can do or get — outcome, not implementation).
- **Benefit** (why it matters to them or the business).
- Optionally: **acceptance criteria bullets**, **assumptions**, **open questions** already gathered upstream.

## Output

- **Story title:** A concise, outcome-focused title (not a user story line; no "As a…").
- **Story description block:** Filled using the template in [assets/story-template.md](assets/story-template.md).

## Rules

- **Title:** Action-noun format, outcome-focused (e.g. "Scan barcode to check stock level"). Not a sentence starting with "As a".
- **Goal line:** "As a [persona], I want [capability], so that [benefit]." — outcome-focused; no implementation detail.
- **Acceptance Criteria:** Numbered list; each criterion is testable and unambiguous.
- **Assumptions / Open Questions:** Include only what is derivable from input; empty section if none.
- Good vs bad examples: [references/REFERENCE.md](references/REFERENCE.md).
- Do not block; if a section has no input, output an empty numbered list.
