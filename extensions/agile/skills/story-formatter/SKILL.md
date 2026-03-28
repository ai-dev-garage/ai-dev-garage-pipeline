---
name: story-formatter
description: From structured story content (user story line, acceptance criteria, technical notes, story points, priority, assumptions, open questions), produce a formatted story definition block. Stateless; never asks questions or decides flow.
argument-hint: user story line, acceptance criteria, technical notes, story points, priority
---

# story-formatter

Stateless transformation only. The orchestrator provides structured content; you produce a formatted output block. You do not ask questions or decide flow.

## Input

- **Title** (one line, concise outcome-focused).
- **User story line** ("As a [persona], I want [capability], so that [benefit].").
- **Acceptance criteria** (testable list from acceptance-criteria-generation skill or provided directly).
- **Technical notes** (optional: dependencies, NFRs, implementation hints at story level).
- **Story points** (optional: number or estimation).
- **Priority** (optional: High / Medium / Low).
- **Assumptions** (optional).
- **Open questions** (optional).

## Output

- A formatted story definition block following the template in [assets/story-template.md](assets/story-template.md).
- Sections with no input are omitted or written as "None."

## Rules

- Do not invent content; only structure what the input provides.
- Acceptance criteria must be testable and observable.
- If a section has no input, omit it or write "None"; do not block.
