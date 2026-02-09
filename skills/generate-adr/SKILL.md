# Generate ADR Skill

Generate a structured Architecture Decision Record from the context of a spike, deep dive, or ad-hoc architecture discussion.

## Prerequisites

### Required MCP Servers

| MCP Server | Tools Used | Purpose | Required? |
|------------|------------|---------|-----------|
| **user-mcp-atlassian** | `jira_get_issue` | Fetch spike findings | Optional |
| | `jira_add_comment` | Post ADR reference to spike ticket | Optional |

### Graceful Degradation

- **No Jira MCP**: Manual context input; skip posting ADR reference to Jira
- **No Engineering Codex**: Skip enrichment; proceed with user-provided context only

## When to Use

Invoke this skill when:
- A spike has concluded with an architecture decision
- A technical deep dive produced a recommendation that should be recorded
- An ad-hoc architecture discussion reached a decision
- A new significant technology or pattern choice needs documentation

## Invocation

```
Generate ADR for the decision to use Kafka over RabbitMQ in currency-manager
```

```
Generate ADR from spike HRZN-456 findings
```

## Workflow

### Phase 1: Gather Context

1. **Understand the decision**
   - If user provided a spike ticket key: fetch via `jira_get_issue` with `fields: "*all"`
   - Extract spike findings from `customfield_14303` (Spike Description) or comments
   - If no ticket: ask user what decision was made and why

2. **Identify target repository**
   - Infer from user input (e.g., "in currency-manager")
   - Or ask: "Which repository should this ADR live in?"

3. **Identify the ADR directory**
   - Check for `docs/adr/` in the target repository
   - If it doesn't exist: offer to create it
   - If user confirms, create the directory structure

### Phase 2: Determine Next ADR Number

1. List files in `docs/adr/`
2. Parse existing ADR filenames (e.g., `0001-record-architecture-decisions.md`, `0016-invoice-event-s3-storage.md`)
3. Find the highest number and increment for the new ADR
4. Use zero-padded format: `0017-` for ADR 17

### Phase 3: Generate the ADR

Use this template (consistent with finance/docs/adr/ format):

```markdown
# [NUMBER]. [Title]

Date: [YYYY-MM-DD]

## Status

Accepted

## Context

[What is the issue that we're seeing that is motivating this decision or change?]

## Decision

[What is the change that we're proposing and/or doing?]

## Consequences

### Positive
- [Benefit 1]

### Negative
- [Trade-off 1]

### Neutral
- [Side effect 1]
```

### Phase 4: Enrich with Codex (Optional)

If `@engineering-codex` is in the workspace:
- Identify the relevant facet (e.g., messaging, event-sourcing, caching)
- Read `@engineering-codex/facets/[facet]/options.md` for alternatives considered and trade-offs
- Incorporate evaluated options and rationale into Context and Consequences
- Add "Alternatives Considered" subsection if codex provides structured comparisons

### Phase 5: Write the File

1. Create the ADR file at `docs/adr/[NUMBER]-[slug].md`
2. Use kebab-case for the slug (e.g., `use-kafka-over-rabbitmq`)
3. Present the file path and contents to the user

### Phase 6: Offer to Update Jira

If triggered from a spike ticket:
- Offer to post the ADR reference as a Jira comment using `jira_add_comment`
- Include: ADR title, file path, and link to the file in the repo

## Output Format

The skill produces:
1. A markdown file in `docs/adr/` with the template above filled
2. Confirmation of file creation
3. Optional: Jira comment with ADR reference

## Error Handling

### No Jira MCP (Spike-Triggered)

Inform user:
```
Jira MCP is not available. I've generated the ADR from your description. 
You can manually add a comment to HRZN-456 with the ADR reference.
```

### ADR Directory Does Not Exist

Offer to create:
```
The target repository doesn't have a docs/adr/ directory. 
Would you like me to create it and add the ADR?
```

### Ambiguous or Conflicting Context

If spike findings and user input conflict:
- Prefer user input for the final decision
- Note any discrepancies: "The spike mentioned X; you specified Y. I've used Y."
- Ask for clarification if critical details are missing

### No Engineering Codex

Proceed without enrichment. Do not block. Inform user only if they asked about alternatives:
```
Engineering Codex is not in the workspace. I've generated the ADR from the context provided. 
You may want to add an "Alternatives Considered" section manually if relevant.
```

### Target Repository Not in Workspace

If the user specifies a repo not in the workspace:
- Generate the ADR content
- Save to a file in the current workspace (e.g., workspace root or a temp location)
- Provide instructions for moving it to the target repo

### Duplicate or Overlapping ADR

If an existing ADR seems to cover the same decision:
- List the overlapping ADRs
- Ask: "ADR-0012 already covers event storage. Should this be an amendment, or a new decision?"

## Related Resources

- [Spike Skill](../spike/SKILL.md) — Often triggers ADR creation
- [Technical Deep Dive Skill](../technical-deep-dive/SKILL.md) — Produces recommendations that may become ADRs
- [Finance ADRs](../../../finance/docs/adr/) — Format reference
