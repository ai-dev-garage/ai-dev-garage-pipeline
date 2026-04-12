# This is ai-garage-assistant playbook.

Available rules:

| Rule Path | Keywords / Triggers | Always-on |
|-----------|-------------------|-----------|
| `{{PLUGIN_ROOT}}/rules/claude-project-setup.md` | claude desktop, claude mobile, claude app, claude project, configure for desktop, set up on phone, notion setup | No |

**Enforcement:**
- **Always-on = Yes:** These rules are loaded in full at session start (appended below). Follow them throughout the entire session regardless of context.
- **Always-on = No:** When you encounter any keyword or trigger listed above in the user's message or task context, immediately load the corresponding rule file into the current context using the Read tool and follow its instructions.
