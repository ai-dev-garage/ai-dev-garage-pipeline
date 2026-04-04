# Code quality review — reference

## Design quality problem taxonomy

These problems are paradigm-neutral. Each section maps them to the vocabulary of common paradigms.

### Cohesion

A unit does too many things — its reasons to change come from more than one concern.

| Paradigm | How it appears | Idiomatic fix |
|---|---|---|
| Class-based OOP | God class; service handling unrelated operations | Extract class; apply SRP |
| Protocol-oriented | Protocol with unrelated requirements | Split protocol |
| Functional | Function with side-effects mixed into computation | Separate pure transform from effectful call |
| Mixed OOP+FP | Class methods mixing domain logic and I/O | Extract pure functions; inject effects |
| Component UI | Component mixing data fetching, transformation, and rendering | Extract custom hook / container component |

### Coupling

A unit depends on concrete implementation details it should not need to know.

| Paradigm | How it appears | Idiomatic fix |
|---|---|---|
| Class-based OOP | `new ConcreteType()` inside a method; depends on class, not interface | Constructor injection; depend on interface/abstract |
| Protocol-oriented | Depends on concrete struct/class instead of protocol | Depend on protocol |
| Functional | Hardcoded function call instead of passed-in function | Pass function as parameter (higher-order) |
| Mixed OOP+FP | Direct import of module singleton | Inject dependency; use factory function |
| Component UI | Hardcoded API client or service inside component | Accept as prop or provide via context |

### Abstraction leak

A unit exposes internal implementation details through its interface.

| Paradigm | How it appears | Idiomatic fix |
|---|---|---|
| Class-based OOP | Public fields; returning mutable internal collections | Expose through methods; return copies or read-only views |
| Protocol-oriented | Protocol exposes concrete associated types unnecessarily | Use opaque types or abstract associated type constraints |
| Functional | Leaking internal data shape through module boundary | Define explicit public type alias |
| Component UI | Exposing internal state shape through props | Pass only what the parent needs |

### Rigidity

Adding a new variant or behavior requires modifying existing units.

| Paradigm | How it appears | Idiomatic fix |
|---|---|---|
| Class-based OOP | Switch/if-else on type tags; modification required to add case | Strategy pattern; polymorphism |
| Protocol-oriented | Switch on enum in multiple places | Protocol + conformance; or sealed class + exhaustive match |
| Functional | Pattern match on concrete type spread across the codebase | Centralize dispatch; use type class or protocol |
| Component UI | Conditional rendering based on ever-growing prop enum | Composition; render props; slot pattern |

### Interface bloat

A contract exposes more than its consumers need.

| Paradigm | How it appears | Idiomatic fix |
|---|---|---|
| Class-based OOP | Interface with many methods; callers only use a subset | Split interface (ISP) |
| Protocol-oriented | Protocol with too many requirements | Compose smaller protocols |
| Functional | Function with too many parameters; record with too many fields | Introduce parameter object; split record |
| Component UI | Component accepting many props; parent controls too much | Extract sub-components; lift only necessary state |

### Substitutability

Implementations cannot be swapped without breaking callers. Apply where paradigm-relevant — less applicable in purely functional code.

| Paradigm | How it appears | Idiomatic fix |
|---|---|---|
| Class-based OOP | Subclass changes behavior callers depend on | Prefer composition over inheritance; favour interfaces |
| Protocol-oriented | Conformance changes semantic contract of protocol | Document protocol contract; add preconditions |
| Component UI | Swap of child component breaks parent due to undocumented prop contract | Define explicit prop interface |

---

## Output format

```markdown
## Code Quality Review

**Target:** <path or description>
**Paradigm detected:** <paradigm(s)>
**Stack extension applied:** <name> | none

---

### [BLOCKER|SUGGESTION|NOTE] <Problem type> — <short title> (<file>:<line or range>)
**Problem:** <what is wrong and why it matters>
**Suggestion:** <idiomatic fix for the detected paradigm>

---

## Summary
- <N> blocker(s), <N> suggestion(s), <N> note(s)
- Main concern: <one sentence>
- Constitution violations: none | <list>
```

---

## Stack extension contract

Stack-specific skills named `{stack}-code-quality-review` compose on top of this skill.

Extension skills must:
- Provide only delta guidance — paradigm-specific vocabulary and idioms for the problems above.
- Reference base check step numbers where adding to them (e.g. "After step 3, also check...").
- Not duplicate the problem taxonomy — extend with stack-specific manifestations only.

Frontmatter example:

```yaml
---
name: swift-code-quality-review
description: Swift/iOS-specific code quality patterns. Use alongside code-quality-review on Swift projects.
extends: ai-garage-dev-workflow:code-quality-review
stacks: [swift, ios]
---
```

Precedence: CONSTITUTION.md > stack extension > base skill.
