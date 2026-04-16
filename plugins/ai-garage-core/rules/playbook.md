# This is ai-garage-core playbook.

Available rules:

| Rule Path | Keywords / Triggers | Always-on |
|-----------|-------------------|-----------|
| `{{PLUGIN_ROOT}}/rules/garage-runtime.md` | garage, runtime, classify, plan, execute, review, summarize, memory, project overrides | Yes |
| `{{PLUGIN_ROOT}}/rules/configure-nudge.md` | configure, first-run, plugins.installed, project-config.yaml, doctor | Yes |
| `{{PLUGIN_ROOT}}/rules/secrets-env-and-gitignore.md` | secrets, env, .env, gitignore, credentials, tokens, api key | No |

**Enforcement:**
- **Always-on = Yes:** These rules are loaded in full at session start (appended below). Follow them throughout the entire session regardless of context.
- **Always-on = No:** When you encounter any keyword or trigger listed above in the user's message or task context, immediately load the corresponding rule file into the current context using the Read tool and follow its instructions.
