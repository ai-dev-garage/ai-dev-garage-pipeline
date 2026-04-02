# Implement code — reference

## Constitution as the source of project-specific patterns

This skill is intentionally language-agnostic. All project-specific patterns, conventions, and architecture rules live in the project's `CONSTITUTION.md` file, managed via the `update-constitution` command.

When a constitution exists, the skill reads and enforces it. When it does not, the skill falls back to general best practices inferred from the codebase.

## WBS state file location

WBS state files live at `.ai-dev-garage/.workflow-state-tmp/{TASK-KEY}/work-breakdown-structure.md`.

The `## Progress` section uses this format:

```markdown
## Progress

- [x] [DONE] Phase 1: Data model
- [ ] [IN PROGRESS] Phase 2: Business logic
- [ ] [NOT STARTED] Phase 3: Integration tests
```

## Implementation Summary format

Each phase in the WBS can have an `### Implementation Summary` block:

```markdown
### Implementation Summary

- **Files changed:** list of modified/created files
- **Key decisions:** architectural or design choices made
- **Deviations from plan:** differences from the WBS plan (if any)
- **HLD impact:** documentation updates needed, or "None"
```

## Self-review checklist (generic)

After implementation, verify:

- [ ] All constitution principles checked (if constitution exists)
- [ ] No unnecessary duplication introduced
- [ ] Build command passes for affected modules
- [ ] Test command passes for affected modules
- [ ] No hardcoded secrets or credentials
- [ ] No debug/temporary code left in
