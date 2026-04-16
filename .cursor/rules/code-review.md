---
description: Structured code review checklist covering standards, security, and quality across all languages
alwaysApply: false
---

# Code Review Assistant

Use this rule to perform a structured code review. Invoke by referencing this file when asking for a review.

**Usage:** `@workspace-standards/rules/code-review.md review my changes to <file or feature>`

---

## Standard automation (before merge)

Automated gates should pass before approving a PR. Use the commands that apply to the repository under review.

**Vue MFE** — Pax8 micro-frontends use the same `package.json` script names across repos:

| Command | Purpose |
|---------|---------|
| `npm run vitest:ci` | Unit tests (CI mode) |
| `npm run check-for-errors` | Lint, typecheck, formatting, and i18n checks (exact steps vary by repo) |
| `npm run vitest:coverage` | Coverage report (optional; thresholds are defined per repo in `vitest.config`) |

Other scripts often used locally or in CI: `npm run tsc`, `npm run lint`, `npm run prettier`, `npm run i18n-kvp-test` (when present).

Many MFEs run the same checks via Husky pre-push; CI should be green for these targets.

**Groovy monolith / Kotlin (Gradle):**

| Command | Purpose |
|---------|---------|
| `./gradlew check` | Tests plus static analysis (PMD, CodeNarc, etc., as configured) |

`./gradlew test` alone is not always sufficient where CI enforces additional checks.

**Terraform:** follow the repo’s CI and conventions for `terraform validate`, `fmt`, and plan policies.

Do not approve if the relevant automated checks fail for the changed code paths.

---

## Review Process

When reviewing code, evaluate against these criteria in order:

### 1. Architecture Alignment

Check if the code follows the golden path for its project type:

**Kotlin Spring Boot:**
- [ ] Controllers only handle HTTP concerns (no business logic)
- [ ] Business logic is in service layer
- [ ] Repository pattern used for data access
- [ ] DTOs separate from domain entities

**Kotlin Axon:**
- [ ] Commands express intent (imperative naming)
- [ ] Events represent facts (past tense naming)
- [ ] @EventSourcingHandler has no side effects
- [ ] Aggregate validates business rules before applying events

**Vue MFE:**
- [ ] Uses `<script setup>` with TypeScript
- [ ] Props and emits are typed
- [ ] Composables used for reusable logic
- [ ] Services handle API calls

**Terraform:**
- [ ] Modules and layouts follow team conventions; state and secrets handled safely
- [ ] `terraform fmt` / validate (or project CI equivalent) satisfied for changed files

**Groovy/Java Monolith:**
- [ ] Controller follows Interface + Implementation pattern (`@Endpoint` on interface, impl extends `AbstractBaseController`)
- [ ] Controllers delegate to services — no business logic in controllers
- [ ] Services organized under appropriate domain package in `service/`
- [ ] Domain objects stay anemic — behavior in services, not domain classes
- [ ] New code positioned for future extraction (minimal cross-domain dependencies)
- [ ] `./gradlew check` passes (tests + PMD + CodeNarc)

### 2. Code Quality

- [ ] No linter warnings introduced
- [ ] Functions are focused (single responsibility)
- [ ] No magic numbers or strings (use constants)
- [ ] Naming is clear and consistent
- [ ] No commented-out code
- [ ] Complex logic has explanatory comments

### 3. Testing

- [ ] New code has corresponding tests
- [ ] Bug fixes include a regression test that fails before the fix and passes after
- [ ] New interactive components (search bars, tables, drawers) have at least a basic render + interaction test
- [ ] Test files are co-located with the feature they test
- [ ] Tests follow naming convention (`should...when...`)
- [ ] Edge cases covered
- [ ] No skipped tests without justification

### 4. Security

- [ ] No hardcoded secrets or credentials
- [ ] Input validation present
- [ ] Proper error handling (no stack traces exposed)
- [ ] No SQL injection or XSS vulnerabilities

### 5. Documentation

- [ ] README updated if public API changed
- [ ] ADR created for architectural decisions
- [ ] Function/class documentation for public APIs

### 6. Frontend / Vue MFE cross-cutting

When the change touches `*.vue`, `*.ts` in an MFE, or user-facing behaviour:

- [ ] **Accessibility:** keyboard navigation and focus; ARIA where needed; labels for controls; sufficient contrast; meaningful alt text
- [ ] **Performance:** avoid unnecessary re-renders and duplicate API calls; watch for bundle size regressions; prefer `computed` over redundant `watch` where appropriate; lazy-load heavy routes or components when relevant
- [ ] **Permissions and feature flags:** UI and API calls respect permission checks; graceful behaviour when access is denied
- [ ] **Contracts and breaking changes:** routes, props, shared components, or public APIs — call out breaking changes and any migration path

---

## Severity decision tree

Classify findings (maps to Critical / Suggestions / Nitpicks in the output format below):

1. **Security issue, data loss, failed CI, or broken automated tests for this change?** → Critical (must fix)
2. **Otherwise: breaks existing behaviour, violates architecture, or missing required tests for new risk?** → Critical or Suggestions (by scope)
3. **Otherwise: material gap in quality, coverage, performance, accessibility, or i18n?** → Suggestions
4. **Otherwise** → Nitpicks (optional)

---

## Review Output Format

Provide feedback in this structure:

```markdown
## Code Review: [Feature/File Name]

### Summary
[1-2 sentence overview of the changes]

### Strengths
- [What was done well]

### Issues Found

#### Critical (must fix)
- [ ] [Issue description and location]

#### Suggestions (recommended)
- [ ] [Improvement suggestion]

#### Nitpicks (optional)
- [ ] [Minor style/preference items]

### Architecture Compliance
[Golden path] alignment: [✅ Aligned / ⚠️ Minor deviations / ❌ Significant gaps]

### Recommendation
[APPROVE / REQUEST CHANGES / NEEDS DISCUSSION]
```

---

## Quick Checks by File Type

### *.kt (Kotlin)
```
- No @Autowired (use constructor injection)
- No !! (non-null assertion) without justification
- Data classes for DTOs
- Proper exception handling
```

### *.groovy (Groovy Monolith)
```
- No `def` when type is known (explicit types)
- No parameter reassignment (CodeNarc enforces)
- @CompileStatic on performance-critical paths
- @Inject for dependencies (constructor injection preferred for new code)
- @Transactional for data-modifying service methods
- Spock preferred for new tests
```

### *.java (Monolith Java)
```
- No new PMD violations
- No @SuppressWarnings without documented justification
- Named parameters for SQL (no concatenation)
```

### *.vue (Vue Component)
```
- <script setup> used
- Props typed with defineProps<{}>()
- Emits typed with defineEmits<{}>()
- No v-html without sanitization
- i18n used for user-facing text
```

### *.ts (TypeScript)
```
- No 'any' types
- No @ts-ignore
- Prefer `type` for object shapes and complex props (see project conventions)
- Async/await pattern (not .then chains)
```

### *Test.kt / *.test.ts
```
- Test name describes behavior
- Arrange-Act-Assert pattern
- Mocks are minimal and appropriate
- No hardcoded test data that could break
```

---

## Common Feedback Templates

### Missing Tests
> This change adds new functionality but no corresponding tests. Please add tests that cover:
> - Happy path scenario
> - Error/edge cases
> - [Specific scenarios based on the code]

### Architecture Violation
> This code places [business logic/data access] in the [controller/service/component]. 
> Per our golden path, this should be in the [correct layer].
> Reference: [link to golden path doc]

### Monolith Build Verification
> Please run `./gradlew check` before pushing — this includes tests, PMD, and CodeNarc.
> `./gradlew test` alone is not sufficient; CI enforces static analysis.

### Vue MFE Build Verification
> Please run `npm run vitest:ci` and `npm run check-for-errors` before pushing — these are the standard Pax8 MFE gates (same script names across MFE repos).
> Coverage expectations are defined per repo in `vitest.config`.

### Security Concern
> Potential security issue: [description]
> Recommendation: [how to fix]

### Naming Suggestion
> The name `[current]` could be clearer. Consider `[suggestion]` to better express [intent].

---

## Appendix: Optional weighted scoring (formal reviews)

Use when a numeric summary helps (e.g. release readiness or large PRs). Score each category **0–10**, then combine with weights.

| Category | Weight | What to score |
|----------|--------|----------------|
| **A.** Code correctness and functionality | 25% | Requirements met, edge cases, absence of defects |
| **B.** Code quality and maintainability | 20% | Structure, readability, SOLID, duplication |
| **C.** Testing and coverage | 20% | Tests for new logic, error paths, repo thresholds |
| **D.** TypeScript and type safety | 15% | Sound types, minimal `any`, justified assertions |
| **E.** Vue best practices | 10% | Composition API, reactivity, component boundaries |
| **F.** Performance and optimisation | 5% | Renders, API usage, algorithms, bundle impact |
| **G.** Documentation and comments | 5% | Where complexity needs “why”, public API clarity |

**Overall score** = (A×0.25) + (B×0.20) + (C×0.20) + (D×0.15) + (E×0.10) + (F×0.05) + (G×0.05)

**Interpretation (guide):** 9.0–10.0 excellent; 7.5–8.9 good; 6.0–7.4 acceptable with follow-ups; below 6.0 needs meaningful rework before merge. Adjust thresholds to team norms.
