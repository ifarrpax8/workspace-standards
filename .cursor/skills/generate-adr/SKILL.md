---
name: generate-adr
description: Generate an Architecture Decision Record from spike findings, deep dives, or ad-hoc decisions.
---
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

## When NOT to Use

- **Still investigating options** — use [Spike](../spike/SKILL.md) or [Evaluate Options](../evaluate-options/SKILL.md) first
- **Trivial decisions** that don't need formal record (config changes, library patch versions)
- **Team hasn't agreed** on the decision yet — document options first, then generate the ADR once decided

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

If triggered from a spike ticket, generate the Jira comment below, **display it to the user and ask for confirmation before posting**:

```
Here is the Jira comment I'll post to [ticket key]. Please review:

[formatted ADR reference]

Shall I post this to Jira? (yes / edit first / skip)
```

Only after the user confirms, post using `jira_add_comment`.

## Output Format

The skill produces a markdown file in `docs/adr/` and, if spike-triggered, an optional Jira comment.

**ADR file**: `docs/adr/[NNNN]-[slug].md` filled from the template above.

**Jira comment** (if spike-triggered):

```
ADR created: [NNNN]-[slug].md
Decision: [one-sentence summary of the decision]
Linked spike: [HRZN-XXX]
Location: docs/adr/[NNNN]-[slug].md
```

## Verification

- **Phase 2 (Number)**: Confirm the ADR number doesn't collide with an existing file. List the directory and verify the computed number is one higher than the max.
- **Phase 5 (Write)**: After writing the file, verify it exists and the first line matches the expected `# [NUMBER]. [Title]` format.
- **Phase 6 (Jira)**: If posting via `jira_add_comment`, verify the response indicates success. If it fails, provide the ADR reference for manual posting.

## Worked Example

**Input:** `Generate ADR from spike HRZN-456 findings`

**Key steps:**
1. Fetched HRZN-456 — spike concluded with recommendation to use Caffeine cache
2. Target repo: `currency-manager`. Found `docs/adr/` with 3 existing ADRs (max: 0003)
3. Generated ADR 0004: "Use Caffeine In-Process Cache for Exchange Rates"
4. Enriched from Engineering Codex `facets/caching/options.md` — added Redis and Hazelcast as alternatives considered
5. Wrote to `docs/adr/0004-use-caffeine-cache-for-exchange-rates.md`
6. Posted ADR reference as comment on HRZN-456

**Output excerpt:**
```markdown
# 4. Use Caffeine In-Process Cache for Exchange Rates

Date: 2026-02-14

## Status
Accepted

## Context
Currency-manager calls an external exchange rate API. Without caching, every rate lookup
triggers an HTTP call (~200ms). The service is the sole consumer of this data.

## Decision
Use Caffeine in-process cache with a 5-minute TTL.

## Consequences
### Positive
- No external infrastructure dependency (Redis, Memcached)
- Sub-millisecond cache hits

### Negative
- Cache is not shared across instances (acceptable — rates are idempotent)
```

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
