---
name: post-implementation-review
description: Post-merge retrospective — validate estimates, capture learnings, and feed insights into future work.
---

# Post-Implementation Review Skill

Closing-the-loop skill that runs after a feature has been implemented and merged. Captures learnings, validates estimates, and updates team knowledge.

## Prerequisites

### Required MCP Servers

| MCP Server | Tools Used | Purpose | Required? |
|------------|------------|---------|-----------|
| **user-mcp-atlassian** | `jira_get_issue` | Fetch ticket history and refinement notes | Optional |
| | `jira_add_comment` | Post review to ticket | Optional |
| **user-github** | `get_pull_request` | Fetch PR details | Optional |
| | `get_pull_request_files` | Fetch changed file list | Optional |
| | `get_pull_request_reviews` | Fetch review comments | Optional |

> **Important:** See [Jira Standards](../../rules/jira-standards.md) for custom field usage. Refinement notes live in `customfield_12636`.

### Graceful Degradation

- **No Jira MCP**: Accept pasted ticket details; generate markdown review
- **No GitHub MCP**: Skip PR stats; focus on estimate accuracy and learnings
- **No MCPs**: Fully manual input; still produces structured review

## When to Use

Use this skill when:
- A feature has been implemented, merged, and deployed
- You want to capture what went well and what didn't
- You want to validate refinement estimates against actual effort
- You want to feed insights back into future work (ADRs, pattern inventory, refinement approach)

## When NOT to Use

- **PR not yet merged** — use [Code Review](../code-review/SKILL.md) for pre-merge review
- **Still implementing** — use [Implement Ticket](../implement-ticket/SKILL.md) to finish the work first
- **Bug investigation** — use [Fix Bug](../fix-bug/SKILL.md) for active defects, not retrospective analysis
- **Quick "how did it go?"** that doesn't need structured tracking — just discuss directly

## Invocation

```
Post-implementation review for HRZN-123
```

```
Review how HRZN-123 went after implementation
```

## Workflow

### Phase 1: Gather Context

1. **Fetch the ticket** (Jira MCP):
   - Full history: original description, refinement notes (`customfield_12636`), implementation summary comment, spike findings (if any)

2. **Fetch the PR** (GitHub MCP):
   - Files changed count
   - Review comments
   - Time to merge (created → merged)

3. **If no MCPs**: Ask user to provide ticket key, PR number, or describe the work

### Phase 2: Estimate Accuracy Review

Compare original refinement data against actual outcomes. Ask the user to confirm actual effort perception.

| Metric | Estimated | Actual | Assessment |
|--------|-----------|--------|------------|
| Fibonacci points | [from refinement] | [perceived actual] | Under / Accurate / Over |
| Confidence score | [from refinement] | [with hindsight] | Was it right? |
| Files changed | [from refinement plan] | [from PR] | Aligned / Scope grew |
| Unknowns | [predicted 0/N] | [encountered M] | Predicted / Surprise |

### Phase 3: Quality Assessment

Based on the PR and implementation summary:

- Were all acceptance criteria met?
- How many unknowns were encountered vs predicted?
- Were any follow-up tickets created during implementation?
- Did the self-review catch issues, or did PR reviewers find more?
- Was the testing strategy from refinement sufficient?

**Test Persona Retrospective** (if `@engineering-codex/facets/testing/test-personas.md` is available):

Review which test personas were covered during implementation:

| Persona | Covered? | Notes |
|---------|----------|-------|
| Optimist (happy path) | Yes/No | [which scenarios] |
| Saboteur (error path) | Yes/No | [which scenarios] |
| Boundary Walker (limits) | Yes/No | [which scenarios] |
| Explorer (unusual-but-valid) | Yes/No | [which scenarios] |
| Auditor (security) | Yes/No/N/A | [which scenarios] |
| User (E2E journey) | Yes/No/N/A | [which scenarios] |

If any persona was consistently missed, flag it as a pattern to improve in future refinements. This helps the team see systemic testing gaps over time (e.g. "we keep missing Saboteur tests for external integrations").

### Phase 4: Learning Capture

Ask structured questions using AskQuestion (or conversationally if unavailable):

1. "What went well that we should repeat?"
2. "What was harder than expected?"
3. "Were there any patterns or decisions that should be documented?" (triggers ADR suggestion or pattern inventory update)
4. "Would you change the refinement approach next time?"

### Phase 5: Produce Review and Recommendations

Output the review using the format below.

### Phase 6: Post to Jira

Generate the review using the format below, then **display it to the user and ask for confirmation before posting**:

```
Here is the post-implementation review I'll post to [ticket key]. Please review:

[formatted review]

Shall I post this to Jira? (yes / edit first / skip)
```

Only after the user confirms, post using `jira_add_comment`. Offer to create action item tickets if needed.

## Output Format

```markdown
## Post-Implementation Review: [HRZN-XXX] - [Title]

**Ticket:** [key]
**Branch/PR:** [branch] / PR #[number]
**Estimated:** [N] points | **Actual effort:** [assessment]
**Confidence at refinement:** [X]/12 | **Confidence in hindsight:** [Y]/12

---

### Estimate Accuracy
| Metric | Estimated | Actual | Assessment |
|--------|-----------|--------|------------|
| Fibonacci points | [from refinement] | [perceived actual] | Under / Accurate / Over |
| Confidence score | [from refinement] | [with hindsight] | Was it right? |
| Files changed | [from refinement plan] | [from PR] | Aligned / Scope grew |
| Unknowns | [predicted 0/N] | [encountered M] | Predicted / Surprise |

### What Went Well
- [Item]

### What Was Harder Than Expected
- [Item]

### Unknowns Encountered
| Unknown | Predicted? | Resolution | Time Impact |
|--------|------------|------------|-------------|
| ... | Yes/No | Solved inline / Follow-up | S/M/L |

### Test Persona Coverage
| Persona | Covered? | Notes |
|---------|----------|-------|
| Optimist | ... | ... |
| Saboteur | ... | ... |
| Boundary Walker | ... | ... |
| Explorer | ... | ... |
| Auditor | ... | ... |
| User | ... | ... |

**Pattern**: [If a persona is consistently missed across reviews, note it here]

### Recommendations for Future Work
- [Specific recommendation]

### Action Items
- [ ] [Update pattern inventory? Create ADR? Adjust golden path?]
- [ ] [Update refinement approach?]
- [ ] [Improve test persona coverage for: [persona]?]
- [ ] [Share learning with team?]
```

## Verification

- **Phase 1 (Context)**: Confirm Jira ticket data was fetched (non-empty summary). Confirm PR data includes merged status — if PR is not yet merged, this skill is premature.
- **Phase 2 (Estimates)**: Confirm the user validated the estimate accuracy table before proceeding. Do not infer "perceived actual" without user input.
- **Phase 6 (Post)**: If posting via `jira_add_comment`, verify the response indicates success. If it fails, present the review as markdown.

## Worked Example

**Input:** `Post-implementation review for HRZN-705`

**Key steps:**
1. Fetched HRZN-705 — "Add historical exchange rate lookup." PR #38 merged 2 days ago.
2. Estimate accuracy: 3 points estimated, felt like 3 (accurate). 1 unknown encountered (cache key change) — resolved inline.
3. Test persona coverage: Optimist and Saboteur covered, Boundary Walker missing (no test for dates before earliest rate).
4. Learning: "Cache key design should be considered during refinement, not discovered during implementation."

**Output excerpt:**
```markdown
## Post-Implementation Review: HRZN-705 — Historical exchange rate lookup

**Estimated:** 3 points | **Actual effort:** Accurate
**Confidence at refinement:** 10/12 | **Confidence in hindsight:** 10/12

### Test Persona Coverage
| Persona | Covered? | Notes |
|---------|----------|-------|
| Optimist | Yes | Rate lookup for valid date |
| Saboteur | Yes | API timeout, missing rate |
| Boundary Walker | No | No test for pre-history dates |

**Pattern**: Boundary Walker gaps on date-based queries — consider adding to refinement checklist.
```

## Error Handling

### Jira MCP Not Available

Present options using AskQuestion:
```
The Atlassian MCP (user-mcp-atlassian) isn't enabled.

How would you like to proceed?
1. Provide ticket details manually - Paste the ticket content and refinement notes
2. Describe the work - I'll build the review from your description
```

### Jira Fetch Fails

If `jira_get_issue` returns an error:
- Display the error message
- Ask user to paste ticket details and refinement notes
- Continue with the workflow using provided content

### Jira Comment Post Fails

If `jira_add_comment` returns an error:
- Display the error message
- Present the review as formatted markdown
- Instruct: "Copy the above and paste it as a comment on [ticket-key]"

### GitHub MCP Not Available

Skip PR stats. Proceed with estimate accuracy and learnings from ticket and user input.

### No PR Found

If the user provides a ticket key but no PR link, and GitHub search fails:
- Ask for PR number and repository
- Or proceed without PR stats; note "PR data unavailable" in the output

## Related Resources

- [Implement Ticket Skill](../implement-ticket/SKILL.md) - Implementation workflow (produces implementation summary)
- [Refine Ticket Skill](../refine-ticket/SKILL.md) - Refinement workflow (produces estimates and plan)
- [Assess Tests Skill](../assess-tests/SKILL.md) - Run a full test completeness audit if persona gaps are found
- [Pattern Inventory](../../../patterns/pattern-inventory.md) - Document patterns discovered during implementation
