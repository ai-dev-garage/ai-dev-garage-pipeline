---
name: acceptance-criteria-generation
description: From requirements or scenario, produce testable acceptance criteria (checklist or Given/When/Then). Stateless; never asks questions or decides flow.
argument-hint: requirements or scenario
---

# acceptance-criteria-generation

Stateless transformation only. The orchestrator provides input; you produce output. You do not ask questions or decide flow.

## Input

- Requirements (bullets or short paragraphs) or a scenario description.
- Optionally: preference for checklist style vs Given/When/Then.

## Output

- A list of testable acceptance criteria. Use either:
  - **Checklist:** `- [ ] [Testable condition]` per line, or
  - **Given/When/Then:** `- **Given** [precondition], **when** [action], **then** [observable result].`
- Each criterion is one line or one short block. If input is empty, output an empty list or "None"; do not block.

## Rules

- **Testable:** Yes/no, observable result. No vague "should work" or "user-friendly."
- **Necessary:** Required for the scope; move "nice to have" out or label separately.
- **Unambiguous:** No "it depends" or undefined terms.
- **Achievable, not ambitious:** Avoid vague or overreaching language; keep criteria specific and verifiable.
- Phrasing examples: [references/REFERENCE.md](references/REFERENCE.md).
- Do not add questions or "clarify with user"; only transform input to criteria.
