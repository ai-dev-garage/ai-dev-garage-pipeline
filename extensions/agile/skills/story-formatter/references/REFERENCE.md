# story-formatter — Reference

## Purpose

Produce a consistently structured Story definition block ready for review, local storage, or persistence. Focus on actionable acceptance criteria and clear technical notes that a developer can act on immediately.

## Good vs bad story descriptions

**Good** — specific, testable, bounded:
> As a developer, I want database migrations to run automatically on startup, so that deployments require no manual intervention.

**Bad** — vague, unmeasurable:
> As a developer, I want things to work better when deploying.

## Good vs bad acceptance criteria for stories

**Good** — observable, binary pass/fail:
> - Given the app starts, all pending migrations run before the first request is served.
> - Given a migration fails, the app exits with a non-zero code and logs the error.

**Bad** — subjective or implementation-specific:
> - Migrations should be fast.
> - The code should be clean.

## Story points guidance

| Points | Scope |
|--------|-------|
| 1 | Trivial change, no design decision |
| 2 | Small, well-understood, single component |
| 3 | Moderate, touches a few areas, some unknowns |
| 5 | Complex, multiple components, non-trivial design |
| 8 | Large, significant unknowns — consider splitting |
