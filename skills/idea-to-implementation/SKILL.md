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

## Invocation

```
@workspace-standards/skills/idea-to-implementation/SKILL.md I have a feature idea: [brief description]
```

Or to resume at a specific stage:
```
@workspace-standards/skills/idea-to-implementation/SKILL.md Resume from PRD for [feature name]
```

Or to skip early stages:
```
@workspace-standards/skills/idea-to-implementation/SKILL.md I already have a PRD, let's break it down into stories
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
                                      ┌──────────────┐
                                      │  6. Refine   │
                                      │  Each Story  │
                                      └──────────────┘
                                             │
                                             ▼
                                      ┌──────────────┐
                                      │ 7. Implement │
                                      │  First Story │
                                      └──────────────┘
```

Each stage is a checkpoint — the user can pause, review, and resume later.

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

1. Invoke `@workspace-standards/skills/generate-opportunity-brief/SKILL.md` with the idea context
2. The skill gathers metadata, enriches with codex content, and drafts the brief
3. Review and iterate with the user

**Output**: Completed Opportunity Brief (markdown or Confluence page)

**Checkpoint**: "Is this brief approved? Ready to generate the PRD?"

> If the user needs approval from stakeholders first, pause here. They can resume later with "Resume from PRD for [feature name]".

### Stage 3: PRD Generation

Hand off to the **Generate PRD** skill:

1. Invoke `@workspace-standards/skills/generate-prd/SKILL.md` with the approved Opp Brief
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
   - Invoke `@workspace-standards/skills/spike/SKILL.md` with the spike ticket
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
   2. Create them in Jira now
   3. Save as markdown for manual creation
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
   - Invoke `@workspace-standards/skills/refine-ticket/SKILL.md` with the story ticket
   - The skill runs Three Amigos analysis, calculates confidence score, generates implementation plan

2. If confidence is low, the Refine Ticket skill will suggest a Technical Deep Dive

3. Repeat for each story in the sprint batch (typically 2-4 stories)

**Output**: Refined stories with implementation plans, confidence scores, and estimates

**Checkpoint**: "First story refined and ready. Want to start implementing?"

### Stage 7: Implement First Story

Hand off to the **Implement Ticket** skill:

1. Invoke `@workspace-standards/skills/implement-ticket/SKILL.md` with the first refined story
2. The skill validates DoR, loads standards, creates branch, implements with TDD
3. Self-review and DoD gate

**Output**: Implemented story with tests, ready for PR

**Final**: "First story implemented! Continue with the next story using the Implement Ticket skill."

## Resuming Mid-Pipeline

The user can resume at any stage by providing context:

| Resume Command | What It Does |
|------|------|
| "I have a feature idea: [X]" | Start from Stage 1 |
| "Resume from PRD for [feature]" | Skip to Stage 3 with existing Opp Brief |
| "I already have a PRD, break it down" | Skip to Stage 5 with existing PRD |
| "Refine ticket HRZN-123" | Jump directly to Stage 6 |
| "Implement ticket HRZN-123" | Jump directly to Stage 7 |

## Progress Tracking

At each checkpoint, display progress:

```
Feature: [Feature Name]
Pipeline Progress: ██████░░░░ Stage 3 of 7

✅ Stage 1: Idea Captured
✅ Stage 2: Opp Brief — [saved location]
🔄 Stage 3: PRD Generation — in progress
⬜ Stage 4: Spike Investigation
⬜ Stage 5: Story Breakdown
⬜ Stage 6: Refinement
⬜ Stage 7: Implementation
```

## Graceful Degradation

| Missing | Impact | Fallback |
|---------|--------|----------|
| Engineering Codex | Reduced technical enrichment in Opp Brief and PRD | Proceed with user input; note reduced context |
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
- [Technical Deep Dive](../technical-deep-dive/SKILL.md) — Called during refinement if needed
- [Engineering Codex](https://github.com/ifarrpax8/engineering-codex) — Technical knowledge base
