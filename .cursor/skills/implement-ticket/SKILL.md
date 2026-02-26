---
name: implement-ticket
description: Structured implementation of refined Jira tickets with TDD, unknown-unknowns triage, and QA handoff.
complexity: low
prompt-version: "1.0"
---
# Implement Ticket Skill

Structured implementation workflow for refined Jira tickets with Definition of Ready validation, pragmatic TDD, unknown-unknowns triage, self-review, and QA handoff.

## Prerequisites

### Required MCP Servers

| MCP Server | Tools Used | Purpose | Required? |
|------------|------------|---------|-----------|
| **user-mcp-atlassian** | `jira_get_issue` | Fetch ticket details and refinement notes | Recommended |
| | `jira_add_comment` | Post implementation summary to Jira | Recommended |
| **user-github** | `search_code` | Search patterns across Pax8 org (via Deep Dive) | Optional |

> **Important:** See [Jira Standards](../../rules/jira-standards.md) for custom field usage. Stories use `customfield_12636`, not the standard description field.

### Graceful Degradation

If MCPs are not available, the skill will:
1. **Prompt to enable**: "The Atlassian MCP (`user-mcp-atlassian`) is not enabled. Would you like to enable it, or provide ticket details manually?"
2. **Offer manual input**: Accept pasted Jira ticket content
3. **Skip Jira posting**: Generate the implementation summary as markdown for manual copy/paste

### Related Skills

This skill may invoke:
- **Technical Deep Dive** - When unknowns require codebase investigation
- **Refine Ticket** - When Definition of Ready fails and the developer chooses to refine first

### Engineering Codex Integration

If `@engineering-codex` is in the workspace, this skill will:
- Reference `best-practices.md` for the relevant facets during implementation (e.g., `@engineering-codex/facets/api-design/best-practices.md` when implementing an API endpoint)
- Check `gotchas.md` to avoid known pitfalls before starting each task
- Use the codex `architecture-review` guidance during the self-review phase (Phase 5) in addition to the code-review.md checklist
- Check Pax8 standards for any technology choices made during implementation

If the codex is not available, the skill uses golden paths and code-review.md as before.

## When to Use

Use this skill when:
- A ticket has been refined and is ready for implementation
- You want structured guidance through the development process
- You want unknowns tracked and scope monitored during implementation
- You want a clean QA handoff with test evidence and tester guidance

## When NOT to Use

- **Ticket hasn't been refined** — use [Refine Ticket](../refine-ticket/SKILL.md) first to establish an implementation plan
- **Fixing a bug or defect** — use [Fix Bug](../fix-bug/SKILL.md) for test-first defect resolution
- **Time-boxed research** — use [Spike](../spike/SKILL.md) or [Technical Deep Dive](../technical-deep-dive/SKILL.md) for investigation
- **Simple config or copy change** that doesn't need TDD, scope tracking, or QA handoff

## Invocation

```
Implement ticket HRZN-123
```

Or with repository context:
```
Implement ticket HRZN-123 in the currency-manager repository
```

## Workflow

### Phase 1: Fetch and Validate Definition of Ready

1. Extract the Jira ticket key from user input
2. Fetch ticket details:

```
Use jira_get_issue with:
- issue_key: [ticket key]
- fields: "*all"
- expand: "renderedFields"
```

3. Extract the refinement notes from `customfield_12636`
4. Validate the Definition of Ready checklist:

- [ ] Acceptance criteria are present, specific, and testable
- [ ] Technical approach is documented (from refinement notes)
- [ ] Test scenarios are documented (happy path + edge cases)
- [ ] Confidence score >= 7/12 (Medium or High)
- [ ] Affected codebases are identified

5. **If DoR passes**: Present a summary of the ticket and proceed to Phase 2

6. **If DoR fails**: Show exactly which criteria are missing and present options using AskQuestion:

```
Definition of Ready check FAILED for [HRZN-XXX].

Missing criteria:
- [List of specific gaps]

How would you like to proceed?
1. Abandon and refine first (recommended) - I'll invoke the refine-ticket skill
2. Proceed with documented risk - Missing criteria will be logged as known risks
```

If the developer chooses to abandon, guide them to invoke:
```
@workspace-standards/.cursor/skills/refine-ticket/SKILL.md refine ticket [HRZN-XXX]
```
Then stop. This is a genuine exit point, not a speed bump.

If the developer chooses to proceed, document the missing DoR items as known risks to include in the final Jira update.

### Phase 2: Setup

1. **Identify target repositories** from the refinement notes or ask the developer to confirm

2. **Load codebase standards** based on the repository type. Read the relevant rules to inform implementation:

| Repository Type | Standards to Load | Golden Path |
|----------------|-------------------|-------------|
| Kotlin (e.g., currency-manager, report-manager) | [kotlin-standards.md](../../rules/kotlin-standards.md) | [kotlin-spring-boot.md](../../../golden-paths/kotlin-spring-boot.md) |
| Kotlin Axon (e.g., einvoice-connector) | [kotlin-standards.md](../../rules/kotlin-standards.md) | [kotlin-axon-cqrs.md](../../../golden-paths/kotlin-axon-cqrs.md) |
| Vue MFE (e.g., finance-mfe, order-management-mfe) | [vue-standards.md](../../rules/vue-standards.md) | [vue-mfe.md](../../../golden-paths/vue-mfe.md) |
| All repositories | [security-standards.md](../../rules/security-standards.md), [pre-review-checklist.md](../../rules/pre-review-checklist.md) | - |

3. **Load codex context** (if `@engineering-codex` is in the workspace):
   - Identify relevant facets based on the ticket's domain (e.g., api-design for new endpoints, authentication for auth changes)
   - Read `best-practices.md` for stack-specific guidance
   - Read `gotchas.md` to be aware of common pitfalls before starting
   - If this is a Pax8 project, check `pax8-context/standards-map.md` for mandated standards

4. **Create the feature branch** from main:

```bash
git checkout main && git pull && git checkout -b [TICKET-KEY]
```

Branch naming: ticket key only (e.g., `HRZN-705`). No suffix or description appended.

### Phase 3: Plan and TDD Assessment

1. **Extract the implementation plan** from the refinement notes and break it into a task list using the TodoWrite tool

2. **Extract test scenarios** from the refinement notes (these were documented during refinement)

   If test scenarios are sparse or only cover happy paths, enrich them using test personas from `@engineering-codex/facets/testing/test-personas.md` (if available):
   - Ensure at least Optimist (happy) and Saboteur (error) scenarios exist for each task
   - Add Boundary Walker scenarios for any task involving numeric, string, or collection input
   - Add Auditor scenarios for any task touching authentication or authorization

3. **Assess TDD feasibility** for each task. Present a recommendation per task:

| Task | TDD Suitable? | Rationale |
|------|--------------|-----------|
| [Task from plan] | Yes / No | [Why] |

**TDD-suitable examples**: New API endpoint, service logic, domain validation, data transformation, utility functions

**Not TDD-suitable examples**: UI layout, configuration changes, wiring/dependency injection, infrastructure setup

4. **Present the plan to the developer** for confirmation before starting:

```
Implementation Plan for [HRZN-XXX]:

1. [Task 1] - TDD: Yes
2. [Task 2] - TDD: No (config change)
3. [Task 3] - TDD: Yes
...

Proceed with this plan?
```

The developer confirms or adjusts before implementation begins.

### Phase 4: Implementation Loop

Execute each task from the plan sequentially. For each task:

#### TDD-Suitable Tasks (Red-Green-Refactor)

Follow single-cycle TDD discipline — one test at a time, not all tests up front:

1. **Red**: Write a single failing test based on an acceptance criterion or test scenario
2. **Green**: Write the minimum implementation to make the test pass
3. **Refactor**: Clean up while keeping tests green
4. **Commit** (recommended): `test(HRZN-XXX): add test for [behavior]` then `feat(HRZN-XXX): implement [behavior]`
5. Repeat for the next test scenario

#### Non-TDD Tasks

1. Implement the change
2. Write tests alongside or immediately after
3. Commit (recommended)

#### Commit Guidance

**Incremental commits** are recommended but optional per task. The skill suggests committing after each logical task, but the developer can batch if preferred.

Commit message format — semantic type with ticket key as scope:
```
<type>(HRZN-XXX): <description>
```

Valid types:
- `feat` - New feature
- `fix` - Bug fix
- `refactor` - Code restructuring without behavior change
- `test` - Adding or updating tests
- `docs` - Documentation changes
- `chore` - Maintenance tasks
- `style` - Code formatting
- `build` - Build system changes
- `perf` - Performance improvements
- `ci` - CI/CD changes
- `revert` - Reverting previous changes
- `deps` - Dependency updates

The skill suggests the appropriate type based on what was just implemented.

#### Unknown Unknowns Triage

When something unexpected is discovered during implementation, pause and present:

```
UNKNOWN DETECTED: [Description of what was discovered]

Impact Assessment:
- Scope: [Does this change the approach?]
- Effort: [How much additional work?]
- Risk: [What could go wrong?]

Recommendation: [One of the below]
1. SOLVE INLINE - Small, contained, won't derail the ticket
2. FOLLOW-UP TICKET - Tangential, can be done separately
3. ESCALATE - Blocking, needs team input or architecture decision

Proceed with recommendation?
```

Present the recommendation using AskQuestion and let the developer confirm or override.

Track all unknowns and their resolutions for the final Jira update.

If the unknown requires codebase investigation, invoke the Technical Deep Dive skill:
```
@workspace-standards/.cursor/skills/technical-deep-dive/SKILL.md investigate [topic] in [repository]
```

#### Cumulative Scope Monitoring

After each unknown is triaged, assess the aggregate impact against the original Fibonacci estimate. If cumulative effort has materially changed the scope, flag it:

```
SCOPE CHECK: [N] unknowns resolved so far, cumulative additional effort is significant.
Original estimate: [X] points | Current trajectory: ~[Y] points

Options:
1. CONTINUE - Accept the larger scope, document in Jira
2. SPLIT - Carve remaining work into a follow-up ticket
3. RE-ESTIMATE - Pause and update the estimate with the team
```

### Phase 5: Self-Review

Before the final commit, run a self-review using the [code-review.md](../../rules/code-review.md) checklist and the [pre-review-checklist.md](../../rules/pre-review-checklist.md) against the diff.

Read the code-review.md rule and apply it to all changed files:

**Architecture Alignment:**
- Does the code follow the golden path for its project type?
- Controllers handle only HTTP concerns (Kotlin), `<script setup>` used (Vue)

**Code Quality:**
- No linter warnings introduced
- Functions are focused (single responsibility)
- Naming is clear and consistent

**Testing:**
- New code has corresponding tests
- Tests follow naming convention (`should...when...`)
- Scenario coverage includes at minimum: happy path (Optimist) and error path (Saboteur)
- Boundary conditions tested for methods with numeric/string/collection input (Boundary Walker)
- If `@engineering-codex/facets/testing/test-personas.md` is available, cross-check against the per-method persona checklist

**Security:**
- No hardcoded secrets or credentials
- Input validation present
- Proper error handling (no stack traces exposed)

**Quick Checks by File Type:**

| File Type | Checks |
|-----------|--------|
| `*.kt` | No `@Autowired` (use constructor injection), no `!!` without justification, data classes for DTOs |
| `*.vue` | `<script setup>` used, typed `defineProps<{}>()` and `defineEmits<{}>()`, no `v-html` without sanitization, i18n for user-facing text |
| `*.ts` | No `any` types, no `@ts-ignore`, interfaces for complex objects, async/await pattern |
| `*Test.kt` / `*.test.ts` | Descriptive test names, Arrange-Act-Assert pattern, minimal mocks |

Fix any issues found before committing. Re-run the review after fixes.

### Phase 6: Definition of Done

Before posting to Jira, validate the DoD checklist:

- [ ] All acceptance criteria from the ticket have been addressed
- [ ] Tests passing (run the test suite)
- [ ] No linter errors introduced
- [ ] Self-review completed (Phase 5)
- [ ] All unknowns documented (resolved or follow-up created)
- [ ] Commit messages follow semantic format
- [ ] No unfinished tasks in the implementation plan

If any items fail, flag them and ask the developer how to proceed using AskQuestion:

```
Definition of Done check for [HRZN-XXX]:

Passed:
- [x] Acceptance criteria addressed
- [x] Tests passing
...

Failed:
- [ ] [Item that failed] - [Details]

How would you like to proceed?
1. Fix the gaps now
2. Document as incomplete and proceed to Jira update
```

### Phase 7: Jira Update

Generate the implementation summary using the format below, then **display it to the user and ask for confirmation before posting**:

```
Here is the implementation summary I'll post to [ticket key]. Please review:

[formatted implementation summary]

Shall I post this to Jira? (yes / edit first / skip)
```

Only proceed to post after the user confirms:

```
Use jira_add_comment with:
- issue_key: [ticket key]
- comment: [formatted implementation summary - see format below]
```

## Test Evidence Guide

Before writing the Jira comment, identify what evidence exists for this ticket. Use the table below to select the right evidence type — describe what was observed, not what was expected.

| Change type | Meaningful evidence |
|---|---|
| API endpoint (new or changed) | A/B test script output, or curl request + actual response showing correct behaviour |
| Backend logic / service | Test runner output with new tests passing, log snippet from a manual run |
| Data migration / query | Before/after record counts or sample query output |
| UI / frontend | Screenshot of happy path and an error/edge state, or short screen recording |
| Config / infrastructure | Deployment log snippet, health check or smoke test output |

Attach files (screenshots, script output) to the Jira ticket directly. In the comment, reference what was attached and what it shows — don't paste raw output inline.

## Implementation Summary Format

Post this format as a Jira comment:

```
[HRZN-XXX] [Title] | [branch] | DoD: Passed / Partial

Built:
  [repo]: [what was implemented]
  Key files: file1.kt, file2.kt

Deviations: none
  / [unknown encountered → resolution: solved inline / follow-up HRZN-XXX / escalated (impact)]
  / Scope: [X]pts estimated → [Y]pts actual — [reason if changed]

Tests: [N] unit · [N] integration · [N] E2E
Coverage: [key areas and notable edge cases]

Tested:
- [what was verified — include evidence type: "A/B script output attached",
  "screenshot of happy path attached", "curl response showing 400 — see attached"]

Could NOT test:
- [scenario] — [reason: needs production data / specific partner config / etc.]

For tester:
- Setup: [env, test data, feature flags]
- Focus: [highest-risk areas and any scenarios the developer could not fully verify]

Remaining: none / [HRZN-XXX follow-up ticket]
```

## Verification

After each critical operation, verify success:

- **Phase 1 (Fetch)**: Confirm `jira_get_issue` returned ticket data. If it errors, switch to manual input before proceeding.
- **Phase 2 (Branch)**: Run `git rev-parse --abbrev-ref HEAD` and confirm the branch name matches the ticket key.
- **Phase 4 (Tests)**: After each red-green cycle, confirm the test runner exit code. Parse output for pass/fail count — do not assume success.
- **Phase 5 (Self-Review)**: Run linter (`./gradlew check` or `npx eslint .`) and confirm zero new warnings before proceeding to DoD.
- **Phase 7 (Jira)**: If posting via `jira_add_comment`, verify the response indicates success. If it fails, present the summary as markdown.

## Worked Example

**Input:** `Implement ticket HRZN-705 in the currency-manager repository`

**Key steps:**
1. Fetched HRZN-705 — "Add historical exchange rate lookup endpoint"
2. DoR passed (10/12 confidence). Loaded `kotlin-standards.md` + `kotlin-spring-boot.md` golden path
3. Planned 4 tasks: endpoint, service, repository query, tests. TDD suitable for all.
4. Red-green cycle for each: wrote `should return rate for date when rate exists`, implemented `GET /rates/{currency}/{date}`, passed
5. Unknown detected: existing `RateCache` doesn't support date-keyed lookups → triaged as SOLVE INLINE (small, added date parameter to cache key)
6. Self-review: clean. 12 new tests, all passing. No linter warnings.
7. Posted implementation summary to HRZN-705

**Output excerpt:**
```
HRZN-705 Add historical exchange rate lookup endpoint | HRZN-705 | DoD: Passed

Built:
  currency-manager: new GET /api/v1/rates/{currency}/{date} endpoint with cache-aware date lookup
  Key files: HistoricalRateEndpoint.kt, HistoricalRateService.kt, RateRepository.kt

Deviations: RateCache didn't support date-keyed lookups → solved inline (added date param to cache key)

Tests: 8 unit · 4 integration
Coverage: rate lookup for valid date, missing rate returns 404, boundary dates

Tested:
- GET /api/v1/rates/USD/2025-01-15 against local — correct rate returned (curl output attached)

Could NOT test:
- Rates before service launch date — no historical data in dev environment

For tester:
- Setup: preproduction, any partner with USD invoices
- Focus: boundary dates (pre-launch, future), missing currency codes

Remaining: none
```

## Error Handling

### MCP Not Available

Present options using AskQuestion:
```
The Atlassian MCP (user-mcp-atlassian) isn't enabled.

How would you like to proceed?
1. Enable the MCP - I'll wait while you enable it
2. Provide ticket details manually - Paste the ticket content
3. Skip Jira integration - I'll generate the summary as markdown
```

### Jira Fetch Fails

If `jira_get_issue` returns an error:
- Display the error message
- Ask user to paste ticket details manually
- Continue with the workflow using provided content

### Jira Comment Post Fails

If `jira_add_comment` returns an error:
- Display the error message
- Present the implementation summary as formatted markdown
- Instruct: "Copy the above and paste it as a comment on [ticket-key]"

### Tests Fail During Implementation

If tests fail during the red-green-refactor cycle:
- Present the failure output
- Analyse the root cause
- Fix and re-run before proceeding to the next task

### Branch Already Exists

If the branch already exists when attempting to create it:
- Check out the existing branch
- Confirm with the developer: "Branch [TICKET-KEY] already exists. Continue working on it?"

## Related Resources

- [Refine Ticket Skill](../refine-ticket/SKILL.md) - Three Amigos refinement (run before this skill)
- [Technical Deep Dive Skill](../technical-deep-dive/SKILL.md) - Codebase investigation for unknowns
- [Spike Skill](../spike/SKILL.md) - Time-boxed research for larger unknowns
- [Assess Tests Skill](../assess-tests/SKILL.md) - Test completeness audit (use after implementation for verification)
- [Code Review Rule](../../rules/code-review.md) - Self-review checklist used in Phase 5
- [Pre-Review Checklist](../../rules/pre-review-checklist.md) - Cross-cutting quality checks used in Phase 5
- [Refinement Best Practices](../../rules/refinement-best-practices.md) - DoR checklist reference
- [Jira Standards](../../rules/jira-standards.md) - Custom field usage
- [Golden Paths](../../../golden-paths/) - Architecture patterns
