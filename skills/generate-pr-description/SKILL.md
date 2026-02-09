# Generate PR Description Skill

Generate a structured PR description from implementation context — branch diff, linked ticket, implementation summary, and test evidence.

## Prerequisites

### Required MCP Servers

| MCP Server | Tools Used | Purpose | Required? |
|------------|------------|---------|-----------|
| **user-github** | `get_pull_request` | Fetch existing PR details | Optional |
| | `get_pull_request_files` | Fetch changed file list | Optional |
| **user-mcp-atlassian** | `jira_get_issue` | Fetch ticket context and implementation notes | Optional |

### Graceful Degradation

- **No GitHub MCP**: Generate from local git context only (`git log`, `git diff`)
- **No Jira MCP**: Skip ticket context; use branch name and diff for summary

## When to Use

Invoke this skill when:
- Creating a new PR and need a structured description
- Updating an existing PR with a better description
- Need to summarize changes for review handoff
- Ticket key is in branch name and you want ticket context included

## Invocation

```
Generate PR description for my current branch
```

```
Generate PR description for HRZN-123
```

## Workflow

### Phase 1: Gather Context

1. **Identify the branch**
   - Run `git rev-parse --abbrev-ref HEAD` to get current branch
   - If user provided a ticket key (e.g., HRZN-123), extract it

2. **Understand what changed**
   - Run `git log main..HEAD` for commit messages
   - Run `git diff main --stat` for file change summary
   - Optionally: `git diff main` for full diff if needed

3. **Fetch ticket context** (if ticket key in branch name or user input)
   - Use `jira_get_issue` with `fields: "*all"`
   - Extract implementation notes from `customfield_12636` or comments

4. **Fetch existing PR** (if GitHub MCP available)
   - Use `get_pull_request` to fetch PR for current branch
   - Use `get_pull_request_files` for changed files
   - Use existing PR title/body as fallback or merge source

### Phase 2: Extract Implementation Notes

From the Jira ticket (if available):
- Read `customfield_12636` (refinement/implementation notes)
- Scan comments for implementation summary
- Extract acceptance criteria, technical approach, test scenarios

### Phase 3: Generate PR Description

Use this template:

```markdown
## [HRZN-XXX] — [Title]

### Summary
[1-2 sentence description of what this PR does and why]

### Changes
- [Bullet list of key changes, grouped by concern]

### Testing
- [List of test types added/modified]
- [Key scenarios covered]

### How to Test
1. [Step-by-step manual verification if needed]

### Screenshots
[If frontend changes — prompt user to add]

### Checklist
- [ ] Tests passing
- [ ] Self-review completed
- [ ] No linter warnings introduced
- [ ] Documentation updated (if applicable)

### Related
- Jira: [HRZN-XXX](link)
- [Related PRs if any]
```

Derive content from:
- Commit messages for change summary
- Diff stats for scope
- Ticket for context, acceptance criteria, and rationale
- User input for any gaps

### Phase 4: Offer Actions

Present the generated description and offer:

1. **Copy to clipboard** — User pastes into PR manually
2. **Create/update PR via GitHub MCP** — If GitHub MCP available, offer to create or update the PR
3. **Save as markdown** — Write to a file (e.g., `pr-description.md`) for manual use

## Output Format

The skill outputs the PR description in the template format above, with all sections filled based on gathered context. Placeholder sections (e.g., "prompt user to add" for Screenshots) should be replaced with explicit prompts when that makes sense.

## Error Handling

### No GitHub MCP

Proceed with local git context only. Inform user:
```
GitHub MCP is not available. I've generated the description from your local branch and commits. 
You can copy this and paste it into the PR manually.
```

### No Jira MCP

Skip ticket context. Inform user:
```
Jira MCP is not available. I couldn't fetch ticket details. 
The description is based on branch name, commit messages, and diff. 
You may want to add ticket context manually.
```

### Branch Not Pushed / No Remote PR

If `get_pull_request` finds no PR:
- Generate full description from local context
- Offer to create PR when user pushes (if GitHub MCP available)
- Provide description for manual PR creation

### Ambiguous Ticket Key

If branch name contains multiple possible ticket patterns (e.g., `feature/HRZN-123-something-HRZN-456`):
- Ask user which ticket to use, or
- Use the first match
- Fetch both if both seem relevant and merge context

### Empty or Minimal Diff

If `git diff main --stat` shows no changes:
- Check if on correct branch
- Check if main is up to date (`git fetch origin main`)
- Ask user to confirm branch and base

## Related Resources

- [Implement Ticket Skill](../implement-ticket/SKILL.md) — Produces implementation that leads to PRs
- [Post-Implementation Review Skill](../post-implementation-review/SKILL.md) — Reviews merged PRs
- [Jira Standards](../../rules/auto-apply/jira-standards.md) — Custom field usage
