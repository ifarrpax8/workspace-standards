# Refinement Best Practices

Comprehensive guide for refining Jira tickets using the Three Amigos approach, ensuring work is well-defined before sprint commitment.

## Three Amigos Overview

The Three Amigos approach brings together three perspectives to ensure comprehensive understanding of any piece of work:

### Developer Perspective

Focus areas:
- **Technical feasibility**: Can this be built with our current stack and constraints?
- **Architecture impact**: Does this require new patterns or affect existing architecture?
- **Implementation approach**: What's the recommended technical solution?
- **Effort estimation**: How complex is the implementation?
- **Dependencies**: What other systems or teams are involved?

Questions to ask:
- Is there existing code we can reference or extend?
- Does this follow our golden path architecture?
- What are the rollback/recovery options if something goes wrong?
- Should this be feature-flagged for gradual rollout?

### Test Perspective

Focus areas:
- **Test scenarios**: What needs to be tested (happy paths, edge cases)?
- **Boundary conditions**: What are the limits and how should they behave?
- **Regression risk**: What existing functionality could be affected?
- **Test types**: What combination of unit, integration, E2E tests is needed?
- **Test data**: What data setup is required?

Questions to ask:
- What happens when input is null, empty, or at maximum values?
- How should the system behave under error conditions?
- What permissions/authorization scenarios need testing?
- Are there performance thresholds to verify?

### Product Perspective

Focus areas:
- **User value**: Why does this matter to users?
- **Acceptance criteria**: What defines "done" from a user perspective?
- **Business context**: How does this fit into the larger product vision?
- **Priority**: How important is this relative to other work?
- **Success metrics**: How will we know this was successful?

Questions to ask:
- Who is the primary user for this feature?
- What existing functionality should this integrate with?
- Are there any constraints (legal, compliance, business rules)?
- What's the minimum viable implementation?

### When to Involve Additional Personas

| Persona | Involve When |
|---------|--------------|
| **UX/Design** | UI changes, new user flows, accessibility concerns |
| **Security** | Authentication, authorization, data handling, PII |
| **DevOps** | Infrastructure changes, deployment requirements, monitoring |
| **Data** | Database schema changes, data migrations, analytics |

## Definition of Ready (DoR) Checklist

A ticket is ready for sprint commitment when all items are checked:

### Requirements
- [ ] User story follows format: "As a [role], I want [goal], so that [benefit]"
- [ ] Acceptance criteria are specific, measurable, and testable
- [ ] Edge cases and error scenarios are documented
- [ ] PRD is linked (via Epic)

### Technical
- [ ] Technical approach is agreed by the team
- [ ] Affected codebases are identified
- [ ] Dependencies are identified and unblocked (or mitigation plan exists)
- [ ] No open questions blocking implementation

### Testing
- [ ] Test scenarios documented (happy path + unhappy paths)
- [ ] Test type recommendations identified (unit, integration, E2E)
- [ ] Test data requirements understood

### Estimation
- [ ] Fibonacci estimate agreed by team
- [ ] Confidence score is Medium or High (7+ out of 12)

## Async Refinement Guidelines

### How to Structure Async Refinement

1. **Initial Post**: Developer or Product posts ticket in refinement channel with key questions
2. **Perspective Responses**: Each persona adds their analysis within SLA
3. **Consolidation**: Facilitator consolidates feedback, identifies conflicts
4. **Resolution**: Sync discussion only if conflicts exist or confidence is low
5. **Finalization**: Update Jira with refinement summary

### Response SLAs

| Persona | Expected Response Time |
|---------|----------------------|
| Product | 4 hours (clarifications) |
| Developer | 8 hours (technical analysis) |
| Test | 8 hours (test scenarios) |

### When to Escalate to Synchronous Discussion

- Confidence score below 7/12
- Conflicting views on technical approach
- Significant architecture decisions needed
- Multiple dependencies with unknowns
- Scope disagreement between personas

### Capturing Decisions in Jira

All refinement discussions should result in:
1. Updated acceptance criteria (if gaps found)
2. Implementation plan comment
3. Test scenarios comment
4. Resolved questions documented

## Multi-Codebase Work Patterns

### Standard Pairings

| Frontend MFE | Backend Service | Domain |
|--------------|-----------------|--------|
| `finance-mfe` | `invoice-service`, `payment-service` | Finance |
| `order-management-mfe` | `order-service` | Orders |

### Structuring Work Spanning BE + FE

For tickets requiring both backend and frontend changes:

1. **Single Ticket** (Preferred when):
   - Changes are tightly coupled
   - Same developer will implement both
   - Combined effort is ≤ 8 story points

2. **Split Tickets** (Preferred when):
   - Changes can be deployed independently
   - Different developers will implement
   - Combined effort exceeds 8 story points
   - Backend needs to be released first for API availability

### Implementation Plan Format for Multi-Codebase

```markdown
## Affected Codebases

### Backend (service-name)
- **Files**: `src/endpoint/...`, `src/service/...`
- **Changes**: [Description]
- **Deploy first**: Yes/No

### Frontend (mfe-name)
- **Files**: `src/components/...`, `src/services/...`
- **Changes**: [Description]
- **Depends on backend**: Yes/No
```

## Test Scenario Guidelines

### Happy Path Definition

The primary success scenario that delivers the core user value:
- User performs the expected action
- System responds with expected result
- No errors or edge cases

### Edge Cases to Always Consider

| Category | Scenarios |
|----------|-----------|
| **Empty/Null** | Null input, empty string, empty array, missing optional fields |
| **Boundaries** | Min value, max value, just below max, just above max |
| **Permissions** | Unauthorized user, wrong role, expired session |
| **State** | Already exists, doesn't exist, concurrent modification |
| **Format** | Invalid format, special characters, unicode, very long input |

### Boundary Conditions

For any numeric or limited input, test:
- Minimum allowed value
- Maximum allowed value
- One below minimum (should fail)
- One above maximum (should fail)
- Typical middle value

### Error Handling Scenarios

- Network failure mid-operation
- Downstream service unavailable
- Invalid data from external source
- Timeout scenarios
- Partial failure in batch operations

### Performance Considerations

- Response time under normal load
- Behavior at peak load
- Large data set handling
- Pagination limits
- Concurrent user scenarios

## Confidence Scoring Rubric

Rate each factor 1-3, total gives confidence score out of 12:

| Factor | Low (1) | Medium (2) | High (3) |
|--------|---------|------------|----------|
| **Requirements** | Vague description, missing AC, unclear user value | Some AC defined, minor gaps, user value understood | Clear, complete AC, all scenarios documented |
| **Technical** | Unknown approach, unfamiliar codebase, architecture decision needed | Approach identified, some unknowns remain | Clear approach, proven patterns, familiar codebase |
| **Test Coverage** | No test scenarios defined | Some scenarios, gaps in edge cases | Full happy/unhappy paths, boundaries defined |
| **Dependencies** | Unknown blockers, external team involvement unclear | Dependencies known, some unresolved | All dependencies resolved or mitigation planned |

### Interpreting the Score

| Score | Confidence | Action |
|-------|------------|--------|
| 10-12 | **High** | Ready for sprint, proceed with implementation |
| 7-9 | **Medium** | Acceptable risk, document unknowns, proceed with caution |
| 4-6 | **Low** | Not ready, requires technical deep dive or product clarification |
| 1-3 | **Not Ready** | Do not commit, significant gaps must be addressed |

## Fibonacci Estimation Guide

| Points | Description | Typical Scope | Examples |
|--------|-------------|---------------|----------|
| **1** | Trivial | Config change, copy update | Environment variable, text change |
| **2** | Small | Single file, straightforward logic | Add validation, simple bug fix |
| **3** | Medium | Multiple files, clear approach | New endpoint, new component |
| **5** | Large | Multiple components, some complexity | Feature with BE + FE changes |
| **8** | Very Large | Cross-service, significant complexity | New integration, complex flow |
| **13** | Epic-sized | Should be broken down | If you're estimating 13, split the ticket |

### Estimation Tips

- Estimate complexity, not time
- Include testing effort in the estimate
- Consider deployment and verification time
- If uncertain between two values, choose the higher one
- If team members disagree by more than one Fibonacci number, discuss

## Quick Reference: Refinement Checklist

Before committing a ticket to sprint:

1. [ ] Three Amigos perspectives captured (Dev, Test, Product)
2. [ ] Definition of Ready checklist complete
3. [ ] Confidence score calculated (minimum 7/12)
4. [ ] Fibonacci estimate agreed
5. [ ] Implementation plan documented in Jira
6. [ ] Test scenarios documented
7. [ ] Affected codebases identified
8. [ ] Dependencies resolved or mitigation planned

## Related Resources

- [Refinement Skill](../skills/refine-ticket/SKILL.md) - Interactive refinement with Jira integration
- [Technical Deep Dive Skill](../skills/technical-deep-dive/SKILL.md) - Quick codebase investigation (hours)
- [Spike Skill](../skills/spike/SKILL.md) - Time-boxed research for broader investigation (days)
- [Golden Paths](../golden-paths/) - Architecture patterns to reference
- [Scoring Criteria](../scoring/criteria/) - Quality standards for implementation
