---
name: post-implementation-review
description: Closing-the-loop skill for completed features. After a PR is merged and deployed, reviews the journey from idea to delivery, captures learnings, validates estimates, and updates team knowledge. Use when the user wants to reflect on a completed ticket, run a post-mortem, or feed insights back into future work.
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

> **Important:** See [Jira Standards](../../rules/auto-apply/jira-standards.md) for custom field usage. Refinement notes live in `customfield_12636`.

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

### Phase 4: Learning Capture

Ask structured questions using AskQuestion (or conversationally if unavailable):

1. "What went well that we should repeat?"
2. "What was harder than expected?"
3. "Were there any patterns or decisions that should be documented?" (triggers ADR suggestion or pattern inventory update)
4. "Would you change the refinement approach next time?"

### Phase 5: Produce Review and Recommendations

Output the review using the format below.

### Phase 6: Post to Jira

If Jira MCP available, post the review as a comment on the ticket using `jira_add_comment`.
Offer to create action item tickets if needed.

## Output Format

```markdown
## Post-Implementation Review: [HRZN-XXX] - [Title]

**Ticket:** [key]
**Branch/PR:** [branch] / PR #[number]
**Estimated:** [N] points | **Actual effort:** [assessment]
**Confidence at refinement:** [X]/12 | **Confidence in hindsight:** [Y]/12

---

### Estimate Accuracy
[table from Phase 2]

### What Went Well
- [Item]

### What Was Harder Than Expected
- [Item]

### Unknowns Encountered
| Unknown | Predicted? | Resolution | Time Impact |
|--------|------------|------------|-------------|
| ... | Yes/No | Solved inline / Follow-up | S/M/L |

### Recommendations for Future Work
- [Specific recommendation]

### Action Items
- [ ] [Update pattern inventory? Create ADR? Adjust golden path?]
- [ ] [Update refinement approach?]
- [ ] [Share learning with team?]
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
- [Pattern Inventory](../../patterns/pattern-inventory.md) - Document patterns discovered during implementation
