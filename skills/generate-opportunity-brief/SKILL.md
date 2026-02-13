---
name: generate-opportunity-brief
description: Draft a Pax8 Opportunity Brief for a feature idea, enriched with Engineering Codex insights about user flows, risks, and best practices. Use when the user has a feature idea, wants to write an opportunity brief, or needs to document a proposal before PRD creation.
---
# Generate Opportunity Brief Skill

Draft a Pax8 Opportunity Brief for a feature idea, enriched with Engineering Codex insights about user flows, risks, and best practices.

## Prerequisites

### Required MCP Servers

| MCP Server | Tools Used | Purpose | Required? |
|------------|------------|---------|-----------|
| **user-mcp-atlassian** | `confluence_get_page` | Fetch Opp Brief template from Confluence | Optional |
| | `confluence_search` | Search for existing briefs | Optional |

### Engineering Codex

This skill reads from the Engineering Codex repository for technical context. If `@engineering-codex` is in your workspace, the skill will automatically pull relevant content. If not, it will proceed with general best practices.

## When to Use

- You have a feature idea and need to draft an Opportunity Brief for Pax8's Engineering Operations process
- You want to ensure your brief considers user experience patterns, technical risks, and architectural implications
- You need to align your feature proposal with Engineering Codex best practices
- **First step** in the idea-to-implementation flow

## Invocation

```
@workspace-standards/skills/generate-opportunity-brief/SKILL.md Generate an opportunity brief for [feature idea]
```

Or with context:
```
@workspace-standards/skills/generate-opportunity-brief/SKILL.md Generate an opportunity brief for a new payment method feature, targeting enterprise customers
```

## Workflow

### Phase 1: Gather Feature Context

1. Ask the user for essential information using AskQuestion:
   - **Feature idea**: What is the core feature or capability you're proposing?
   - **Target users**: Who will use this feature? (e.g., end users, internal teams, partners)
   - **Strategic alignment**: How does this align with Pax8's strategic goals?
   - **Known constraints**: Are there any technical, timeline, or resource constraints?
   - **Executive Sponsor**: Who is the executive sponsor for this opportunity?
   - **Idea Owner**: Who owns this idea?
   - **Requesting Department**: Which department is requesting this?

2. Capture the responses for use in the brief

### Phase 2: Identify Relevant Codex Content

If `@engineering-codex` is available in the workspace:

1. Map the feature to relevant Engineering Codex facets and experiences:
   - Use the feature description to identify facets (e.g., authentication, api-design, state-management)
   - Identify user experiences that apply (e.g., forms-and-data-entry, search-and-discovery)

2. Read relevant `product.md` files from `@engineering-codex/facets/` and `@engineering-codex/experiences/`:
   - Extract user flow patterns
   - Identify KPIs and success metrics
   - Note product considerations

3. Read relevant `gotchas.md` files:
   - Identify technical risks
   - Note common pitfalls to address in the brief

4. Read relevant `architecture.md` files if architectural implications are significant

If codex is not available, note this and proceed with the user's input alone.

### Phase 3: Draft the Opportunity Brief

Fill in the Pax8 Opportunity Brief template structure:

```markdown
# Opportunity Brief: [Feature Name]

## Metadata
- **Executive Sponsor**: [Name]
- **Idea Owner**: [Name]
- **Requesting Department**: [Department]
- **Date**: [Current Date]
- **Status**: Draft

## Problem Alignment

[Describe the problem this feature addresses, informed by user input and codex product perspectives]

### User Impact
[Who is affected and how, based on target users identified]

### Business Impact
[Strategic alignment and business value]

## Hypothesis

**If** we [build/implement/change] [feature/component/capability],
**then** [expected outcome/behavior],
**because** [rationale/assumption].

[Informed by codex product.md user flow patterns and best practices]

## Projected ROI

### Benefits
- [Quantified benefit 1] — [Source/assumption]
- [Quantified benefit 2] — [Source/assumption]

### Costs
- [Estimated cost 1] — [Source/assumption]
- [Estimated cost 2] — [Source/assumption]

### ROI Calculation
[If user provides estimates, structure them here]

## Technical Considerations

### Relevant Facets
- [Facet 1]: [Brief note on relevance]
- [Facet 2]: [Brief note on relevance]

### Key Risks (from Codex Gotchas)
- [Risk 1 from gotchas.md] — [Mitigation approach]
- [Risk 2 from gotchas.md] — [Mitigation approach]

### Architecture Implications
[If applicable, note significant architectural considerations from codex]

## Next Steps

1. [Next step 1]
2. [Next step 2]
```

**Note**: The full Pax8 template is at: https://pax8.atlassian.net/wiki/spaces/EO/pages/2446131237

### Phase 4: Review and Refine

1. Present the draft Opportunity Brief to the user
2. Ask for feedback on problem alignment, hypothesis clarity, ROI estimates, missing considerations
3. Iterate based on feedback

### Phase 5: Output

Ask the user how they'd like to save:

```
How would you like to save this Opportunity Brief?
1. Save as markdown file
2. Create Confluence page (if Confluence MCP available)
3. Display for manual copy
4. Proceed directly to PRD generation (if approved)
```

If the user chooses option 4, hand off to the Generate PRD skill.

## Graceful Degradation

| Dependency | If Missing |
|-----------|-----------|
| Engineering Codex | Proceed without technical enrichment; note in the brief |
| Confluence MCP | Save as markdown instead of creating Confluence page |

## Related Resources

- [Generate PRD Skill](../generate-prd/SKILL.md) — Next step after approval
- [Idea to Implementation Skill](../idea-to-implementation/SKILL.md) — Full pipeline orchestrator
- [Engineering Codex](../../engineering-codex/) — Technical knowledge base (if in workspace)
