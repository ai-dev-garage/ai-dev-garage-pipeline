# epic-formatter — Reference

## Purpose

Produce a consistently structured Epic definition block ready for review, local storage, or persistence. Epics define a coherent unit of business value delivered over multiple stories — keep scope bounded enough to complete within one quarter or less.

## Good vs bad epic titles

**Good** — outcome-oriented, bounded:
> "User authentication and session management"
> "Automated database migration pipeline"

**Bad** — vague, open-ended:
> "Make things more secure"
> "Backend improvements"

## Good vs bad business value statements

**Good** — measurable, stakeholder-visible:
> Reduces onboarding time for new users by removing manual account activation steps.

**Bad** — internal jargon, not business-facing:
> Refactors the auth module to use JWT instead of sessions.

## Good vs bad success criteria for epics

**Good** — verifiable at epic close:
> - All login and registration flows work without manual admin steps.
> - Session expiry is enforced and tested end-to-end.
> - Security audit checklist completed with no critical findings.

**Bad** — implementation detail, not outcome:
> - JWT library is integrated.
> - Sessions table is removed from the database.

## Scope boundaries

Always state both in-scope and out-of-scope explicitly. Epics without explicit exclusions tend to grow unboundedly.
