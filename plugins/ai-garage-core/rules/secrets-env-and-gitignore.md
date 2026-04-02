---
description: When editing .gitignore in application repos, keep secret env files ignored and allow committed *.template.env. Never solicit secrets in chat — use env vars and gitignored local files.
globs: "**/.gitignore"
---

# Secrets, `.env`, and `.gitignore`

## Do not solicit secrets in chat

When authoring or editing Garage assets (skills, agents, rules, commands), **never** ask the user to paste passwords, API tokens, or private keys in chat. Point users to **environment variables** and/or a **local gitignored** env file (e.g. `${CLAUDE_PLUGIN_ROOT}/skills/<skill-name>/<skill-name>.env`).

## `.gitignore` for env files

When creating or updating **`.gitignore`** in a project repo:

- Ignore real env files; allow **committed templates** whose names end in `.template.env`.
- `*.env` matches many `*.env` filenames; pair with **`!*.template.env`** so templates stay tracked.
- List **`.env`** explicitly (some Git ignore rules do not treat `.env` as matching `*.env`).

Suggested baseline (extend with `.env.local`, `.env.production`, etc. as needed):

```gitignore
.env
*.env
!*.template.env
```

If the team commits **`.env.example`**, ensure no pattern ignores it, or add **`!.env.example`** after broader rules.

## Installed skills (reference)

User-filled secrets for an installed skill often live at **`${CLAUDE_PLUGIN_ROOT}/skills/<skill-name>/<skill-name>.env`**. That path is outside normal project git trees when using a global Garage install; project repos still benefit from the `.gitignore` patterns above for workspace-level `.env` files.
