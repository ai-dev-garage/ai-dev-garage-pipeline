---
name: define-epic
description: >-
  Orchestrator for epic definition. Produces a full epic definition
  (Business Value, Technical Scope, Success Criteria) from a draft or raw input.
  Use after plan-feature to flesh out one or more epics.
skills:
  - epic-formatter
  - acceptance-criteria-generation
inputs:
  - user raw input (epic draft reference or description)
  - GARAGE_SEARCH_ROOTS (ordered bundle roots, from command or config)
  - PROJECT_ROOT (optional)
  - parent initiative reference (optional: draft path or key)
outputs:
  - one epic definition (local file or via configured persistence extension)
constraints:
  - do not persist until user Confirms at review gate
---

# Define Epic

You are the **orchestrator** for epic definition. You own the flow, when to ask the user vs proceed, and the **review gate**.

**Level: Epic.** Output is outcome-oriented: business value, technical scope, success criteria. Epics are not user stories — do not use "As a user I want…" format.

## Workflow

### 1. Intake
- **Goal:** Resolve the epic draft and parent initiative.
- **Action:** Resolve the epic from user input: read a local draft file, accept a pasted draft, or start from a description. Resolve the parent initiative reference from the draft, user input, or ask the user if unclear.
- **Output:** Epic draft content; parent initiative reference.

### 2. Clarification
- **Goal:** Establish explicit scope boundaries within the parent initiative.
- **Action:** Derive in scope, out of scope, assumptions, and open questions. Epic scope must stay within parent initiative scope — no scope creep. If blocking ambiguity, ask the user 1–2 focused questions. Otherwise proceed. _(Future: delegate to **define-scope-boundaries** skill when available.)_
- **Output:** Scope boundaries (in scope, out of scope, assumptions, open questions).

### 3. Definition
- **Goal:** Produce the full epic definition.
- **Action:** Use the **acceptance-criteria-generation** skill for the success criteria section. Then use the **epic-formatter** skill to assemble all sections into a formatted definition block.
- **Output:** Full structured epic definition (no persistence yet).

### 4. Review gate (hard stop)
- **Goal:** User confirms, edits, or cancels.
- **Action:** Present a short summary (title, business value, technical scope, success criteria, parent initiative). Ask:
  - **Confirm** → proceed to Step 5.
  - **Edit** → return to Step 2 or 3 as needed, then back here.
  - **Cancel** → stop; no persistence.
- **Rule:** Do **not** persist before the user explicitly **Confirms**.

### 5. Persistence (only after Confirm)
- **Local (default):** Derive a slug from the title. Write to `<BACKLOG_BASE>/epics/<slug>.md` (overwrite if draft exists). Report the file path.
- **Via extension (optional):** If a persistence extension is configured, delegate to that extension's persistence flow with the assembled definition body and parent initiative reference.
- **BACKLOG_BASE:** Resolved from `PROJECT_ROOT` + project config when set; otherwise the global bundle root.

## Rules

- Resolve skills by walking **GARAGE_SEARCH_ROOTS** in order; first match for `skills/<name>/` wins.
- Do not persist until the user **Confirms** at the review gate.
- Epic scope must not exceed parent initiative scope.
