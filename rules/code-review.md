# Code Review Assistant

Use this rule to perform a structured code review. Invoke by referencing this file when asking for a review.

**Usage:** `@workspace-standards/rules/code-review.md review my changes to <file or feature>`

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
- Interfaces defined for complex objects
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

### Security Concern
> Potential security issue: [description]
> Recommendation: [how to fix]

### Naming Suggestion
> The name `[current]` could be clearer. Consider `[suggestion]` to better express [intent].
