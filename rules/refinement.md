# Refinement Assistant

A lightweight rule for quick ticket breakdowns. For the comprehensive Three Amigos refinement process, see [Refinement Best Practices](refinement-best-practices.md) or use the interactive [Refine Ticket Skill](../skills/refine-ticket/SKILL.md).

**Usage:** `@workspace-standards/rules/refinement.md help me refine <ticket or feature description>`

---

## Refinement Process

### 1. Understand the Requirement

First, clarify the following:

- **What** is being built/changed?
- **Why** is this needed? (Business value)
- **Who** are the users/consumers?
- **Where** in the system does this fit?

### 2. Identify Affected Components

Based on the requirement, identify:

```markdown
## Affected Areas

### Backend Services
- [ ] Service name: [specific changes needed]

### Frontend (MFE)
- [ ] MFE name: [specific changes needed]

### Database
- [ ] Schema changes: [yes/no, details]
- [ ] Migration needed: [yes/no]

### Events/Messaging
- [ ] New events: [list]
- [ ] Modified events: [list]
- [ ] Consumers to update: [list]

### Configuration
- [ ] Environment variables: [list]
- [ ] Feature flags: [list]
```

### 3. Technical Tasks Breakdown

Break the work into atomic, deliverable tasks:

```markdown
## Tasks

### Task 1: [Title]
- **Description:** [What needs to be done]
- **Acceptance Criteria:**
  - [ ] [Specific, testable criterion]
  - [ ] [Another criterion]
- **Dependencies:** [Other tasks or external dependencies]
- **Estimated Effort:** [S/M/L]

### Task 2: [Title]
...
```

### 4. Architecture Considerations

Ask these questions:

**For New Features:**
- [ ] Does this follow our golden path architecture?
- [ ] Is an ADR needed for any decisions?
- [ ] What pattern should be used? (CQRS, layered, etc.)

**For Modifications:**
- [ ] Does this introduce technical debt?
- [ ] Are there opportunities to improve existing code?
- [ ] Does this affect existing tests?

**For Cross-Cutting Concerns:**
- [ ] Authentication/Authorization needed?
- [ ] Audit logging required?
- [ ] Performance considerations?
- [ ] Error handling strategy?

### 5. Risk Assessment

```markdown
## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| [Risk description] | Low/Med/High | Low/Med/High | [How to address] |
```

### 6. Testing Strategy

Define what needs to be tested:

```markdown
## Testing Requirements

### Unit Tests
- [ ] [Component/function to test]

### Integration Tests
- [ ] [Flow or integration to test]

### Manual Testing
- [ ] [Scenario that requires manual verification]

### Regression Considerations
- [ ] [Existing functionality that could be affected]
```

---

## Output Template

When refining a ticket, produce output in this format:

```markdown
# Refinement: [Ticket ID] - [Title]

## Summary
[1-2 sentence description of what this ticket accomplishes]

## Business Context
- **User Story:** As a [role], I want [goal] so that [benefit]
- **Acceptance Criteria from Product:**
  - [ ] [Criterion 1]
  - [ ] [Criterion 2]

## Technical Approach

### Architecture Decision
[Describe the approach and why]

### Components Affected
- **[Component 1]:** [Change description]
- **[Component 2]:** [Change description]

## Implementation Tasks

### 1. [Task Title] (Backend)
- Create/modify [specific file/class]
- Implement [specific functionality]
- **AC:** [Technical acceptance criterion]

### 2. [Task Title] (Frontend)
- Create/modify [specific component]
- Implement [specific UI/logic]
- **AC:** [Technical acceptance criterion]

### 3. [Task Title] (Testing)
- Add [specific tests]
- **AC:** All new code has test coverage

## Dependencies
- [ ] [External dependency or blocker]

## Risks
- [Risk and mitigation]

## Questions for Product/Stakeholders
- [ ] [Clarification needed]

## Definition of Done
- [ ] Code reviewed and approved
- [ ] Tests passing
- [ ] Documentation updated
- [ ] Deployed to preproduction
- [ ] Product sign-off
```

---

## Quick Reference: Story Point Estimation

| Size | Description | Typical Scope |
|------|-------------|---------------|
| **1** | Trivial | Config change, copy update |
| **2** | Small | Single file change, simple logic |
| **3** | Medium | Multiple files, straightforward feature |
| **5** | Large | Multiple components, some complexity |
| **8** | Very Large | Cross-service, significant complexity |
| **13** | Epic-sized | Should be broken down further |

---

## Questions to Ask

### If Requirements Are Unclear
- What should happen if [edge case]?
- Who is the primary user for this feature?
- What existing functionality should this integrate with?
- Are there any constraints (performance, security, etc.)?

### If Technical Approach Is Unclear
- Is there existing code we can reference or extend?
- Does this require a new pattern or can we follow existing patterns?
- What are the rollback/recovery options if something goes wrong?
- Should this be feature-flagged for gradual rollout?

### If Scope Is Too Large
- Can this be delivered incrementally?
- What is the minimum viable implementation?
- Are there parts that can be deferred to a follow-up ticket?
