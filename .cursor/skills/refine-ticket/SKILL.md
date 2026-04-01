---
name: refine-ticket
description: Three Amigos refinement for Jira tickets with confidence scoring and implementation planning.
complexity: low
prompt-version: "1.3"
---
# Refine Ticket Skill

Interactive Three Amigos refinement for Jira tickets with automatic PRD fetching, confidence scoring, and implementation plan generation.

## Prerequisites

### Required MCP Servers

This skill works best with the following MCP servers enabled:

| MCP Server | Tools Used | Purpose | Required? |
|------------|------------|---------|-----------|
| **Atlassian MCP** (e.g. Cursor `plugin-atlassian-atlassian`) | `getJiraIssue` | Fetch Jira ticket details (`cloudId`, `issueIdOrKey`; use `responseContentFormat: adf` when editing descriptions) | Recommended |
| | `editJiraIssue` | Update ticket description and `customfield_12636` | Recommended |
| | `addCommentToJiraIssue` | Post implementation plan to Jira | Recommended |
| | `getConfluencePage` | Fetch PRD from Confluence | Optional |
| **user-github** | `search_code` | Search patterns across Pax8 org (via Deep Dive) | Optional |

> **Important:** See [Jira Standards](../../rules/jira-standards.md) for custom field usage, **ADF requirements**, and Success Criteria spacing. The business uses `customfield_12636` for Story descriptions; Jira Cloud requires **Atlassian Document Format** for that field, not wiki or markdown strings.

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
1. **Prompt to enable**: "The Atlassian MCP (e.g. `plugin-atlassian-atlassian`) is not enabled. Would you like to enable it, or provide ticket details manually?"
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
Use the getJiraIssue tool with:
- cloudId: [from getAccessibleAtlassianResources]
- issueIdOrKey: [extracted ticket key]
- expand: "renderedFields" (if supported)
- responseContentFormat: adf when Phase 5 will rewrite the description; otherwise markdown is fine
```

3. Extract the Epic link from the ticket (check `parent` field or `customfield_10014` for the Epic key)
4. Fetch the Epic to find the PRD link:

```
Use the getJiraIssue tool with:
- cloudId: [from getAccessibleAtlassianResources]
- issueIdOrKey: [Epic key from step 3]
- fields: ["customfield_12637", "description", "summary"]
```

5. Locate the PRD link in the Epic's description:
   - Check `customfield_12637` first (the "Epic Description" custom field used by the business — see [Jira Standards](../../rules/jira-standards.md))
   - Fall back to the standard `description` field if the custom field is empty
   - The Epic description template includes a "PRD Link" section — scan for a Confluence URL (e.g. `https://*.atlassian.net/wiki/spaces/...` or `https://*.atlassian.net/wiki/x/...`)
   - The link is typically preceded by a label such as "PRD Link", "PRD:", or "Product Requirements Document"

6. If a Confluence URL is found, extract the page ID and fetch the PRD:

```
Use the getConfluencePage tool with:
- cloudId: [from getAccessibleAtlassianResources]
- pageId: [extracted from the Confluence URL path — the numeric segment after /pages/]
- contentFormat: markdown (if supported)
```

> **Tip:** Confluence URLs come in two common formats:
> - Long form: `https://pax8.atlassian.net/wiki/spaces/SPACE/pages/123456789/Page+Title` — page ID is `123456789`
> - Short link: `https://pax8.atlassian.net/wiki/x/AbCdEf` — pass the encoded segment to `getConfluencePage` or use `searchConfluenceUsingCql` with the page title as a fallback

7. Ask user to confirm or specify target repositories if not clear from ticket labels/components

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
- **Structure scenarios with expected outcomes**: Each scenario must include the action/condition and the expected result (e.g., "Filter by invalid currency code → 400 Bad Request"). These structured scenarios will be carried into the implementation plan's Test Scenarios section, grouped by: happy path, error path, boundary, and security/access.
- Assess regression risk to existing functionality
- Recommend test types (unit, integration, E2E) and map to the test pyramid

#### Product Perspective
- Evaluate clarity of user value
- **Enrich acceptance criteria** in two formats (both derived from the same analysis):
  1. **Success Criteria** (for the ticket description's Success Criteria panel) — Written in Gherkin syntax (Given/When/Then) from the user's perspective. These are the behavioural acceptance criteria the team and testers will reference. See [Success Criteria Format](#success-criteria-format) below.
  2. **Acceptance Criteria** (for the implementation plan comment) — Checklist-style (`- [ ]`) with specific, testable criteria including expected behaviour. These are the developer-facing criteria used during implementation.
- Review the original AC from the ticket. Rewrite vague criteria to be specific, measurable, and testable. Add missing criteria surfaced by the Developer and Test perspectives (edge cases, error handling, boundary behaviour). The enriched criteria replace the originals, not supplement them.
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

Generate two artefacts from the Three Amigos analysis:

1. **Success Criteria** (Gherkin format) — for the ticket description's Success Criteria panel. See [Success Criteria Format](#success-criteria-format).
2. **Implementation Plan** (comment format) — the full plan including checklist-style AC, test scenarios, tasks, etc. See [Implementation Plan Format](#implementation-plan-format). Populate from:
   - **Repositories**: From Phase 1 step 7 (confirmed target repositories)
   - **Acceptance Criteria**: The enriched AC from the Product Perspective (not the original ticket AC)
   - **Test Scenarios**: The structured scenarios from the Test Perspective, grouped by category with expected outcomes

**Display both to the user and ask for confirmation before posting**:

```
Here is what I'll update on [ticket key]. Please review:

── Ticket Description (Success Criteria panel) ──

[formatted Gherkin success criteria]

── Implementation Plan (comment) ──

[formatted implementation plan]

Shall I post both to Jira? (yes / edit first / skip)
```

Only proceed after the user confirms. Then perform two Jira updates:

#### Step 1: Update the ticket description

Read the existing description from `customfield_12636` (fetched in Phase 1). Preserve the existing Overview panel and replace the Success Criteria panel with the enriched Gherkin criteria. Write the implementation plan into the Refinement Notes panel. See [Jira Standards](../../rules/jira-standards.md) for the panel template and **ADF** requirements.

**Jira Cloud / MCP:** Use `getJiraIssue` with `responseContentFormat: adf` to obtain the current document, then `editJiraIssue` with `contentFormat: adf` and the same ADF `doc` in **both** `fields.description` and `fields.customfield_12636`. Wiki-style `{panel:...}` strings are a human-readable reference only; the API expects ADF JSON for `customfield_12636`. Resolve `cloudId` via `getAccessibleAtlassianResources` when the tool requires it.

```
Use the editJiraIssue tool with:
- cloudId: [from getAccessibleAtlassianResources]
- issueIdOrKey: [ticket key]
- contentFormat: adf
- fields: { "description": { ADF doc }, "customfield_12636": { same ADF doc } }
```

If the issue type does not use `customfield_12636`, update `description` only per [Jira Standards](../../rules/jira-standards.md).

The description should follow this structure (express in ADF panels as documented in Jira Standards):
```
{panel:bgColor=#deebff}
*Overview*

[preserved from original ticket — do not modify]
{panel}

{panel:bgColor=#eae6ff}
*Refinement Notes*

[formatted implementation plan — same content as the comment]
{panel}

{panel:bgColor=#e3fcef}
*Success Criteria*

[Gherkin-format success criteria — see Success Criteria Format below]
{panel}
```

> **Important:** Write the same ADF document to both `fields.description` and `fields.customfield_12636` when the issue uses that custom field. See [Jira Standards](../../rules/jira-standards.md).

#### Step 2: Post the implementation plan as a comment

```
Use the addCommentToJiraIssue tool with:
- cloudId: [from getAccessibleAtlassianResources]
- issueIdOrKey: [ticket key]
- contentFormat: markdown (or adf if needed)
- commentBody: [formatted implementation plan - see format below]
```

The comment provides a timestamped record of the refinement output. The description is the living document that the team references during implementation.

## Success Criteria Format

Write success criteria in Gherkin syntax (Given/When/Then) from the user's perspective. These go into the ticket description's Success Criteria panel.

```
Given [precondition or context]
When [action the user takes]
Then [expected observable outcome]

Given [precondition or context]
When [action the user takes]
And [additional action or condition]
Then [expected observable outcome]
And [additional expected outcome]
```

**Guidelines:**
- Write from the user's perspective, not the system's (e.g., "Given I am on the invoices page" not "Given the InvoiceListEndpoint receives a request")
- Each scenario should be independently understandable
- Use `And` to chain multiple preconditions, actions, or outcomes within a single scenario
- Cover the happy path first, then key error and edge cases
- Keep language natural and non-technical — these are read by product, QA, and developers alike

**Jira / ADF presentation:** When posting Success Criteria to the ticket description, separate scenarios visually. In Atlassian Document Format, use a **heading** (level 4) per scenario (e.g. “Scenario 1”, “Scenario 2”) before that scenario’s Given/When/Then paragraphs, or insert **`horizontalRule`** nodes between scenarios (see [Jira Standards](../../rules/jira-standards.md)). Plain consecutive paragraphs often render as a single block in the Success Criteria panel.

## Implementation Plan Format

Post this format as a Jira comment:

```
[HRZN-XXX] [Ticket title] | [N]pts | [X]/12 [High/Medium/Low]

Repositories: [repo-1, repo-2]

Acceptance Criteria:
- [ ] [Specific, testable criterion — enriched from original AC and Three Amigos analysis]
- [ ] [Another criterion — include expected behaviour, not just intent]
- [ ] [Edge case or error scenario surfaced during refinement]

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

Test Scenarios:
  Happy path:
  - [Scenario] → [expected outcome]
  Error path:
  - [Scenario] → [expected outcome]
  Boundary:
  - [Scenario] → [expected outcome]
  Security/access:
  - [Scenario] → [expected outcome] (include only when relevant)

Dependencies:
- [HRZN-XXX] ([runtime/compile-time]): [one line description]

Risks:
- [Risk] → [mitigation]
```

## Definition of Ready Verification

Before completing refinement, verify these are satisfied:

- [ ] User story follows format: "As a [role], I want [goal], so that [benefit]"
- [ ] Acceptance criteria are enriched, specific, measurable, and testable (included in implementation plan)
- [ ] Technical approach agreed
- [ ] Test scenarios documented with expected outcomes, grouped by category (included in implementation plan)
- [ ] Target repositories explicitly listed in implementation plan
- [ ] Dependencies identified
- [ ] Fibonacci estimate agreed
- [ ] No open questions blocking implementation
- [ ] PRD linked (via Epic)
- [ ] Confidence score is 7+ (Medium or High)

If any items are not satisfied, flag them and ask if refinement should continue or if the ticket needs more work before sprint commitment.

## Verification

After each critical operation, verify success:

- **Phase 1 (Fetch)**: Confirm `getJiraIssue` returned ticket data with a non-empty summary. If `customfield_12636` is empty, the ticket has no existing refinement notes — this is expected for unrefined tickets. Confirm the Epic was fetched and check whether a Confluence PRD link was found in `customfield_12637` or `description`. If no link was found, flag this in the analysis.
- **Phase 2 (Analysis)**: Confirm at least one test scenario was generated per persona perspective used. If zero scenarios, the acceptance criteria may be too vague — flag in Q&A.
- **Phase 4 (Score)**: Confirm the confidence score is a number between 1-12 and each factor has a valid rating. Present the breakdown for user confirmation.
- **Phase 5 (Jira Update)**: Two verifications required:
  1. **Description update** (`editJiraIssue` with ADF for `customfield_12636` when applicable): Verify the response indicates success. If it fails with an ADF validation error, switch from wiki/markdown strings to Atlassian Document Format per [Jira Standards](../../rules/jira-standards.md). If it still fails, present the description content for manual copy — flag that the Success Criteria panel needs updating.
  2. **Comment** (`addCommentToJiraIssue`): Verify the response indicates success. If it fails, present the implementation plan as markdown for manual copy.

## Worked Example

**Input:** `Refine ticket HRZN-712`

**Key steps:**
1. Fetched HRZN-712 — "Allow partners to filter invoices by currency." Epic linked to PRD on Confluence, fetched PRD context.
2. Three Amigos analysis:
   - Developer: Filter added to `InvoiceListEndpoint`, new query param, existing `InvoiceRepository` already supports currency field
   - Test (using personas): Optimist — filter returns matching invoices; Saboteur — invalid currency code returns 400; Boundary Walker — empty result set returns 200 with empty list
   - Product: Confirmed filter should be optional (no filter = all currencies). Enriched AC in both Gherkin (for description) and checklist (for plan).
3. Q&A resolved: "Should multi-currency filter be supported?" → No, single currency only for v1
4. Scored 10/12 (High). Recommended 3 points (multiple files, clear approach).
5. Updated HRZN-712 description (Success Criteria panel) and posted implementation plan as comment

**Success Criteria (written to ticket description):**
```
Given I am on the invoices page
When I select currency "USD" from the filter
Then only invoices with currency USD are displayed

Given I am on the invoices page
When I do not select a currency filter
Then all invoices are displayed regardless of currency

Given I am on the invoices page
When I enter an invalid currency code "XYZ"
Then I see an error message indicating the currency is not valid

Given I am on the invoices page
When I filter by a valid currency that has no invoices
Then I see an empty list with no error

Given I am on the invoices page
When I select a currency filter
And I have pagination or date range filters active
Then both filters are applied together
```

**Implementation plan (posted as comment):**
```
[HRZN-712] Allow partners to filter invoices by currency | 3pts | 10/12 High

Repositories: pax8 (monolith)

Acceptance Criteria:
- [ ] GET /invoices?currency=USD returns only invoices with currency USD
- [ ] Omitting the currency param returns all invoices (filter is optional)
- [ ] Invalid currency code (e.g. "XYZ") returns 400 Bad Request with error message
- [ ] Valid currency with no matching invoices returns 200 with empty list
- [ ] Filter works alongside existing pagination and date range params

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

Test Scenarios:
  Happy path:
  - Filter by valid currency code (USD) → returns only USD invoices
  - Omit currency param → returns all invoices unchanged
  Error path:
  - Filter by invalid currency code "XYZ" → 400 Bad Request
  - Filter by empty string → 400 Bad Request
  Boundary:
  - Valid currency with zero matching invoices → 200 with empty list
  - Currency param combined with existing pagination → both filters applied correctly

Dependencies: none
Risks: none identified
```

## Error Handling

### MCP Not Available

**If Atlassian MCP is not enabled:**

Present options using AskQuestion:
```
The Atlassian MCP (e.g. plugin-atlassian-atlassian) doesn't appear to be enabled. 
This skill uses it to fetch Jira tickets and post comments automatically.

How would you like to proceed?
1. Enable the MCP - I'll wait while you enable the Atlassian integration in Cursor settings
2. Provide ticket manually - Paste the Jira ticket content and I'll continue
3. Skip Jira integration - I'll generate the implementation plan as markdown for you to copy
```

**If user chooses manual input:**
- Ask for: Ticket ID, Title, Description, Acceptance Criteria, Epic/PRD link
- Continue with refinement process using provided content
- At output phase, generate markdown instead of posting to Jira

### Jira Fetch Fails

If `getJiraIssue` returns an error:
- Display the error message
- Ask user to paste ticket details manually
- Continue with refinement process

### Jira Description Update Fails

If `editJiraIssue` returns an error when updating the description:
- Display the error message
- If the error states the field must be an **Atlassian Document**, rebuild the payload as ADF (see [Jira Standards](../../rules/jira-standards.md)) and retry; `customfield_12636` on Stories typically requires this
- Otherwise present the full description content (all three panels) as formatted markdown for manual paste
- Instruct: "Copy the Success Criteria section and paste it into the ticket description's Success Criteria panel on [ticket-key]"
- Continue to post the comment (Step 2) regardless — the comment is independent

### Jira Comment Post Fails

If `addCommentToJiraIssue` returns an error:
- Display the error message
- Present the implementation plan as formatted markdown
- Instruct: "Copy the above and paste it as a comment on [ticket-key]"

### PRD Not Found

If no PRD link is found in the Epic description, or the Confluence page fetch fails:
- Check both `customfield_12637` and `description` on the Epic before giving up
- If the Epic itself has no description content, note this explicitly
- Note that PRD context is missing
- Reduce confidence score for Requirements by 1 point
- Ask user if they can provide a PRD link or paste the PRD content directly

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
