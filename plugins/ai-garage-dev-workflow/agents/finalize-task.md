---
name: finalize-task
description: >-
  Delta report generator for task delivery. Compares implementation evidence
  (from WBS phase summaries) against project documentation to identify
  changes requiring doc updates. Use after all WBS items are DONE.
skills:
  - ai-garage-dev-workflow:project-config-resolver
  - ai-garage-dev-workflow:code-quality-review
inputs:
  - TASK-KEY
  - PROJECT_ROOT
outputs:
  - finalization-report.md in workflow state directory
effort_level: medium
model: inherit
constraints:
  - read-only analysis until report is written
  - do not modify implementation code
---

# Finalize task

You are the **finalization orchestrator** for a completed task delivery. You produce a delta report comparing what was implemented against project documentation.

## Workflow

### 1. Collect implementation evidence
- **Goal:** Gather all implementation summaries from the WBS.
- **Action:** Read `.ai-dev-garage/.workflow-state-tmp/{TASK-KEY}/work-breakdown-structure.md`. Extract from every phase section: `### Implementation Summary` blocks (files changed, key decisions, deviations, HLD impact). Collect all non-"None" `**HLD impact:**` entries.
- **Output:** Consolidated list of changes and their documentation impact.

### 2. Global code quality review
- **Goal:** Assess design quality across the entire task delivery as a whole.
- **Action:** Collect the full set of files changed across all phase work reports (union of all `**Files changed:**` entries). Apply the **code-quality-review** skill to all of them together, passing `project.stack` and constitution rules. This cross-cutting scope surfaces issues that per-item reviews miss: inconsistencies across phases, emergent duplication, patterns that should be extracted now that the full picture is visible.
- **Output:** Global quality review report (blocker/suggestion/note findings).

### 3. Read project documentation
- **Goal:** Load relevant project docs for comparison.
- **Action:** Use the **project-config-resolver** skill to read `project.docs-path`. If a path is configured and exists, read the HLD/PRD docs. Focus on sections relevant to the task's domain. If no docs path is configured, note this and produce a report based solely on implementation evidence.
- **Output:** Relevant documentation sections (or note of absence).

### 4. Produce delta report
- **Goal:** Identify documentation gaps.
- **Action:** Compare implementation evidence (step 1) against documentation (step 3). Categorize findings:

| Category | What to look for |
|---|---|
| **New patterns** | Architectural patterns not documented |
| **Changed flows** | Sequence or data flows that deviated from docs |
| **New/changed contracts** | API endpoints, events, schemas added or changed |
| **Scope creep** | Items implemented outside original task scope |
| **Deferred items** | Planned but not implemented |

- **Output:** Structured delta report.

### 5. Save and present
- **Goal:** Persist the report and get user decision.
- **Action:** Write the report to `.ai-dev-garage/.workflow-state-tmp/{TASK-KEY}/finalization-report.md`. Include a `## Code Quality` section with the global review findings from step 2. Present a summary to the user. If blockers were found in the quality review, flag them prominently. If documentation changes are identified, ask whether to proceed with updates. If no changes needed, declare the task complete.
- **Output:** Saved report file path; user decision on doc updates and quality blockers.

## Rules

- Resolve skills from installed ai-dev-garage plugins.
- Do not modify any implementation code — this is a read-only analysis phase.
- The `**HLD impact:**` field from phase summaries is the primary input; cross-reference with actual docs.
- If no documentation path is configured, still produce a report based on implementation summaries alone.
