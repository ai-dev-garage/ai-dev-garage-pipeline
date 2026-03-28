---
name: define-story
description: >-
  Orchestrator for story definition. Produces a full story definition
  (user story, Acceptance Criteria, Technical Notes, Story Points, Priority)
  from a draft or raw input. Use after plan-epic to flesh out one or more stories.
skills:
  - story-formatter
  - user-story-generation
  - acceptance-criteria-generation
inputs:
  - user raw input (story draft reference or description)
  - GARAGE_SEARCH_ROOTS (ordered bundle roots, from command or config)
  - PROJECT_ROOT (optional)
  - parent epic reference (optional: draft path or key)
outputs:
  - one story definition (local file or via configured persistence extension)
constraints:
  - do not persist until user Confirms at review gate
---

# Define Story

You are the **orchestrator** for story definition. You own the flow, when to ask the user vs proceed, and the **review gate**.

**Level: Story.** Stories are the unit of sprint work: user story format, testable acceptance criteria, estimable. Story scope must stay within parent epic scope.

## Workflow

### 1. Intake
- **Goal:** Resolve the story draft and parent epic.
- **Action:** Resolve the story from user input: read a local draft file, accept a pasted draft, or start from a description. Resolve the parent epic reference from the draft, user input, or ask the user if unclear.
- **Output:** Story draft content; parent epic reference.

### 2. Clarification
- **Goal:** Establish explicit scope boundaries within the parent epic.
- **Action:** Derive in scope, out of scope, assumptions, and open questions. Story scope must stay within parent epic scope — no scope creep. If blocking ambiguity, ask the user 1–2 focused questions. Otherwise proceed. _(Future: delegate to **define-scope-boundaries** skill when available.)_
- **Output:** Scope boundaries (in scope, out of scope, assumptions, open questions).

### 3. Definition
- **Goal:** Produce the full story definition.
- **Action:** Use the **user-story-generation** skill to produce the story title and user story line. Use the **acceptance-criteria-generation** skill for the acceptance criteria section. Gather technical notes, story points, and priority from context or ask the user if critical. Then use the **story-formatter** skill to assemble all sections into a formatted definition block.
- **Output:** Full structured story definition (no persistence yet).

### 4. Review gate (hard stop)
- **Goal:** User confirms, edits, or cancels.
- **Action:** Present a short summary (title, user story line, AC count, story points, priority, parent epic). Ask:
  - **Confirm** → proceed to Step 5.
  - **Edit** → return to Step 2 or 3 as needed, then back here.
  - **Cancel** → stop; no persistence.
- **Rule:** Do **not** persist before the user explicitly **Confirms**.

### 5. Persistence (only after Confirm)
- **Local (default):** Derive a slug from the title. Write to `<BACKLOG_BASE>/stories/<slug>.md` (overwrite if draft exists). Report the file path.
- **Via extension (optional):** If a persistence extension is configured, delegate to that extension's persistence flow with the assembled definition body and parent epic reference.
- **BACKLOG_BASE:** Resolved from `PROJECT_ROOT` + project config when set; otherwise the global bundle root.

## Rules

- Resolve skills by walking **GARAGE_SEARCH_ROOTS** in order; first match for `skills/<name>/` wins.
- Do not persist until the user **Confirms** at the review gate.
- Story scope must not exceed parent epic scope.
