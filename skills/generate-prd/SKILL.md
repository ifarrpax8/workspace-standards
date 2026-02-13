---
name: generate-prd
description: Draft a Pax8 Product Requirements Document from an approved Opportunity Brief, enriched with Engineering Codex technical insights, ADR standards, and best practices. Use when the user wants to create a PRD, write product requirements, or document feature specifications.
---
# Generate PRD Skill

Draft a Pax8 Product Requirements Document from an approved Opportunity Brief, enriched with Engineering Codex technical insights, Pax8 ADR standards, and best practices.

## Prerequisites

### Required MCP Servers

| MCP Server | Tools Used | Purpose | Required? |
|------------|------------|---------|-----------|
| **user-mcp-atlassian** | `confluence_get_page` | Fetch PRD template or Opp Brief from Confluence | Optional |
| | `jira_search` | Find related existing tickets | Optional |

### Engineering Codex

This skill reads extensively from the Engineering Codex for technical context, risk identification, and decision frameworks. If `@engineering-codex` is in your workspace, the skill will pull from facets, experiences, and Pax8 standards. If not, it will produce a less enriched PRD from user input alone.

## When to Use

- You have an approved Opportunity Brief and need to create a PRD
- You want to ensure your PRD considers Pax8 standards, technical risks, and architectural decisions
- **Second step** in the idea-to-implementation flow (after Opp Brief)

## Invocation

```
@workspace-standards/skills/generate-prd/SKILL.md Generate a PRD from this opportunity brief: [paste or reference]
```

Or:
```
@workspace-standards/skills/generate-prd/SKILL.md Generate PRD for [feature name]
```

## Workflow

### Phase 1: Load Opportunity Brief

1. Ask the user to provide their approved Opportunity Brief:
   - Accept markdown content directly
   - Accept a file path reference
   - Accept a Confluence page link (if Confluence MCP available)

2. Extract key information: problem statement, hypothesis, ROI, target users, strategic alignment

3. Confirm the brief is approved

### Phase 2: Identify Technical Scope

If `@engineering-codex` is available:

1. Map the feature to relevant facets and experiences
2. Read relevant files:
   - `product.md` — user flows, KPIs, success metrics
   - `gotchas.md` — risks and pitfalls
   - `architecture.md` — system design considerations
   - `options.md` — decision points that need to be made
3. Identify cross-facet dependencies from synergy sections

### Phase 3: Check Pax8 Standards

If `@engineering-codex/pax8-context/` is available:

1. Read `standards-map.md` and filter for relevant facets
2. Identify Standards (already decided) and Guidance (recommended)
3. Read `deprecated.md` for technologies to avoid
4. Pre-fill technology decisions where Pax8 has already decided

### Phase 4: Draft PRD Sections

```markdown
# Product Requirements Document: [Feature Name]

## Metadata
- **Opportunity Brief**: [Link or reference]
- **Product Owner**: [Name]
- **Engineering Lead**: [Name]
- **Date**: [Current Date]
- **Status**: Draft
- **Version**: 1.0

## Problem Alignment

[Carried from Opportunity Brief]

### User Problem
[Restate from Opp Brief]

### Business Problem
[Restate from Opp Brief]

## Expected Outcomes

### Must Have
[Core requirements, informed by codex best practices]

### Nice to Have
[Enhancements that improve the experience]

### Out of Scope
[Explicitly excluded items]

## Success Metrics

### Primary Metrics
- [Metric 1]: [Target] — [Measurement method]

### Secondary Metrics
- [Metric 2]: [Target]

## User Stories

[Structured user stories informed by codex product.md user flows]

## Technical Requirements

### Architecture Considerations
[From codex architecture.md files]

### Integration Points
[Systems that need to integrate]

### Performance Requirements
[If applicable, from codex performance facet]

### Security Requirements
[If applicable, from codex security facet]

## Risks

### Technical Risks
- **[Risk from gotchas.md]** — [Likelihood] — [Impact] — [Mitigation]

### Product Risks
- **[Risk]** — [Likelihood] — [Impact] — [Mitigation]

### Dependencies
- **[Dependency]** — [Description] — [Status]

## Significant Decisions

### Decisions Already Made (Pax8 Standards)
- **[Decision]** — [Pax8 Standard: ADR-XXXXX] — [Summary]

### Decisions Needed
- **[Decision 1]** — See: `@engineering-codex/facets/[facet]/options.md`

## Design & Technical Artifacts

### Required
- [ ] [Artifact 1] — [Rationale]

### Recommended
- [ ] [Artifact 2] — [Rationale]

## Open Questions

[Questions that need answers before development]

## Spike Candidates

[Technical unknowns that may require a spike before implementation]
- **[Unknown 1]** — [Why it needs investigation] — [Suggested scope]
```

**Note**: The full Pax8 template is at: https://pax8.atlassian.net/wiki/spaces/EO/pages/2446327849

### Phase 5: Review and Refine

1. Present draft, ask for feedback
2. Iterate on completeness, accuracy, clarity
3. Ensure all sections are complete

### Phase 6: Output and Next Steps

Ask the user:

```
How would you like to proceed?
1. Save PRD as markdown file
2. Create Confluence page (if MCP available)
3. Display for manual copy
4. Create spike tickets for open unknowns (hand off to Spike skill)
5. Break down into stories for refinement (hand off to story breakdown)
```

If spike candidates exist, suggest creating spike tickets.
If ready for implementation, suggest story breakdown and refinement.

## Graceful Degradation

| Dependency | If Missing |
|-----------|-----------|
| Engineering Codex | Produce PRD from user input; note reduced technical enrichment |
| Pax8 Context | Skip Pax8 standards section; note decisions need evaluation |
| Confluence MCP | Save as markdown instead |
| Jira MCP | Skip related ticket search |

## Related Resources

- [Generate Opportunity Brief Skill](../generate-opportunity-brief/SKILL.md) — Previous step
- [Spike Skill](../spike/SKILL.md) — For technical unknowns identified in the PRD
- [Refine Ticket Skill](../refine-ticket/SKILL.md) — For refining stories from the PRD
- [Idea to Implementation Skill](../idea-to-implementation/SKILL.md) — Full pipeline orchestrator
