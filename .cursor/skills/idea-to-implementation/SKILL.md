---
name: idea-to-implementation
description: End-to-end orchestrator from idea through PRD, spike, story breakdown, refinement, and implementation.
complexity: high
prompt-version: "1.0"
---
# Idea to Implementation Skill

End-to-end orchestrator that guides a feature from initial idea through Opportunity Brief, PRD, spike investigation, story breakdown, refinement, and implementation. Each phase hands off to the appropriate skill, with checkpoints between stages.

## Prerequisites

### Required MCP Servers

| MCP Server | Tools Used | Purpose | Required? |
|------------|------------|---------|-----------|
| **user-mcp-atlassian** | `jira_*` | Create/update tickets, post comments | Recommended |
| | `confluence_*` | Fetch templates, create pages | Optional |
| **user-github** | `search_code`, `get_file_contents` | Codebase patterns during spike/implementation | Optional |

### Workspace Requirements

| Repository | Purpose | Required? |
|-----------|---------|-----------|
| **workspace-standards** | Skills, rules, golden paths | Required |
| **engineering-codex** | Best practices, facets, Pax8 standards, tech radar | Recommended |
| **adr** | Pax8 ADR repository for standards context | Optional |
| **Target repository** | The codebase being implemented against | Required for implementation |

## When to Use

- Starting a brand new feature from an idea
- Demonstrating the full engineering workflow
- Onboarding someone to how Pax8 takes ideas from inception to delivery
- You want a guided flow and don't want to remember which skill to invoke next

## When NOT to Use

- **Ticket already exists and is refined** — jump directly to [Implement Ticket](../implement-ticket/SKILL.md)
- **Just need to refine a single ticket** — use [Refine Ticket](../refine-ticket/SKILL.md) directly
- **Quick bug fix or small change** — use [Fix Bug](../fix-bug/SKILL.md) or implement directly
- **Research/spike only** — use [Spike](../spike/SKILL.md) without the full pipeline

## Invocation

```
@workspace-standards/.cursor/skills/idea-to-implementation/SKILL.md I have a feature idea: [brief description]
```

Or to resume at a specific stage:
```
@workspace-standards/.cursor/skills/idea-to-implementation/SKILL.md Resume from PRD for [feature name]
```

Or to skip early stages:
```
@workspace-standards/.cursor/skills/idea-to-implementation/SKILL.md I already have a PRD, let's break it down into stories
```

## Pipeline Overview

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   1. Idea    │───▶│  2. Opp      │───▶│   3. PRD     │
│   Capture    │    │   Brief      │    │  Generation  │
└──────────────┘    └──────────────┘    └──────────────┘
                                               │
                         ┌─────────────────────┤
                         │                     │
                         ▼                     ▼
                  ┌──────────────┐    ┌──────────────┐
                  │  4. Spike    │    │  5. Story    │
                  │  (if needed) │───▶│  Breakdown   │
                  └──────────────┘    └──────────────┘
                                             │
                                             ▼
                  ┌──────────────┐    ┌──────────────┐
                  │ 7. Implement │◀───│  6. Refine   │
                  │  First Story │    │  Each Story  │
                  └──────────────┘    └──────────────┘
                         │
                         ▼
                  ┌──────────────┐    ┌──────────────┐
                  │  8. Assess   │───▶│  9. Code     │
                  │  Tests       │    │  Review      │
                  └──────────────┘    └──────────────┘
                                             │
                                             ▼
                                      ┌──────────────┐
                                      │ 10. Post-    │
                                      │  Impl Review │
                                      └──────────────┘
```

Each stage is a checkpoint — the user can pause, review, and resume later. Stage 9 runs after the PR is created, stage 10 after merge and deploy.

## Workflow

### Stage 1: Idea Capture

Lightweight — just enough context to start:

1. Ask the user to describe their idea in 2-3 sentences
2. Ask clarifying questions:
   - Who is this for? (user persona)
   - What problem does it solve?
   - Is this a new feature, enhancement to existing, or replacement?
3. Confirm readiness to proceed to Opportunity Brief

**Output**: Feature idea summary

**Checkpoint**: "Ready to draft the Opportunity Brief?"

### Stage 2: Opportunity Brief

Hand off to the **Generate Opportunity Brief** skill:

1. Invoke `@workspace-standards/.cursor/skills/generate-opportunity-brief/SKILL.md` with the idea context
2. The skill gathers metadata, enriches with codex content, and drafts the brief
3. Review and iterate with the user

**Output**: Completed Opportunity Brief (markdown or Confluence page)

**Checkpoint**: "Is this brief approved? Ready to generate the PRD?"

> If the user needs approval from stakeholders first, pause here. They can resume later with "Resume from PRD for [feature name]".

### Stage 3: PRD Generation

Hand off to the **Generate PRD** skill:

1. Invoke `@workspace-standards/.cursor/skills/generate-prd/SKILL.md` with the approved Opp Brief
2. The skill maps to codex facets, checks Pax8 standards, identifies decisions and risks
3. Review and iterate

**Output**: Completed PRD with decisions, risks, and spike candidates

**Decision Point**: Check if spikes are needed:

```
The PRD identifies these unknowns that may need investigation:
1. [Unknown 1] — [brief description]
2. [Unknown 2] — [brief description]

How would you like to proceed?
1. Create spike tickets and investigate before continuing
2. Proceed to story breakdown (accept the risk of unknowns)
3. Investigate one specific unknown now, create tickets for the rest
```

### Stage 4: Spike Investigation (if needed)

For each unknown that needs investigation:

1. Create a spike ticket in Jira (if MCP available):
   - Type: Spike
   - Summary: "[Feature Name] Spike: [Unknown Description]"
   - Link to PRD
   - Success criteria defined
   - Time-box specified

2. If the user wants to investigate now, hand off to the **Spike** skill:
   - Invoke `@workspace-standards/.cursor/skills/spike/SKILL.md` with the spike ticket
   - The skill investigates, documents findings, and posts to Jira

3. Feed spike findings back into the PRD:
   - Update decisions based on spike outcomes
   - Resolve open questions
   - Adjust scope if needed

**Output**: Spike findings, updated PRD

**Checkpoint**: "All unknowns resolved? Ready to break down into stories?"

### Stage 5: Story Breakdown

Turn the PRD into implementable stories:

1. Read the PRD's "Must Have" and "Nice to Have" sections
2. For each requirement, create a story:
   - **Summary**: Clear, action-oriented title
   - **Description**: User story format ("As a [persona], I want to [action], so that [benefit]")
   - **Acceptance Criteria**: Derived from PRD requirements + codex `testing.md` and `best-practices.md`
   - **Technical Notes**: Architecture decisions, integration points, Pax8 standards to follow
   - **Estimated Complexity**: T-shirt size (S/M/L) based on scope
   - **Dependencies**: Other stories that must complete first

3. Order stories by dependency and priority:
   - Infrastructure/foundation stories first
   - Core feature stories next
   - Enhancement stories last
   - Nice-to-haves at the end

4. If Jira MCP is available, offer to create the stories:
   ```
   I've drafted [N] stories. Would you like to:
   1. Review them all before creating in Jira
   2. Create them in Jira (requires confirmation)
   3. Save as markdown for manual creation
   ```

   If the user chooses option 2, display the full story list and ask for explicit confirmation before calling the Jira MCP:
   ```
   Here are the [N] stories I'll create in Jira. Please review:

   [story list]

   Shall I create these in Jira? (yes / edit first / skip)
   ```

5. If creating in Jira:
   - Create an Epic: "[Feature Name]"
   - Create stories linked to the Epic
   - Set story order based on dependency analysis

**Output**: Ordered list of stories with acceptance criteria

**Checkpoint**: "Stories created. Ready to refine the first story?"

### Stage 6: Refine Stories

For each story (starting with the first):

1. Hand off to the **Refine Ticket** skill:
   - Invoke `@workspace-standards/.cursor/skills/refine-ticket/SKILL.md` with the story ticket
   - The skill runs Three Amigos analysis, calculates confidence score, generates implementation plan

2. If confidence is low, the Refine Ticket skill will suggest a Technical Deep Dive

3. Repeat for each story in the sprint batch (typically 2-4 stories)

**Output**: Refined stories with implementation plans, confidence scores, and estimates

**Checkpoint**: "First story refined and ready. Want to start implementing?"

### Stage 7: Implement First Story

Hand off to the **Implement Ticket** skill:

1. Invoke `@workspace-standards/.cursor/skills/implement-ticket/SKILL.md` with the first refined story
2. The skill validates DoR, loads standards, creates branch, implements with TDD
3. Self-review and DoD gate

**Output**: Implemented story with tests, ready for PR

**Checkpoint**: "Implementation complete. Ready to create the PR and run code review?"

### Stage 8: Assess Tests

After implementation, run a quick test completeness check before code review:

1. Invoke `@workspace-standards/.cursor/skills/assess-tests/SKILL.md` scoped to the services changed in Stage 7
2. The skill inventories test files, maps them to the test pyramid, and checks persona coverage
3. Identify any persona gaps (especially Saboteur and Boundary Walker) and suggest tests to add

**Decision Point**:

```
Test assessment found these gaps:
1. [Missing Saboteur test for X]
2. [No Boundary Walker coverage on Y]

How would you like to proceed?
1. Add the missing tests now (before code review)
2. Note them as follow-up work
3. They're acceptable — skip to code review
```

If the user chooses to add tests, return to the implementation context and add them before proceeding.

**Output**: Test completeness report with any gaps addressed or acknowledged

**Checkpoint**: "Tests assessed. Ready for code review?"

### Stage 9: Code Review

Hand off to review and PR skills:

1. Run **pre-qodo review** on your **local changes** (optional ticket key for AC alignment; **no push or PR required** — loads pr-agent-settings paths + Pax8 rules):
   - Invoke `@workspace-standards/.cursor/skills/pre-qodo-review/SKILL.md` with or without the ticket key
   - Fix any MUST FIX issues identified

2. Generate the PR description and open the PR:
   - Invoke `@workspace-standards/.cursor/skills/generate-pr-description/SKILL.md` to create a structured PR description from the implementation context
   - Create or update the PR via GitHub MCP (if available)

3. Run the **code review** skill if you want a **Pax8-only** pass without loading pr-agent-settings paths (optional; often redundant if step 1 covered the diff):
   - Invoke `@workspace-standards/.cursor/skills/code-review/SKILL.md` against local diff, branch, or PR
   - The skill applies the team's standards checklist, golden paths, and codex best practices
   - Fix any MUST FIX issues identified

4. Once the review is clean, the PR is ready for human review and merge

**Output**: PR with structured description, self-reviewed against standards

**Checkpoint**: "PR created and self-reviewed. Once merged and deployed, run a post-implementation review (Stage 10)."

### Stage 10: Post-Implementation Review

After the PR is merged and deployed, close the feedback loop:

1. Invoke `@workspace-standards/.cursor/skills/post-implementation-review/SKILL.md` with the ticket
2. The skill compares estimates vs actuals, captures learnings, and identifies process improvements
3. Post the review to Jira

**Output**: Post-implementation review with estimate accuracy, learnings, and action items

**Final**: "Feature complete — from idea to delivery with learnings captured (including test persona coverage). Continue with the next story, or start a new feature."

## Resuming Mid-Pipeline

The user can resume at any stage by providing context:

| Resume Command | What It Does |
|------|------|
| "I have a feature idea: [X]" | Start from Stage 1 |
| "Resume from PRD for [feature]" | Skip to Stage 3 with existing Opp Brief |
| "I already have a PRD, break it down" | Skip to Stage 5 with existing PRD |
| "Refine ticket HRZN-123" | Jump directly to Stage 6 |
| "Implement ticket HRZN-123" | Jump directly to Stage 7 |
| "Assess tests for HRZN-123" | Jump directly to Stage 8 |
| "Review PR for HRZN-123" | Jump directly to Stage 9 |
| "Pre-qodo review HRZN-123" | Jump directly to Stage 9 (run pre-qodo-review first) |
| "Post-implementation review for HRZN-123" | Jump directly to Stage 10 |

## Progress Tracking

At each checkpoint, display progress:

```
Feature: [Feature Name]
Pipeline Progress: ███░░░░░░░░ Stage 3 of 10

✅ Stage 1: Idea Captured
✅ Stage 2: Opp Brief — [saved location]
🔄 Stage 3: PRD Generation — in progress
⬜ Stage 4: Spike Investigation
⬜ Stage 5: Story Breakdown
⬜ Stage 6: Refinement
⬜ Stage 7: Implementation
⬜ Stage 8: Assess Tests
⬜ Stage 9: Code Review
⬜ Stage 10: Post-Implementation Review
```

## Verification

At each stage transition, verify the previous stage completed successfully:

- **Stage 2 → 3**: Confirm the Opportunity Brief was reviewed and approved by the user before generating the PRD.
- **Stage 5 → 6**: Confirm stories were created (in Jira or as markdown) and the user selected which to refine first.
- **Stage 7 → 8**: Confirm implementation is complete (tests passing, DoD met) before running test assessment.
- **Stage 9 → 10**: Confirm the PR was created and merged before running post-implementation review.

If any verification fails, pause and present the status to the user rather than proceeding with incomplete input.

## Worked Example

**Input:** `I have a feature idea: Allow partners to download invoice PDFs in bulk`

**Key steps (condensed across stages):**
1. **Idea Capture**: Captured idea — for partner admins, bulk PDF download from invoice list
2. **Opp Brief**: Generated brief linking to billing domain, estimated medium complexity
3. **PRD**: Generated PRD with 3 must-haves, 1 nice-to-have. Spike needed: PDF generation at scale
4. **Spike**: Investigated PDF libraries, recommended async generation with S3 storage
5. **Story Breakdown**: Created 4 stories in Epic HRZN-800: API endpoint, PDF generator service, async job processor, MFE download button
6. **Refine**: First story (API endpoint) scored 10/12, estimated 3 points
7. **Implement**: TDD implementation, 4 tests, 1 unknown (S3 presigned URL expiry) resolved inline
8. **Assess Tests**: Found Boundary Walker gap — no test for zero invoices selected
9. **Code Review**: Clean after adding boundary test. PR created.
10. **PIR**: Estimate accurate, learned to include async patterns in refinement

**Progress tracker:**
```
Feature: Bulk Invoice PDF Download
Pipeline Progress: ██████████ Stage 10 of 10 — Complete
```

## Graceful Degradation

| Missing | Impact | Fallback |
|---------|--------|----------|
| Engineering Codex | Reduced technical enrichment in Opp Brief, PRD, and test persona coverage | Proceed with user input; note reduced context |
| Pax8 Context / ADRs | No pre-filled Pax8 standards in PRD | List all decisions as "needs evaluation" |
| Jira MCP | Cannot create tickets automatically | Generate markdown for manual creation |
| Confluence MCP | Cannot fetch templates or create pages | Use embedded templates; save as markdown |
| Target repository | Cannot implement | Stop at Stage 6 (refinement) |

## Related Resources

- [Generate Opportunity Brief](../generate-opportunity-brief/SKILL.md) — Stage 2
- [Generate PRD](../generate-prd/SKILL.md) — Stage 3
- [Spike Skill](../spike/SKILL.md) — Stage 4
- [Refine Ticket Skill](../refine-ticket/SKILL.md) — Stage 6
- [Implement Ticket Skill](../implement-ticket/SKILL.md) — Stage 7
- [Assess Tests Skill](../assess-tests/SKILL.md) — Stage 8 (test completeness gate)
- [Generate PR Description](../generate-pr-description/SKILL.md) — Stage 9 (PR creation)
- [Pre-Qodo Review Skill](../pre-qodo-review/SKILL.md) — Stage 9 (local diff; optional ticket; Qodo paths + Pax8)
- [Code Review Skill](../code-review/SKILL.md) — Stage 9 (self-review)
- [Post-Implementation Review](../post-implementation-review/SKILL.md) — Stage 10
- [Technical Deep Dive](../technical-deep-dive/SKILL.md) — Called during refinement if needed
- [Generate ADR](../generate-adr/SKILL.md) — Called during spike if architecture decision needed
- [Engineering Codex](https://github.com/ifarrpax8/engineering-codex) — Technical knowledge base
