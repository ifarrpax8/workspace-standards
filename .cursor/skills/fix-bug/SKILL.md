---
name: fix-bug
description: Test-first bug fixing — prove defects with a failing test, then fix. For bugs, review findings, and defects.
---

# Fix Bug Skill

Test-first bug fixing workflow: prove the defect with a failing test, then fix it and verify the test passes.

## Prerequisites

### Required MCP Servers

| MCP Server | Tools Used | Purpose | Required? |
|------------|------------|---------|-----------|
| **user-mcp-atlassian** | `jira_get_issue` | Fetch bug ticket details | Optional |
| | `jira_add_comment` | Post fix summary to Jira | Optional |

### Graceful Degradation

- **No Jira MCP**: Accept bug description from user or code review output directly
- **No ticket**: Skill works standalone — the bug can come from a code review, a stack trace, or a verbal description

### Related Skills

This skill may be invoked from:
- **Code Review** — When fixing MUST FIX / Critical issues
- **Implement Ticket** — When a bug is discovered during feature work (Unknown Unknowns triage → SOLVE INLINE)

## When to Use

Use this skill when:
- Fixing a bug reported in a Jira ticket
- Addressing critical/must-fix items from a code review
- Resolving a defect found during implementation
- Any time a code change is intended to fix incorrect behaviour

## When NOT to Use

- **New feature work** — use [Implement Ticket](../implement-ticket/SKILL.md)
- **Broad code quality issues** found during review — use [Code Review](../code-review/SKILL.md) to categorize first, then fix-bug for each MUST FIX item
- **Refactoring without a defect** — this skill requires a provable bug; refactoring is not a bug fix
- **Simple typo or config fix** that doesn't need test-first proof — just fix it directly

## Invocation

```
Fix bug HRZN-456
```

```
Fix the NPE in validateCursorGroupBy
```

```
Fix the MUST FIX issues from the code review
```

## Workflow

### Phase 1: Understand the Defect

Establish a clear understanding of what's broken before touching any code.

**From a Jira ticket:**
```
Use jira_get_issue with:
- issue_key: [ticket key]
- fields: "*all"
- expand: "renderedFields"
```

**From a code review finding:**
Extract from the review output:
- File and line number
- Description of the issue
- Suggested fix (if provided)

**From a description or stack trace:**
Ask the user for:
- Steps to reproduce (if applicable)
- Expected vs actual behaviour
- Stack trace or error message

Produce a concise defect statement:

```
DEFECT: [One-sentence description]
LOCATION: [File(s) and method(s) involved]
ROOT CAUSE: [Why it happens — null reference, missing branch, wrong type, etc.]
IMPACT: [What goes wrong for the user or caller]
MISSING PERSONA: [Which test persona would have caught this — see below]
```

If `@engineering-codex/facets/testing/test-personas.md` is available, identify which test persona's test was missing:
- Null/missing data → **Boundary Walker** test was missing
- Dependency failure / timeout → **Saboteur** test was missing
- Auth bypass / tenant leakage → **Auditor** test was missing
- Unusual input combination → **Explorer** test was missing
- Wrong result for valid input → **Optimist** test was incorrect or missing

This helps the team see patterns in which persona's scenarios are consistently undertested.

Present the defect statement and confirm understanding before proceeding.

### Phase 2: Write a Failing Test (Red)

Write a test that **proves the defect exists** by exercising the exact code path that fails.

**Guidelines:**
- The test should fail for the same reason the bug manifests (not a different error)
- Name the test descriptively — it should read as a specification of the correct behaviour
- Place the test alongside existing tests for the same class/module
- Follow existing test patterns and naming conventions in the codebase

**Test naming examples:**
- `facetWithCursorMissingGroupBy_throwsNullPointerException` (proving the bug)
- `facetWithCursorMissingGroupBy_skipsInvalidFacetGracefully` (specifying the fix)

**Strategy for proving the defect:**

If the defect is a crash (NPE, ClassCastException, etc.):
```
try {
    exerciseDefectivePath()
    assert false : "Expected [ExceptionType]"
} catch ([ExceptionType] ignored) {
    // Proves the defect exists
}
```

If the defect is wrong behaviour (incorrect return value, missing filter, etc.):
```
result = exerciseDefectivePath()
// Assert the INCORRECT behaviour to prove the bug exists
assertEquals(wrongValue, result)
```

### Phase 3: Run the Test — Verify It Fails

Run the test and confirm it fails for the expected reason.

```bash
# Run only the new test
./gradlew :module:test --tests "com.example.ClassTest$NestedClass.testName"
```

or for frontend:
```bash
npx vitest run path/to/test.ts -t "test name"
```

**Critical checkpoint:**
- If the test **passes** — the defect may not be reproducible in this path, or the test doesn't exercise the right code path. Investigate before proceeding.
- If the test **fails for a different reason** — adjust the test to target the actual defect.
- If the test **fails for the expected reason** — proceed to Phase 4.

### Phase 4: Implement the Fix

Apply the minimal change that corrects the behaviour.

**Principles:**
- Fix the root cause, not the symptom
- Prefer the smallest change that resolves the defect
- Follow existing codebase patterns (search for how similar issues are handled elsewhere)
- Check for the same defect pattern in related code (e.g., if a null check was missing in one method, check sibling methods)

### Phase 4b: Rewrite the Test to Prove the Fix

After applying the fix, the "prove the bug" test from Phase 2 **should now fail** — because the defect no longer exists. This is expected and confirms the fix changed the behaviour.

Now rewrite the test to assert the **correct** behaviour:

- Replace the "expect the bug" assertion with one that verifies the fix
- Rename the test to describe the expected behaviour, not the bug
- The rewritten test becomes a permanent regression guard

**Example transition:**

Before fix (Phase 2 — proves the bug):
```
// Test: facetWithCursorMissingGroupBy_throwsNullPointerException
try {
    exerciseDefectivePath()
    assert false : "Expected NullPointerException"
} catch (NullPointerException ignored) {}
```

After fix (Phase 4b — proves the fix):
```
// Test: facetWithCursorMissingGroupBy_skipsInvalidFacetGracefully
result = exerciseDefectivePath()
assertNotNull(result)
```

The original test name documents the bug that was found. The new test name documents the correct behaviour going forward.

### Phase 5: Verify the Fix (Green)

Run the rewritten test and confirm it passes.

```bash
./gradlew :module:test --tests "com.example.ClassTest$NestedClass.testName"
```

**Critical checkpoint:**
- If the test **passes** — proceed to Phase 6
- If the test **fails** — the fix is incomplete; return to Phase 4

### Phase 6: Check for Regressions

Run the broader test suite to ensure the fix hasn't broken anything.

```bash
# Run all tests in the module
./gradlew :module:test

# Or for the full build with static analysis
./gradlew check
```

For frontend:
```bash
npx vitest run
```

**If regressions are found:**
- Analyse whether the regression is caused by the fix or was pre-existing
- If caused by the fix, adjust the approach and return to Phase 4
- If pre-existing, note it and proceed

### Phase 7: Summary

**If from a Jira ticket**, post a comment:

```markdown
## Bug Fix Summary

**Defect:** [One-sentence description]
**Root Cause:** [Why it happened]
**Fix:** [What was changed]

### Test Evidence
- **Failing test (before fix):** [Test name] — confirmed the defect by [description]
- **Passing test (after fix):** [Test name] — verifies [correct behaviour]
- **Regression check:** [N] tests passing, 0 failures

### Files Changed
- `path/to/file` — [What changed and why]
```

**If from a code review**, update the review thread or inform the reviewer.

## Verification

After each critical phase, verify the operation succeeded:

- **Phase 3 (Red)**: Run the test and confirm it **fails** for the expected reason. If it passes or fails for a different reason, do not proceed — investigate first.
- **Phase 5 (Green)**: Run the rewritten test and confirm it **passes**. If it still fails, the fix is incomplete — return to Phase 4.
- **Phase 6 (Regressions)**: Run the full test suite and confirm no new failures. Parse the output for failure count — do not assume success without checking.
- **Phase 7 (Jira)**: If posting via `jira_add_comment`, verify the response indicates success. If it fails, present the summary as markdown for manual copy.

## Worked Example

**Input:** `Fix the NPE in validateCursorGroupBy`

**Key steps:**
1. Located defect in `ScheduledOrderCustomSearchRepositoryImpl.java:187` — `groupBy` field is null when cursor-based pagination is used without aggregation
2. Identified missing persona: **Boundary Walker** (null input not tested)
3. Wrote failing test: `facetWithCursorMissingGroupBy_throwsNullPointerException` — confirmed NPE on line 187
4. Applied fix: added null check with early return, skipping facet when `groupBy` is absent
5. Rewrote test: `facetWithCursorMissingGroupBy_skipsInvalidFacetGracefully` — verified fix returns empty facet list
6. Ran full suite: 324 tests passing, 0 failures

**Output excerpt:**
```markdown
## Bug Fix Summary

**Defect:** NullPointerException when cursor pagination used without groupBy field
**Root Cause:** `groupBy` assumed non-null in `buildFacetQuery()` but cursor requests omit it
**Fix:** Added null guard in `validateCursorGroupBy()` — returns empty facet list instead of crashing

### Test Evidence
- **Failing test (before fix):** `facetWithCursorMissingGroupBy_throwsNullPointerException` — confirmed NPE
- **Passing test (after fix):** `facetWithCursorMissingGroupBy_skipsInvalidFacetGracefully` — returns empty list
- **Regression check:** 324 tests passing, 0 failures
```

## Multiple Bugs

When fixing multiple bugs (e.g., several MUST FIX items from a review):

1. Work through each bug individually, completing Phases 1-5 for each
2. Run the full regression suite once at the end (Phase 6)
3. Produce a combined summary

## Error Handling

### Cannot Reproduce the Defect

If the test in Phase 2 passes unexpectedly:
- Verify the test exercises the correct code path
- Check if the defect is environment-specific
- Ask the user for additional reproduction context
- If the defect truly cannot be reproduced, document this finding

### Fix Introduces New Complexity

If the fix requires significant new code:
- Consider whether this is actually a feature gap, not a bug
- If the fix exceeds the scope of a bug fix, flag it as a potential follow-up ticket
- Reference the implement-ticket skill for larger changes

## Related Resources

- [Code Review Skill](../code-review/SKILL.md) — Often surfaces bugs that need this workflow
- [Implement Ticket Skill](../implement-ticket/SKILL.md) — For feature work that discovers bugs inline
- [Assess Tests Skill](../assess-tests/SKILL.md) — Systematic test completeness audit to prevent future bugs
- [Code Review Rule](../../../rules/code-review.md) — Review checklist
