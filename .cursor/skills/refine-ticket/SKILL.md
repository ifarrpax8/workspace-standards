---
name: refine-ticket
description: Three Amigos refinement for Jira tickets with confidence scoring and implementation planning.
---
# Refine Ticket Skill

Interactive Three Amigos refinement for Jira tickets with automatic PRD fetching, confidence scoring, and implementation plan generation.

## Prerequisites

### Required MCP Servers

This skill works best with the following MCP servers enabled:

| MCP Server | Tools Used | Purpose | Required? |
|------------|------------|---------|-----------|
| **user-mcp-atlassian** | `jira_get_issue` | Fetch Jira ticket details | Recommended |
| | `jira_update_issue` | Update ticket description with implementation plan | Recommended |
| | `jira_add_comment` | Post implementation plan to Jira | Recommended |
| | `confluence_get_page` | Fetch PRD from Confluence | Optional |
| **user-github** | `search_code` | Search patterns across Pax8 org (via Deep Dive) | Optional |

> **Important:** See [Jira Standards](../../rules/jira-standards.md) for custom field usage. The business uses `customfield_12636` instead of the standard description field.

### Checking MCP Availability

Before starting, verify MCP availability by checking if the Atlassian MCP tools are accessible. If not enabled, the skill will offer manual alternatives.

### Extended Capabilities

When technical investigation is needed, this skill may invoke the **Technical Deep Dive** skill, which can leverage:
- Local workspace repositories
- GitHub search across all Pax8 org repos (if `user-github` MCP enabled)
- Web search for external documentation

### Engineering Codex Integration

If `@engineering-codex` is in the workspace, this skill will automatically:
- Check relevant facets' `gotchas.md` to identify risks during the Developer Perspective analysis
- Reference `best-practices.md` for the relevant facets when proposing implementation approaches
- Check `@engineering-codex/pax8-context/standards-map.md` to pre-fill technology decisions that Pax8 has already made
- Use `tech-radar.md` to validate tool/library choices mentioned in the ticket

If the codex is not available, the skill falls back to golden paths and web search as before.

### Graceful Degradation

If MCPs are not available, the skill will:
1. **Prompt to enable**: "The Atlassian MCP (`user-mcp-atlassian`) is not enabled. Would you like to enable it, or provide ticket details manually?"
2. **Offer manual input**: Accept pasted Jira ticket content
3. **Skip unavailable features**: Generate implementation plan as markdown for manual copy/paste to Jira

## When to Use

Use this skill when:
- Starting work on a new Jira ticket
- Preparing tickets for sprint planning
- Ensuring a ticket meets Definition of Ready
- Need to document implementation approach

## When NOT to Use

- **Ticket is already refined** and ready to implement — use [Implement Ticket](../implement-ticket/SKILL.md)
- **Fixing a known bug** — use [Fix Bug](../fix-bug/SKILL.md) directly; bugs don't need Three Amigos refinement
- **Spike or research** — use [Spike](../spike/SKILL.md) for time-boxed investigation before refinement
- **Simple config change** with no ambiguity that doesn't warrant formal refinement

## Invocation

```
Refine ticket HRZN-123
```

Or with additional context:
```
Refine ticket HRZN-123 for the finance-mfe and invoice-service repositories
```

## Workflow

### Phase 1: Input and Fetch

1. Extract the Jira ticket key from user input
2. Fetch ticket details using Atlassian MCP:

```
Use the jira_get_issue tool with:
- issue_key: [extracted ticket key]
- fields: "*all"
- expand: "renderedFields"
```

3. Extract the Epic link from the ticket
4. If Epic has a PRD link (Confluence), fetch it:

```
Use the confluence_get_page tool with:
- page_id: [extracted from Epic's PRD link]
- convert_to_markdown: true
```

5. Ask user to confirm or specify target repositories if not clear from ticket labels/components

### Phase 2: Three Amigos Analysis

Present analysis from each perspective:

#### Developer Perspective
- Assess technical feasibility based on ticket description and PRD
- Check alignment with golden path architectures (reference `@workspace-standards/golden-paths/`)
- If `@engineering-codex` is available: read relevant facet's `best-practices.md` and `gotchas.md` to inform the assessment, and check `pax8-context/standards-map.md` for pre-decided technology choices
- Identify affected components and files in target repositories
- Propose implementation approach options (informed by codex `options.md` if available)
- Identify technical risks and dependencies (informed by codex `gotchas.md` if available)

#### Test Perspective
- Extract testable scenarios from acceptance criteria
- If `@engineering-codex/facets/testing/test-personas.md` is available, use the six test personas to generate comprehensive scenarios:
  - **The Optimist**: What are the happy path success scenarios?
  - **The Saboteur**: What happens when dependencies fail or input is invalid?
  - **The Boundary Walker**: What are the limits (zero, max, empty, off-by-one)?
  - **The Explorer**: What unusual-but-valid combinations exist (concurrency, duplicates)?
  - **The Auditor**: Are there auth, tenant isolation, or injection risks?
  - **The User**: What end-to-end journeys need E2E coverage?
- If codex is not available, fall back to the standard edge case checklist:
  - Null/empty inputs
  - Boundary conditions (min/max values)
  - Permission scenarios
  - Error conditions
- Assess regression risk to existing functionality
- Recommend test types (unit, integration, E2E) and map to the test pyramid

#### Product Perspective
- Evaluate clarity of user value
- Check acceptance criteria completeness
- Identify missing business context
- Flag scope concerns

### Phase 3: Interactive Q&A

Present the initial analysis with identified gaps, then ask clarifying questions grouped by persona:

**Format questions using the AskQuestion tool** to gather structured input:

Example questions to ask:
- Developer: "Which existing pattern should this follow?" with options from golden paths
- Test: "Are there specific boundary values to test?" 
- Product: "Should [edge case] result in [behavior A] or [behavior B]?"

Update analysis based on responses and iterate until gaps are resolved.

### Phase 4: Scoring

Calculate confidence score (1-12) using this rubric:

| Factor | Low (1) | Medium (2) | High (3) |
|--------|---------|------------|----------|
| Requirements | Vague, missing AC | Some AC, gaps exist | Clear, complete AC |
| Technical | Unknown approach | Approach with unknowns | Clear, proven patterns |
| Test Coverage | No scenarios | Some scenarios | Full coverage defined |
| Dependencies | Unknown blockers | Known, some unresolved | All resolved |

**If Technical score is 1 (Low):**
Suggest: "Technical confidence is low. Would you like to run a technical deep dive to investigate the codebase?"

If user agrees, guide them to invoke:
```
@workspace-standards/.cursor/skills/technical-deep-dive/SKILL.md investigate [topic] in [repository]
```

Then return to this refinement with enhanced technical context.

**Recommend Fibonacci estimate** based on:
- 1: Config/copy change
- 2: Single component, straightforward
- 3: Multiple files, clear approach
- 5: Multiple components, some complexity
- 8: Cross-service, significant complexity
- 13: Should be broken down (suggest splitting)

### Phase 5: Output

Generate the implementation plan using the format below, then **display it to the user and ask for confirmation before posting**:

```
Here is the implementation plan I'll post to [ticket key]. Please review:

[formatted implementation plan]

Shall I post this to Jira? (yes / edit first / skip)
```

Only proceed to post after the user confirms. Then:

```
Use the jira_update_issue tool with:
- issue_key: [ticket key]
- fields: {}
- additional_fields: { "customfield_12636": "[formatted implementation plan - see format below]" }
```

> **Note:** Use `customfield_12636` (custom Description field), not the standard description. See [Jira Standards](../../rules/jira-standards.md).

Alternatively, add as a comment:

```
Use the jira_add_comment tool with:
- issue_key: [ticket key]
- comment: [formatted implementation plan - see format below]
```

## Implementation Plan Format

Post this format as a Jira comment:

```
[HRZN-XXX] [Ticket title] | [N]pts | [X]/12 [High/Medium/Low]

Approach: [One sentence describing the agreed technical approach]

Decisions:
- [Key decision, e.g. framework choice, scope boundary, approach chosen]
- [Another decision — include brief rationale if non-obvious]

Files:
  New:     [filename.ext, filename.ext]
  Modify:  [filename.ext — what changes]
  Extract: [filename.ext (from current location)]

Tasks:
  1. [Task] — [key constraint or AC in brief]
  2. [Task] — [key constraint or AC in brief]
  3. Tests: [types and focus areas]

Test focus:
- [Key scenario or constraint to verify]
- [Another area, especially edge cases or access control]

Dependencies:
- [HRZN-XXX] ([runtime/compile-time]): [one line description]

Risks:
- [Risk] → [mitigation]
```

## Definition of Ready Verification

Before completing refinement, verify these are satisfied:

- [ ] User story follows format: "As a [role], I want [goal], so that [benefit]"
- [ ] Acceptance criteria are specific, measurable, and testable
- [ ] Technical approach agreed
- [ ] Test scenarios documented
- [ ] Dependencies identified
- [ ] Affected codebases identified
- [ ] Fibonacci estimate agreed
- [ ] No open questions blocking implementation
- [ ] PRD linked (via Epic)
- [ ] Confidence score is 7+ (Medium or High)

If any items are not satisfied, flag them and ask if refinement should continue or if the ticket needs more work before sprint commitment.

## Verification

After each critical operation, verify success:

- **Phase 1 (Fetch)**: Confirm `jira_get_issue` returned ticket data with a non-empty summary. If `customfield_12636` is empty, the ticket has no existing refinement notes — this is expected for unrefined tickets.
- **Phase 2 (Analysis)**: Confirm at least one test scenario was generated per persona perspective used. If zero scenarios, the acceptance criteria may be too vague — flag in Q&A.
- **Phase 4 (Score)**: Confirm the confidence score is a number between 1-12 and each factor has a valid rating. Present the breakdown for user confirmation.
- **Phase 5 (Jira Update)**: If posting via `jira_update_issue` or `jira_add_comment`, verify the response indicates success. If it fails, present the plan as markdown for manual copy.

## Worked Example

**Input:** `Refine ticket HRZN-712`

**Key steps:**
1. Fetched HRZN-712 — "Allow partners to filter invoices by currency." Epic linked to PRD on Confluence, fetched PRD context.
2. Three Amigos analysis:
   - Developer: Filter added to `InvoiceListEndpoint`, new query param, existing `InvoiceRepository` already supports currency field
   - Test (using personas): Optimist — filter returns matching invoices; Saboteur — invalid currency code returns 400; Boundary Walker — empty result set returns 200 with empty list
   - Product: Confirmed filter should be optional (no filter = all currencies)
3. Q&A resolved: "Should multi-currency filter be supported?" → No, single currency only for v1
4. Scored 10/12 (High). Recommended 3 points (multiple files, clear approach).
5. Posted implementation plan to HRZN-712 via `customfield_12636`

**Output excerpt:**
```
[HRZN-712] Allow partners to filter invoices by currency | 3pts | 10/12 High

Approach: Add optional currency query param to InvoiceListEndpoint — existing
InvoiceRepository currency field requires no schema change.

Decisions:
- Filter is optional: absent = all currencies returned
- Single currency only for v1 (multi-currency deferred)

Files:
  Modify: InvoiceListEndpoint.groovy — add currency param, InvoiceRepository.groovy — add filter

Tasks:
  1. Add currency query param to InvoiceListEndpoint — passes to repository filter
  2. Add currency filter to InvoiceRepository — uses existing currency field
  3. Tests: filter returns matching invoices, invalid code returns 400, absent param returns all

Test focus:
- Valid currency code returns matching invoices only
- Invalid currency code "XYZ" → 400
- Absent param → all invoices (no filter applied)
- Empty result set → 200 with empty list

Dependencies: none
Risks: none identified
```

## Error Handling

### MCP Not Available

**If Atlassian MCP is not enabled:**

Present options using AskQuestion:
```
The Atlassian MCP (user-mcp-atlassian) doesn't appear to be enabled. 
This skill uses it to fetch Jira tickets and post comments automatically.

How would you like to proceed?
1. Enable the MCP - I'll wait while you enable user-mcp-atlassian in Cursor settings
2. Provide ticket manually - Paste the Jira ticket content and I'll continue
3. Skip Jira integration - I'll generate the implementation plan as markdown for you to copy
```

**If user chooses manual input:**
- Ask for: Ticket ID, Title, Description, Acceptance Criteria, Epic/PRD link
- Continue with refinement process using provided content
- At output phase, generate markdown instead of posting to Jira

### Jira Fetch Fails

If `jira_get_issue` returns an error:
- Display the error message
- Ask user to paste ticket details manually
- Continue with refinement process

### Jira Comment Post Fails

If `jira_add_comment` returns an error:
- Display the error message
- Present the implementation plan as formatted markdown
- Instruct: "Copy the above and paste it as a comment on [ticket-key]"

### PRD Not Found

If Confluence page fetch fails or no PRD link exists:
- Note that PRD context is missing
- Reduce confidence score for Requirements by 1 point
- Ask user if they can provide PRD content or a link

### Low Confidence Score (< 7)
- Clearly state the ticket is not ready for sprint
- List specific gaps that need addressing
- Suggest next steps (technical deep dive, product clarification, etc.)

## Related Resources

- [Implement Ticket Skill](../implement-ticket/SKILL.md) - Structured implementation of refined tickets (next step after refinement)
- [Refinement Best Practices](../../rules/refinement-best-practices.md)
- [Technical Deep Dive Skill](../technical-deep-dive/SKILL.md) - Quick codebase investigation (hours)
- [Spike Skill](../spike/SKILL.md) - Time-boxed research (days) for broader investigation
- [Golden Paths](../../../golden-paths/)
- [Scoring Criteria](../../../scoring/criteria/)
