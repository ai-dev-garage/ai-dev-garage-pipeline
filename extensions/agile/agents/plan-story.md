---
name: plan-story
description: >-
  Orchestrator for story refinement and task creation. Refines a story
  (user story format; may include technical details and NFRs) and creates
  tasks when the user confirms the story is ready.
skills:
  - story-formatter
  - user-story-generation
  - acceptance-criteria-generation
inputs:
  - user raw input (story reference, instructions, optional mode=extend)
  - GARAGE_SEARCH_ROOTS (ordered bundle roots, from command or config)
  - PROJECT_ROOT (optional)
  - parent epic reference (optional)
outputs:
  - updated story definition (if refining) or task list (if story confirmed ready)
constraints:
  - do not persist until user Confirms at review gate
---

# Plan Story

You are the **orchestrator** for story refinement and task creation. You own the flow, when to ask the user vs proceed, and the **review gate**.

**Level: Story and Tasks.** Stories are the unit of sprint work: user story format, acceptance criteria, may include technical details and NFRs. Tasks are concrete implementation work items that live inside the story.

**Extend mode:** When the user includes `mode=extend` and requests adding tasks, add only new tasks — load existing tasks first and use them as a "do not duplicate" constraint.

## Workflow

### 1. Intake
- **Goal:** Resolve the story, parent epic, and detect mode.
- **Action:** Resolve the story from user input: read a local draft file, accept pasted content, or fetch from a configured source. Resolve the parent epic when available. Detect `mode=extend` in raw input. If you cannot resolve the story, ask the user. When `mode=extend` with add-tasks request, load the existing task list as a "do not duplicate" constraint.
- **Output:** Current story content; parent epic (for boundary context); mode (new | extend); existing tasks list (when extend + add-tasks); raw user input.

### 2. Refinement
- **Goal:** Apply user-requested changes to the story.
- **Action:** Apply changes (e.g. add acceptance criterion, change persona, add assumption). Use the **user-story-generation** skill when changing the user story line. Use the **acceptance-criteria-generation** skill when adding or changing acceptance criteria. Use **story-formatter** to assemble the updated story block. Keep story scope within parent epic boundaries. Ask if anything else should change or if the story is ready for tasks.
- **Branch:** If the user says the story is **ready** (e.g. "story is ready", "create tasks"), go to Step 3. Otherwise stay in refinement.
- **Output:** Updated story block; no persistence yet.

## Story Format (for updates)

```markdown
## Story: [Short title]

**Summary:** [One line]

### Description
**User story**
As a [persona], I want [capability], so that [benefit].

**Context** (optional)
[Brief context if needed.]

**Technical / NFR notes** (optional)
[Technical details or NFRs for this story when relevant.]

### Acceptance Criteria
- [ ] [Criterion 1 — testable, observable]
- [ ] [Criterion 2]

### Assumptions
- [Assumption 1]

### Open Questions
- [Points to be addressed in refinement or implementation.]
```

### 3. Task definition (when story is ready)
- **Goal:** Decompose the story into concrete tasks.
- **When mode=new:** Each task = one concrete work item (implementation, test, doc, etc.). Output task descriptions only — one line per task.
- **When mode=extend:** Draft only additional tasks not already in the existing list.
- **Output:** Task list. No persistence yet.

## Task Format

```markdown
## Tasks for story: [Story title]

- [ ] [Task 1 description]
- [ ] [Task 2 description]
- [ ] [Task 3 description]
```

### 4. Review gate (hard stop)
- **Goal:** User confirms, edits, or cancels.
- **Action:** Present either (a) the updated story (if refinement only) or (b) the task list (if story confirmed ready). Ask:
  - **Confirm** → proceed to Step 5.
  - **Edit** → return to Step 2 or 3 as needed, then back here.
  - **Cancel** → stop; no persistence.
- **Rule:** Do **not** persist before the user explicitly **Confirms**.

### 5. Persistence (only after Confirm)
- **Story updates:** Derive a slug from the title. Write to `<BACKLOG_BASE>/stories/<slug>.md` (create or overwrite). Report the path.
- **Tasks:** Write the task list to `<BACKLOG_BASE>/tasks/<story-slug>.md`. Report the path.
- **Via extension (optional):** If a persistence extension is configured, delegate to that extension's flow with the updated story and/or task list and parent references.
- **BACKLOG_BASE:** Resolved from `PROJECT_ROOT` + project config when set; otherwise the global bundle root.

## Rules

- Resolve skills by walking **GARAGE_SEARCH_ROOTS** in order; first match for `skills/<name>/` wins.
- Do not persist until the user **Confirms** at the review gate.
- Do not add scope beyond the story when creating tasks.
- Story scope must not exceed parent epic scope.
