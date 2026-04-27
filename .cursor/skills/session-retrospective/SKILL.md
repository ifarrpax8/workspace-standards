---
name: session-retrospective
description: End-of-session retrospective that reviews skill usage and interaction patterns, then produces targeted improvement proposals for SKILL.md files and documentation.
complexity: low
prompt-version: "1.0"
---

# Session Retrospective Skill

Reviews the current conversation to surface friction, gaps, and improvement opportunities in skills and documentation. Produces concrete, prioritised proposals — with specific before/after edits to SKILL.md files — that can be applied immediately or tracked as Jira tickets.

## Prerequisites

### Required MCP Servers

| MCP Server | Tools Used | Purpose | Required? |
|------------|------------|---------|-----------|
| **user-mcp-atlassian** | `jira_create_issue` | Create improvement ticket in HRZN | Optional |

### Graceful Degradation

If no MCP is available: output improvement proposals as markdown only; offer to save to `docs/skill-improvements.md`.

## When to Use

- After any substantial session involving one or more skills
- When a skill felt unclear, incomplete, or required significant improvisation
- At the end of a sprint to batch improvements before the next planning cycle
- When a skill invocation produced unexpected results or required manual correction

## When NOT to Use

- After trivial single-step tasks where no skill guidance was involved
- For implementation-specific learnings tied to a Jira ticket — use [Post-Implementation Review](../post-implementation-review/SKILL.md) instead
- For periodic deep-cleaning of all skill files — run this after individual sessions, not as a bulk audit

## Invocation

```
session retrospective
```

```
retro on this session
```

```
what could we improve from this session?
```

## Workflow

### Phase 1: Session Inventory

Review the full conversation and identify:

1. **Skills explicitly invoked** — by name or by reading a SKILL.md
2. **Skills implicitly invoked** — the agent followed a skill-like workflow without being asked
3. **Improvised steps** — the agent deviated from or extended skill guidance to handle something not covered
4. **Manual inputs required** — context the user had to supply that a skill should have anticipated
5. **Repeated clarifications** — questions the agent asked more than once, or that should not have been necessary
6. **Missing skills** — tasks that would have benefited from a structured skill but none existed

Produce a brief inventory table:

| # | Skill / Area | Used? | Friction Observed |
|---|-------------|-------|-------------------|
| 1 | [skill-name] | Yes/Implicitly/No | [brief note or "none"] |

### Phase 2: Friction Analysis

For each skill or area that had friction, evaluate:

- Was a phase missing or unclear?
- Did the agent need to go off-script to handle an edge case?
- Was a "When NOT to Use" boundary unclear, causing the wrong skill to be invoked?
- Were cross-skill handoffs awkward or underdocumented?
- Was an example missing that would have made the expected output clear?
- Were MCP tool calls misused due to incorrect guidance in the skill?

### Phase 3: Gap Detection

Identify things that should exist but don't:

- A skill phase that was needed but absent
- A rule or golden path that was referenced but does not exist
- A new skill that would have been useful (describe the gap in one sentence)
- A "When NOT to Use" case that should be documented
- An update to AGENTS.md or a rules file to reflect a change in practice

### Phase 4: Produce Improvement Proposals

For each finding, produce a structured proposal. Order by priority (High → Low).

```markdown
## Improvement #N: [Short title]

**Target**: workspace-standards/.cursor/skills/[skill-name]/SKILL.md
**Type**: Missing phase | Unclear step | Wrong/missing example | New skill needed | Rule update | AGENTS.md update
**Priority**: High | Medium | Low

**Finding**:
[What was missing, ambiguous, or wrong — 1–3 sentences.]

**Proposed change**:
[Exact text to add, remove, or replace. Use before/after format for edits.]

**Prompt version bump**: [current] → [bumped patch version, e.g. "1.0" → "1.1"]
```

### Phase 5: Action Options

Present the full set of proposals, then ask which action the user wants to take:

```
I found [N] improvement(s) across [M] skill(s). How would you like to proceed?

1. Apply all now — I'll edit the affected SKILL.md files directly
2. Apply selectively — Walk through each proposal and choose
3. Create a Jira ticket — I'll open an improvement ticket in HRZN with all proposals
4. Save to log — I'll append proposals to docs/skill-improvements.md for later
5. Dismiss — No action needed
```

If the user chooses **Apply all now** or **Apply selectively**, edit the SKILL.md files and bump `prompt-version` for each changed file.

If the user chooses **Create a Jira ticket**, create a single ticket summarising all proposals:

- **Project**: HRZN
- **Type**: Task
- **Summary**: `Skill improvements from session on [date]`
- **Description**: Full proposal list in markdown

If the user chooses **Save to log**, append to `docs/skill-improvements.md` in the workspace-standards repo (create the file if it doesn't exist) using this format:

```markdown
## [Date] — Session Retrospective

### Session summary
[1–2 sentence description of what the session covered]

### Proposals
[Full proposal list]
```

## Output Format

```markdown
## Session Retrospective — [Date]

### Session Summary
[1–2 sentences: what was worked on, which skills were used]

### Skill Inventory
| # | Skill / Area | Used? | Friction |
|---|-------------|-------|---------|
| ... | ... | ... | ... |

### Improvement Proposals

#### Improvement #1: [Title]
**Target**: ...
**Type**: ...
**Priority**: High
**Finding**: ...
**Proposed change**:
[content]
**Prompt version bump**: 1.0 → 1.1

[... additional proposals ...]

### No Action Needed
[Any skills or areas that worked well and require no changes]
```

## Verification

- **Phase 1**: At least one skill or area must be identified. If the session had no skill usage, state this and offer to end the retrospective.
- **Phase 4**: Every proposal must name a specific target file and include a concrete proposed change — not just a vague recommendation.
- **Phase 5 (Apply)**: After editing SKILL.md files, confirm `prompt-version` was bumped in every changed file.
- **Phase 5 (Jira)**: Confirm `jira_create_issue` returned a ticket key before reporting success.

## Worked Example

**Input:** `session retrospective`

**Session context:** The agent used `implement-ticket` to implement HRZN-731. Mid-session, the user had to manually provide the MCP fallback instructions because the skill's graceful degradation section didn't cover the case where Jira was reachable but returned a 403.

> **Historical note:** This example predates the migration to native `description` fields. The reference to `customfield_12636` below reflects the old custom field pattern — the field and fallback approach are no longer applicable.

**Output excerpt:**

```markdown
## Session Retrospective — 2026-03-03

### Session Summary
Implemented HRZN-731 (invoice currency select component) using implement-ticket. Jira MCP was available but returned a 403 on `customfield_12636`, requiring manual fallback handling.

### Skill Inventory
| # | Skill | Used? | Friction |
|---|-------|-------|---------|
| 1 | implement-ticket | Yes | Graceful degradation gap: 403 on Jira field fetch not handled |
| 2 | code-review | Yes | None |

### Improvement Proposals

#### Improvement #1: Handle Jira 403 in implement-ticket graceful degradation
**Target**: workspace-standards/.cursor/skills/implement-ticket/SKILL.md
**Type**: Missing edge case in error handling
**Priority**: High

**Finding**:
The graceful degradation section only covers MCP unavailability, not the case where Jira is reachable but returns a 403 (e.g., insufficient field permissions). The agent had to improvise a fallback.

**Proposed change** (historical — `customfield_12636` no longer used):
Add to the Graceful Degradation section:
> **Jira 403 on description**: If `jira_get_issue` succeeds but `description` is forbidden, ask the user to paste the acceptance criteria directly.

**Prompt version bump**: 1.1 → 1.2
```

## Error Handling

### No Skills Used This Session

```
This session didn't invoke any skills directly.

Would you like to:
1. Review the session for ad-hoc patterns that could become skills
2. End the retrospective — nothing to capture
```

### Proposal Has No Clear Target File

If a gap doesn't map to an existing file (e.g., a new skill is needed), produce a scaffold suggestion:

```markdown
**Proposed new skill**: workspace-standards/.cursor/skills/[suggested-name]/SKILL.md
**Purpose**: [One-line description]
**Key phases**: [Bullet list of 3–5 phases]
**Complexity**: low | high
```

## Related Resources

- [Post-Implementation Review](../post-implementation-review/SKILL.md) — ticket-level retrospective (estimates, tests, learnings)
- [Implement Ticket](../implement-ticket/SKILL.md) — produces the implementation summary that feeds PIR
- [Skill Improvement Log](../../../docs/skill-improvements.md) — persistent log of session proposals (created on first use)
