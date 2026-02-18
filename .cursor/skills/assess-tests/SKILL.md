---
name: assess-tests
description: Assess test completeness across the test pyramid with persona-driven gap analysis and priority recommendations.
---
# Assess Tests Skill

Systematic assessment of test completeness across the test pyramid. Evaluates scenario coverage (happy, error, boundary, edge), pyramid balance, test quality, and user journey coverage.

## Prerequisites

### Required MCP Servers

| MCP Server | Tools Used | Purpose | Required? |
|------------|------------|---------|-----------|
| **user-github** | `get_file_contents` | Fetch source and test files | Optional |
| **user-mcp-atlassian** | `jira_get_issue` | Fetch ticket for business context | Optional |

### Graceful Degradation

- **No GitHub MCP**: Read files from local workspace using file tools
- **No Engineering Codex**: Use built-in criteria; skip codex best practices and gotchas
- **No Jira MCP**: Skip business context enrichment; rely on code analysis only

## When to Use

Use this skill when:
- Reviewing test completeness before a release or PR
- Assessing whether a feature has adequate test coverage across the pyramid
- Identifying gaps in error path, boundary, and edge case testing
- Auditing the testing posture of a service or domain area
- Checking test quality (not just quantity) for a codebase

## When NOT to Use

- **Full repo quality score** across all categories (architecture, security, docs, etc.) — use [Score](../score/SKILL.md)
- **Reviewing a specific PR** — use [Code Review](../code-review/SKILL.md) which includes testing as one dimension
- **Writing or fixing tests** — use [Fix Bug](../fix-bug/SKILL.md) for defects or [Implement Ticket](../implement-ticket/SKILL.md) for new feature tests
- **Simple check** of whether a single test file exists — just search for it directly

## Invocation

```
Assess tests for the invoice aggregate in einvoice-connector
```

```
Assess tests for src/services/P8pInvoiceService.ts
```

```
Assess tests for the currency-manager service
```

## Workflow

### Phase 1: Scope & Context

1. **Determine scope** using AskQuestion:

```
What would you like me to assess?
1. File — A specific source or test file
2. Feature — A domain package or feature directory
3. Service — An entire repository (capped at ~20 source files by complexity)
```

2. **Identify the target path** from the user's input or ask for it

3. **Detect the tech stack** by scanning build files and file extensions:

| Indicator | Stack | Test Framework |
|-----------|-------|---------------|
| `build.gradle.kts` + `*.kt` | Kotlin/Spring Boot | JUnit 5, MockK, Testcontainers |
| `build.gradle.kts` + Axon deps | Kotlin/Axon | JUnit 5, AggregateTestFixture |
| `package.json` + `*.vue` | Vue MFE | Vitest, Testing Library |
| `build.gradle` + `*.groovy`/`*.java` | Groovy/Java monolith | Spock, JUnit |

4. **Load standards**:
   - Load the relevant testing rules from `.cursor/rules/` in the target repo
   - Load the relevant golden path from `@workspace-standards/golden-paths/`
   - If `@engineering-codex` is in the workspace:
     - Read `facets/testing/best-practices.md` for quality criteria
     - Read `facets/testing/gotchas.md` for anti-pattern checks
     - Read `facets/testing/architecture.md` for pyramid ratios
     - Read `facets/testing/test-personas.md` for scenario coverage perspectives (if available)

5. **Map source to test files**:
   - For each source file in scope, find its corresponding test file
   - Flag any source files with no test counterpart
   - **Service scope check**: If more than 20 source files are found, notify the user:

   ```
   This service has [N] source files. For a thorough assessment, I'll focus on
   the ~20 most complex files (by method count and branching logic). You can
   also narrow to a specific feature or file for deeper analysis.

   Proceed with top 20, or narrow scope?
   ```

### Phase 2: Test Inventory

Read all test files in scope and classify each test method:

**By pyramid layer:**

| Layer | Indicators |
|-------|-----------|
| Unit | Mocked dependencies, no `@SpringBootTest`, no Testcontainers, fast |
| Integration | `@SpringBootTest`, `@DataJpaTest`, Testcontainers, real database |
| Component | `@WebMvcTest`, `@WebFluxTest`, API slice tests |
| Contract | Pact, `PactDslJsonBody`, consumer/provider tests |
| E2E | Playwright, browser automation, full stack |

**By scenario type:**

| Type | What to look for |
|------|-----------------|
| Happy path | Standard input, expected output, success flow |
| Error path | Exceptions, error responses, failure handling, invalid state |
| Boundary | Zero, null, empty, max values, exactly-at-limit, off-by-one |
| Edge case | Concurrent access, race conditions, unusual but valid input combinations |
| Security | Auth bypass attempts, injection, privilege escalation |

**By test persona** (if codex test-personas.md available):

| Persona | Focus |
|---------|-------|
| The Optimist | Happy path — does the feature work as designed? |
| The Saboteur | Error path — what happens when things go wrong? |
| The Boundary Walker | Boundary — what happens at the limits? |
| The Explorer | Edge cases — what about unusual but valid scenarios? |
| The Auditor | Security and compliance — can rules be bypassed? |
| The User | Journey — does the end-to-end flow work for real users? |

**Checkpoint**: Present the inventory to the user before proceeding.

```
## Test Inventory: [scope]

Found [N] test files with [M] test methods.

| Layer | Count | % |
|-------|-------|---|
| Unit | ... | ... |
| Integration | ... | ... |
| ... | ... | ... |

| Scenario Type | Count | % |
|---------------|-------|---|
| Happy path | ... | ... |
| Error path | ... | ... |
| Boundary | ... | ... |
| Edge case | ... | ... |

Source files with no tests: [list]

Does this look right? Should I adjust scope before continuing?
```

### Phase 3: Source Analysis

Read source files to identify testable behaviors:

**For Kotlin/Spring Boot:**

| Source Element | Testable Behaviors |
|---------------|-------------------|
| `@PostMapping`, `@GetMapping` etc. | Endpoint request/response, validation, auth |
| Service methods | Business logic branches, calculations, state changes |
| `@CommandHandler` | Command validation, event application, rejection cases |
| `@EventSourcingHandler` | State mutation (must have no side effects) |
| `@SagaEventHandler` | Saga coordination, compensation, timeout handling |
| Repository queries | Query correctness, empty results, pagination |
| Exception handlers | Error response format, logging, status codes |

**For Vue MFE:**

| Source Element | Testable Behaviors |
|---------------|-------------------|
| Component props/emits | Rendering with different props, emit payloads |
| Composable functions | Reactive state, computed values, async operations |
| Service methods | API calls, error handling, data transformation |
| Event handlers | User interaction, form submission, navigation |
| Conditional rendering | Show/hide logic, loading states, empty states, error states |

For each testable behavior, determine which scenario types apply:
- Does the behavior have a success case? → Happy path needed
- Can it fail or throw? → Error path needed
- Does it accept numeric/string/collection input? → Boundary needed
- Are there conditional branches or business rules? → Edge case needed

**Interactive moment**: If ambiguous business logic is found, ask the user:

```
I found conditional logic in [method/component]. Are there specific business
rules or domain constraints I should know about? For example:
- Threshold values for calculations
- Time-based behavior (expiry, scheduling)
- Role-based access differences
```

### Phase 4: Gap Analysis

Cross-reference Phase 2 (what's tested) against Phase 3 (what's testable).

Produce findings in four categories:

**1. Missing Tests** — Testable behaviors with no test at all
- List each untested behavior with its source location
- Severity: CRITICAL if it's a public endpoint or core business logic, HIGH otherwise

**2. Incomplete Scenarios** — Tested but missing scenario types
- For each tested behavior, identify which scenario types are missing
- Severity: HIGH if missing error paths for external integrations, MEDIUM for missing boundaries

**3. Pyramid Imbalance** — Compare actual ratios against targets
- Target: Unit 70-80%, Integration 15-20%, E2E 5-10%
- Flag if inverted (ice cream cone) or if layers are entirely missing
- Severity: MEDIUM for imbalance, HIGH if no integration tests exist

**4. Test Quality Concerns** — Anti-patterns in existing tests
- Check against codex gotchas (or built-in list):
  - Over-mocking (everything mocked, nothing real tested)
  - Sleep-based waits (`Thread.sleep`, `page.waitForTimeout`)
  - Assertion-free tests (test runs but asserts nothing)
  - Implementation coupling (testing private methods, internal state)
  - Shared mutable state between tests
  - Copy-paste test setup (no shared fixtures)
- Severity: varies by anti-pattern

### Phase 5: Report

Output the structured assessment:

```markdown
## Test Assessment: [scope]

**Tech stack:** [detected]
**Standards applied:** [rules and golden paths loaded]
**Source files assessed:** [N]
**Test files found:** [M]

---

### Test Pyramid

  Unit:        [bar] [count] ([%])  [vs target 70-80%]
  Integration: [bar] [count] ([%])  [vs target 15-20%]
  Component:   [bar] [count] ([%])
  Contract:    [bar] [count] ([%])
  E2E:         [bar] [count] ([%])  [vs target 5-10%]

  Assessment: [Healthy / Top-heavy / Bottom-heavy / Missing layers]

### Scenario Coverage

| Behavior | Happy | Error | Boundary | Edge | Layer |
|----------|-------|-------|----------|------|-------|
| [name] | PASS/MISS | PASS/MISS | PASS/MISS/N/A | PASS/MISS/N/A | [layer] |
| ... | ... | ... | ... | ... | ... |

### Priority Gaps

1. [CRITICAL] [description] — [source location]
2. [HIGH] [description] — [source location]
3. [MEDIUM] [description] — [source location]
...

### Test Quality Concerns

| Concern | Files Affected | Recommendation |
|---------|---------------|----------------|
| [anti-pattern] | [files] | [how to fix] |
| ... | ... | ... |

### Strengths
- [What's done well in the existing tests]

### Summary
[2-3 sentence overall assessment with top priority action]
```

### Phase 6: Generate (Optional)

After presenting the report, offer next steps:

```
What would you like to do?
1. Generate test stubs for the priority gaps
2. Deep-dive into a specific area (re-run at file scope)
3. Copy the assessment as markdown
```

If the user chooses option 1:
- Generate skeleton test methods following the repo's existing patterns
- Use the naming convention from the golden path (`should [behavior] when [condition]`)
- Include AAA/GWT structure with TODOs for each section
- Group by priority (CRITICAL first)

## Verification

- **Phase 1 (Scope)**: Confirm source files were found. If zero files at the specified path, ask user to confirm before proceeding.
- **Phase 2 (Inventory)**: Confirm test files were read and classified. Present the inventory checkpoint to the user for validation before gap analysis.
- **Phase 4 (Gap Analysis)**: Cross-check that every source file in scope has an entry in the gap analysis — no files should be silently skipped.
- **Phase 6 (Generate)**: If generating test stubs, verify each file was written and contains the expected test method signatures.

## Worked Example

**Input:** `Assess tests for the invoice aggregate in einvoice-connector`

**Key steps:**
1. Scoped to `src/main/kotlin/.../invoice/` — found 6 source files, 4 test files
2. Detected Kotlin Axon project — loaded `kotlin-axon-cqrs.md` golden path + test personas
3. Inventoried 28 test methods: 22 unit (79%), 6 integration (21%), 0 E2E
4. Gap analysis: `InvoiceAggregate.kt` has Optimist and Saboteur coverage but no Boundary Walker tests for amount limits; `InvoiceSaga.kt` has no compensation tests (Saboteur gap)

**Output excerpt:**
```markdown
## Test Assessment: invoice aggregate (einvoice-connector)

### Test Pyramid
  Unit:        ████████░░ 22 (79%)  [vs target 70-80%] OK
  Integration: ██░░░░░░░░  6 (21%)  [vs target 15-20%] OK
  E2E:         ░░░░░░░░░░  0 (0%)   [vs target 5-10%] MISSING

### Priority Gaps
1. [CRITICAL] InvoiceSaga — no compensation test when payment fails (Saboteur)
2. [HIGH] InvoiceAggregate — no boundary test for zero/negative amounts (Boundary Walker)
3. [MEDIUM] No E2E test for invoice creation journey (User)
```

## Error Handling

### No Test Files Found

If no test files exist for the scope:
- Report this as a CRITICAL finding
- Analyse the source to produce a complete list of needed tests
- Offer to generate the full test file structure

### Source Files Not Found

If the specified path doesn't exist:
- Ask user to confirm the path
- Suggest similar paths found via file search

### Large Service Scope

If service scope exceeds 20 source files:
- Rank by complexity (method count, cyclomatic branching, dependency count)
- Assess the top 20 and note which files were excluded
- Suggest the user re-run at feature scope for excluded areas

### Standards Not Found

If a referenced rule file or golden path does not exist:
- Skip that rule set
- Note in the report which standards were unavailable

### No Engineering Codex

If the codex is not in the workspace:
- Use built-in test pyramid ratios (70/20/10)
- Use built-in anti-pattern checklist
- Skip test persona analysis
- Note in the report that codex enrichment was unavailable

## Related Resources

- [Code Review Skill](../code-review/SKILL.md) — includes testing as one review dimension
- [Fix Bug Skill](../fix-bug/SKILL.md) — test-first approach for fixing found issues
- [Implement Ticket Skill](../implement-ticket/SKILL.md) — TDD workflow for new features
- Engineering Codex: Testing (`@engineering-codex/facets/testing/`) — best practices, gotchas, test pyramid (when codex in workspace)
- [Golden Paths](../../../golden-paths/) — testing strategy per tech stack
