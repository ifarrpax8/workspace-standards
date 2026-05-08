---
description: Conventional commit format for commits and PR titles — per ADR 00038
globs: []
alwaysApply: false
type: "manual"
---

# Commit Standards

Per ADR 00038, all repositories use **Conventional Commits** enforced via squash merge. The PR title becomes the commit message on `main` — it must follow the format.

## Format

```
type(TICKET-ID): description
```

- **type** — one of the types below
- **TICKET-ID** — the Jira ticket (e.g. `HRZN-123`, `MRR-305`)
- **description** — imperative present tense, lowercase first letter, no trailing period

```
feat(HRZN-123): add currency exchange rate caching
fix(MRR-305): handle null billing terms on invoice creation
test(HRZN-456): add contract tests for payment service
```

## Types

| Type | Use for |
|---|---|
| `feat` | New feature or user-facing capability |
| `fix` | Bug fix |
| `refactor` | Code change that isn't a feature or fix |
| `test` | Adding or correcting tests |
| `docs` | Documentation only |
| `chore` | Build process, tooling, dependency updates |
| `perf` | Performance improvement |
| `style` | Formatting, whitespace — no logic change |
| `ci` | CI/CD configuration |
| `deps` | Dependency updates (matches ADR 00038 explicitly) |

## Breaking Changes

Append `!` after the type for breaking changes:

```
feat(HRZN-123)!: remove deprecated currency conversion endpoint
```

## Description Guidelines

- Imperative, present tense: `add`, `fix`, `update` — not `added`, `fixes`, `updating`
- Lowercase first letter
- No trailing period
- Describe **what** the change does, not what you did
- Keep it under 72 characters

## Individual Commits

Apply the same format to individual commits during development — it makes the squash PR title easy to derive and keeps history readable during review:

```bash
git commit -m "feat(HRZN-123): add exchange rate composable"
git commit -m "test(HRZN-123): add unit tests for composable"
```

## Branch Naming

Use the ticket ID only:

```bash
git checkout -b HRZN-123
```

Not: `feature/HRZN-123-add-currency-exchange-rate-caching`
