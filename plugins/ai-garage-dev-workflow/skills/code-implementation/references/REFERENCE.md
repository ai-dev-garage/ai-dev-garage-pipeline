# Implement code — reference

## Constitution as the source of project-specific patterns

This skill is intentionally language-agnostic. All project-specific patterns, conventions, and architecture rules live in the project's `CONSTITUTION.md` file, managed via the `update-constitution` command.

The calling agent reads the constitution and passes relevant rules as input. This skill applies them.

## Self-review checklist

After implementation, verify:

- [ ] All constitution principles checked (if provided)
- [ ] No unnecessary duplication introduced
- [ ] Build command passes for affected modules
- [ ] Test command passes for affected modules
- [ ] No hardcoded secrets or credentials
- [ ] No debug/temporary code left in

## Stack extensions

Stack-specific plugins can provide extension skills that compose on top of this skill. The naming convention is `{stack}-code-implementation` (e.g., `java-code-implementation`, `node-code-implementation`).

Extension skills:
- Contain only stack-specific delta guidance, not a copy of this skill.
- Are loaded by the calling agent when `project.stack` matches.
- Apply their patterns **after** this skill's instructions.
- Use `extends: ai-garage-dev-workflow:code-implementation` in frontmatter.

Precedence: CONSTITUTION.md > Stack extension > This skill (for any conflicting guidance).
