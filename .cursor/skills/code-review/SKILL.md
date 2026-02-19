---
name: code-review
description: Review PRs or local changes against team standards, golden paths, and Engineering Codex best practices.
---
# Code Review Skill

Interactive code review of PRs or local changes against team standards, golden paths, and optionally the Engineering Codex.

## Prerequisites

### Required MCP Servers

| MCP Server | Tools Used | Purpose | Required? |
|------------|------------|---------|-----------|
| **user-github** | `get_pull_request` | Fetch PR details | Optional |
| | `get_pull_request_files` | Fetch changed file list | Optional |
| | `get_file_contents` | Fetch file contents for review | Optional |
| **user-mcp-atlassian** | `jira_get_issue` | Fetch linked ticket context | Optional |

### Graceful Degradation

- **No GitHub MCP**: User provides files or diff manually; review is generated as markdown
- **No Engineering Codex**: Skip codex checks; use only golden paths and rules

## When to Use

Use this skill when:
- Reviewing a pull request before merge
- Performing self-review before pushing
- Validating local changes against team standards
- Checking alignment with golden paths and best practices

## When NOT to Use

- **Broad architecture audit** across the whole codebase — use [Architecture Review](../architecture-review/SKILL.md) or [Score](../score/SKILL.md)
- **Post-merge retrospective** on a completed feature — use [Post-Implementation Review](../post-implementation-review/SKILL.md)
- **Simple one-file check** that doesn't need structured analysis — just read the file directly
- **Test completeness audit** — use [Assess Tests](../assess-tests/SKILL.md) for persona-level testing analysis

## Invocation

```
Review PR 42 in currency-manager
```

```
Review my changes on branch HRZN-123
```

```
Review the files I've changed
```

## Workflow

### Phase 1: Identify Changes

1. **If given a PR number**: Fetch PR details and file list via GitHub MCP
   ```
   Use get_pull_request with owner, repo, pull_number
   Use get_pull_request_files with owner, repo, pull_number
   ```

2. **If given a branch or local changes**: Use `git diff` to identify changed files
   ```
   git diff main --name-only
   git diff main -- <path>
   ```

3. **If no GitHub MCP**: Ask user to describe what changed or paste a diff

### Phase 2: Load Standards

Load the relevant rules based on file types present:

| File Type | Rules to Load |
|-----------|---------------|
| `*.kt` | [kotlin-standards.md](../../rules/kotlin-standards.md) |
| `*.groovy`, `*.java` | [groovy-standards.md](../../rules/groovy-standards.md) |
| `*.vue`, `*.ts` | [vue-standards.md](../../rules/vue-standards.md) |
| `*.tf` | [terraform-standards.md](../../rules/terraform-standards.md) |
| All | [security-standards.md](../../rules/security-standards.md) |

**Detect project type** from build files and dependencies (do this once before loading golden paths):

| Signal | Project Type |
|--------|-------------|
| `build.gradle` (Groovy DSL) or `*.groovy` files in `service/` | **Groovy Monolith** |
| `build.gradle.kts` with `axon` dependency | **Kotlin Axon** |
| `build.gradle.kts` without `axon` dependency | **Kotlin Spring Boot** |
| `package.json` with `vue` dependency | **Vue MFE** |
| `*.tf` files or `terraform/` directory | **Terraform** |

When ambiguous (e.g., mixed file types in a monorepo), use the file types in the diff to narrow scope. If still unclear, ask the user.

Load the relevant golden path based on detected project type:

| Project Type | Golden Path |
|--------------|-------------|
| Groovy Monolith | [groovy-monolith.md](../../../golden-paths/groovy-monolith.md) |
| Kotlin Spring Boot | [kotlin-spring-boot.md](../../../golden-paths/kotlin-spring-boot.md) |
| Kotlin Axon | [kotlin-axon-cqrs.md](../../../golden-paths/kotlin-axon-cqrs.md) |
| Vue MFE | [vue-mfe.md](../../../golden-paths/vue-mfe.md) |
| Terraform | [terraform-iac.md](../../../golden-paths/terraform-iac.md) |

If `@engineering-codex` is in the workspace:
- Read relevant facet's `best-practices.md` and `gotchas.md` based on changed code

Read [code-review.md](../../rules/code-review.md) for the base checklist.

### Phase 3: Review Each File

For each changed file, apply the review checklist from `rules/code-review.md`:

**Architecture Alignment:**
- Does the code follow the golden path for its project type?
- Proper layer separation (controllers handle HTTP only, services handle logic)

**Code Quality:**
- No linter warnings introduced
- Functions focused (single responsibility)
- Naming clear and consistent

**Testing:**
- New code has corresponding tests
- Tests follow naming convention (`should...when...`)
- Scenario coverage: at minimum happy path and error path exist
- If `@engineering-codex/facets/testing/test-personas.md` is available, check for Boundary Walker and Saboteur coverage on critical methods
- For deeper test assessment, suggest the [Assess Tests Skill](../assess-tests/SKILL.md)

**Security:**
- No hardcoded secrets
- Input validation present
- Proper error handling

**Quick checks by file type:**

| File Type | Checks |
|-----------|--------|
| `*.kt` | No `@Autowired`, no `!!` without justification, data classes for DTOs |
| `*.groovy` | No `def` when type is known, no parameter reassignment, `@CompileStatic` on perf-critical paths |
| `*.java` (monolith) | No new PMD violations, no `@SuppressWarnings` without justification |
| `*.vue` | `<script setup>`, typed props/emits, no `v-html` without sanitization, i18n |
| `*.ts` | No `any` types, no `@ts-ignore`, interfaces for complex objects |
| `*Test.groovy` / `*Spec.groovy` | Spock `given/when/then`, descriptive string names, mocked DAOs and services |
| `*Test.kt` / `*.test.ts` | Descriptive names, AAA pattern, minimal mocks |

### Phase 4: Produce Review Summary

Output a structured review:

```markdown
## Code Review: [PR title or branch name]

**Files reviewed:** [N]
**Standards applied:** [list of rules/golden paths used]
**Overall assessment:** Approve / Approve with suggestions / Request changes

---

### Issues Found

#### [MUST FIX] (blocks approval)
| File | Line | Issue | Suggestion |
|------|------|-------|------------|
| ... | ... | ... | ... |

#### [SUGGESTION] (non-blocking)
| File | Line | Issue | Suggestion |
|------|------|-------|------------|
| ... | ... | ... | ... |

### Strengths
- [What's done well]

### Summary
[1-2 sentence overall assessment]
```

### Phase 5: Offer Actions

After presenting the review, ask:

```
What would you like to do?
1. Fix the MUST FIX issues now (uses the fix-bug skill for test-first fixes)
2. Post this review as a PR comment (requires confirmation)
3. Copy the review as markdown
```

If the developer chooses option 1, invoke the [Fix Bug Skill](../fix-bug/SKILL.md) for each critical issue. The fix-bug skill ensures each defect is proven with a failing test before being fixed.

If the developer chooses option 2, **ask for explicit confirmation before calling the GitHub MCP API**:

```
I'll post this review as a comment on PR #[number]. Shall I proceed? (yes / edit first / skip)
```

Only after the user confirms, post using the GitHub MCP.

## Verification

After each phase, verify the operation succeeded:

- **Phase 1**: Confirm at least one changed file was identified. If zero files found, check branch name or ask the user before proceeding.
- **Phase 2**: Confirm the standards files and golden path loaded without errors. Note any missing files in the output under "Standards applied."
- **Phase 4**: If posting as a PR comment via GitHub MCP, verify the comment was created by checking the response. If it fails, fall back to markdown output.

## Worked Example

**Input:** `Review PR 42 in currency-manager`

**Key steps:**
1. Fetched PR #42 via GitHub MCP — 4 files changed in `src/service/` and `src/endpoint/`
2. Detected Kotlin Axon project (`build.gradle.kts` contains `axon`) — loaded `kotlin-standards.md` + `kotlin-axon-cqrs.md` golden path
3. Reviewed each file against architecture alignment, code quality, testing, and security checklists
4. Found: `@EventSourcingHandler` calling external HTTP service (MUST FIX — side effect in event handler)
5. Found: missing test for error path when exchange rate API returns 429 (SUGGESTION)

**Output excerpt:**
```markdown
## Code Review: PR #42 — Add multi-currency ledger support

**Files reviewed:** 4
**Standards applied:** kotlin-standards, kotlin-axon-cqrs golden path, security-standards
**Overall assessment:** Request changes

### Issues Found

#### [MUST FIX]
| File | Line | Issue | Suggestion |
|------|------|-------|------------|
| ExchangeRateHandler.kt | 34 | @EventSourcingHandler calls HTTP service | Move to saga or event processor — handlers must be side-effect free |

#### [SUGGESTION]
| File | Line | Issue | Suggestion |
|------|------|-------|------------|
| ExchangeRateServiceTest.kt | — | No test for 429/rate-limit scenario | Add Saboteur test for API throttling |
```

## Error Handling

### GitHub MCP Not Available

Ask user to provide:
- List of changed files
- Diff content (paste or describe)
- Or point to a branch for `git diff`

Proceed with review using provided content. Output as markdown only.

### Jira MCP Not Available

Skip linked ticket context. Review proceeds without ticket details.

### No Changed Files Found

If `git diff` or PR returns no files:
- Confirm the branch or PR is correct
- Ask user to specify files to review

### Standards File Not Found

If a referenced rule file (e.g., `terraform-standards.md`) does not exist:
- Skip that rule set
- Note in "Standards applied" which rules were unavailable

## Related Resources

- [Code Review Rule](../../rules/code-review.md)
- [Implement Ticket Skill](../implement-ticket/SKILL.md) — uses this checklist in Phase 5
- [Fix Bug Skill](../fix-bug/SKILL.md) — test-first bug fixing for critical issues found during review
- [Golden Paths](../../../golden-paths/)
