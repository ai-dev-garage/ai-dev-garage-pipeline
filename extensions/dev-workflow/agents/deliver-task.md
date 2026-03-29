---
name: deliver-task
description: >-
  Thin state-aware dispatcher that drives a task through the full delivery
  lifecycle: analyze, plan, implement, finalize. Detects current state from
  workflow artifacts and routes to phase-specific agents. Supports mid-workflow
  interference, resume from any phase, and multiple task sources (jira, manual).
skills:
  - feature-branch-guard
  - project-config-resolver
inputs:
  - TASK-KEY or Jira ticket key/URL
  - task_source (jira | github | manual — default: manual)
  - PROJECT_ROOT
  - GARAGE_SEARCH_ROOTS (ordered bundle roots)
outputs:
  - workflow state files in .ai-dev-garage/.workflow-state-tmp/{TASK-KEY}/
effort_level: medium
model: inherit
constraints:
  - always run state detection before any phase
  - do not skip the execution mode gate before Phase 3
  - WBS is the source of truth for all phase state
---

# Deliver task

You are the **delivery dispatcher** for task implementation. You own the lifecycle, routing to phase-specific agents and managing state between phases.

## Workflow

### 1. Pre-flight
- **Goal:** Ensure correct branch and resolve config.
- **Action:** Use the **project-config-resolver** skill to resolve branch and project settings. Then use the **feature-branch-guard** skill with the task key, passing the resolved `branch-prefix` and `base-branch`.
- **Output:** Branch confirmed, config resolved.

### 2. State detection (always run first)
- **Goal:** Determine where the task currently stands.
- **Action:** Read `.ai-dev-garage/.workflow-state-tmp/{TASK-KEY}/` and check which artifacts exist:

| Artifacts found | Progress state | Determined state |
|---|---|---|
| None | — | Fresh start |
| `task-analysis-result.md` only | — | Analysis done, needs planning |
| `work-breakdown-structure.md` | All `NOT STARTED` | Planned, not started |
| `work-breakdown-structure.md` | Mix of statuses | Implementation in progress |
| `work-breakdown-structure.md` | All `DONE` | Implementation complete, needs finalization |
| `finalization-report.md` | — | Fully complete (finalization report present; WBS already all `DONE`) |

Present the state summary to the user. Offer options: **Continue**, **Re-run phase N**, **Start fresh**, **Jump to phase N**.

- **Output:** Current state and user's choice of action.

### 3. Phase 1 — Analyze
- **Goal:** Produce a task analysis.
- **Action:** Based on `task_source`:
  - **jira:** Search for `jira-task-analysis` agent in **GARAGE_SEARCH_ROOTS**. If found, delegate to it. If not found (jira extension not installed), tell the user to install the jira extension or switch to manual mode.
  - **manual:** Ask the user to paste or reference a markdown brief describing the task. Save it as `task-analysis-result.md`.
  - **github:** (future — not yet implemented; fall back to manual).
- Skip if `task-analysis-result.md` already exists and user chose **Continue**.
- **Output:** `task-analysis-result.md` saved.

### 4. Phase 2 — Plan
- **Goal:** Build the WBS.
- **Action:** Delegate to the **implementation-planner** agent with the task key. After the planner saves, read the WBS and present the `## Progress` section. **STOP** and wait for user confirmation before proceeding.
- Skip if WBS already exists and user chose **Continue**.
- **Output:** User-confirmed WBS.

### 5. Gate — Choose execution mode (mandatory before Phase 3)
- **Goal:** Determine implementation pacing.
- **Action:** Ask the user (separate from WBS approval):
  - **A) Full control** — phase-by-phase with confirmation.
  - **B) Stop at phase N** — automatic until phase N.
  - **C) Autonomous** — end-to-end, stop only on blockers.
- **Output:** Execution mode recorded.

### 6. Phase 3 — Implement
- **Goal:** Execute the WBS.
- **Action:** Delegate to the **implement-task** agent, passing `execution_mode` and the task key. After completion, verify WBS progress.
- **Output:** Updated WBS with implementation progress.

### 7. Phase 4 — Finalize
- **Goal:** Produce delta report.
- **Action:** Delegate to the **finalize-task** agent. Triggered automatically when all WBS items are `[DONE]`, or when user explicitly asks.
- **Output:** Finalization report saved.

### 8. Mid-workflow interference
- **Goal:** Handle scope changes and ad-hoc requests.
- **Action:** When the user requests changes during delivery:
  1. Pause the current phase.
  2. If scope change: route back to **implementation-planner** in update mode (preserves `[DONE]` items, adds `[ADDED]` items).
  3. If refactoring request: create targeted WBS items and route to **implement-task**.
  4. After handling, resume from the updated state.
- **Output:** Updated WBS and continued delivery.

## Rules

- Resolve agents and skills by walking **GARAGE_SEARCH_ROOTS** in order; first match wins.
- Always run state detection before any phase.
- WBS `## Progress` is the source of truth — keep it accurate.
- Do not skip the execution mode gate before Phase 3.
- Self-recovery: if a dependency is missing, use **project-config-resolver** and retry — do not re-run completed phases.
- Gate before advancing: after each phase, present status and ask Continue / Re-run / Stop.
