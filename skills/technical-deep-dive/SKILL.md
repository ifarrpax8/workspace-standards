---
name: technical-deep-dive
description: Codebase investigation skill for understanding implementation approaches, identifying code locations, analyzing patterns, and resolving technical unknowns. Use when the user needs a deep dive into a codebase, wants to investigate how something works, or needs to resolve technical questions before implementation.
---
# Technical Deep Dive Skill

Codebase investigation skill for understanding implementation approaches, identifying code locations, analyzing patterns, and resolving technical unknowns.

## Prerequisites

### Required MCP Servers

| MCP Server | Tools Used | Purpose | Required? |
|------------|------------|---------|-----------|
| **user-mcp-atlassian** | `jira_get_issue` | Fetch ticket context (if provided) | Optional |
| **user-github** | `search_code` | Search patterns across Pax8 org repos | Optional |
| | `get_file_contents` | Retrieve files from GitHub repos not in workspace | Optional |
| **cursor-ide-browser** | `browser_navigate` | Fallback: Browse GitHub with SSO session | Optional |
| | `browser_snapshot`, `browser_click` | Interact with GitHub UI | Optional |

### Core Capabilities Used

This skill primarily uses built-in Cursor capabilities:
- **Explore subagent** - For codebase investigation
- **Read tool** - For examining files
- **Grep/Glob tools** - For searching patterns
- **SemanticSearch** - For finding relevant code

These are always available and don't require MCP configuration.

### Extended Search (GitHub)

This skill can search across all Pax8 organization repositories - useful when:
- Looking for patterns in repos not in your current workspace
- Finding how other teams solved similar problems
- Searching for existing implementations to reference

**Method 1: GitHub MCP** (if configured with org access)
```
search_code with q: "org:pax8 EventHandler"
search_code with q: "org:pax8 path:src/endpoint pagination"
```

**Method 2: Browser MCP** (fallback using your authenticated session)
```
Navigate to: https://github.com/search?q=org%3Apax8+[search+term]&type=code
```

If GitHub MCP returns permission errors, the skill will offer:
```
GitHub MCP doesn't have access to Pax8 private repos. Would you like me to:
1. Search via Browser (uses your SSO-authenticated session)
2. Continue with local workspace only
```

### Graceful Degradation

If the Atlassian MCP is not available when a ticket key is provided:
1. **Prompt to enable**: "The Atlassian MCP (`user-mcp-atlassian`) is not enabled. Would you like to enable it, or describe the ticket context manually?"
2. **Continue without**: Proceed with the deep dive using only the technical question provided

## When to Use

Invoke this skill when:
- No clear implementation approach exists
- Unfamiliar with the affected codebase
- Architecture decisions need to be made
- Complex integration with existing systems required
- Technical confidence score is 1/3 (Low) during refinement
- Spike/research work before creating tickets

## Invocation

Standalone:
```
Technical deep dive: How do we add a new filter to the invoice list in finance-mfe?
```

With specific repository:
```
Technical deep dive in currency-manager: How are exchange rates fetched and cached?
```

From refinement (when technical confidence is low):
```
Continue from refinement HRZN-123: Need to understand how to add a new event handler
```

## Workflow

### Phase 1: Input and Context

1. **Understand the Question**
   - What technical question needs answering?
   - What is the desired outcome?
   - Is this related to a Jira ticket? If so, fetch context:

   ```
   Use the jira_get_issue tool if ticket key provided
   ```

2. **Identify Target Repositories**
   - Ask user to confirm which repository/repositories to investigate
   - Can be one or multiple repositories

3. **Clarify Scope**
   - Is this about adding new functionality?
   - Modifying existing functionality?
   - Understanding how something works?
   - Making an architecture decision?

### Phase 2: Codebase Exploration

Use the explore subagent to investigate the codebase:

```
Task: Explore [repository] to understand [topic]

Investigate:
1. Find files related to [feature/component]
2. Identify the patterns used (layered architecture, CQRS, etc.)
3. Look for similar implementations we can reference
4. Map out dependencies and integration points
```

**For Backend (Kotlin) repositories, explore:**
- `src/main/kotlin/` - Main source code
- Package structure (endpoint, service, repository, domain)
- Existing patterns for similar functionality
- Event handlers, commands, sagas (if Axon)
- Configuration classes

**For Frontend (Vue MFE) repositories, explore:**
- `src/components/` - UI components
- `src/composables/` - Reusable logic
- `src/services/` - API layer
- `src/stores/` - Pinia state management
- Existing patterns for similar UI elements

### Phase 3: Pattern Analysis

1. **Reference Golden Paths**
   - Read the relevant golden path document:
     - Backend: `@workspace-standards/golden-paths/kotlin-spring-boot.md` or `kotlin-axon-cqrs.md`
     - Frontend: `@workspace-standards/golden-paths/vue-mfe.md`

1b. **Reference Engineering Codex** (if available)
   - Read `@engineering-codex/facets/[relevant-facet]/architecture.md` for architectural patterns, diagrams, and trade-offs
   - Read `@engineering-codex/facets/[relevant-facet]/options.md` for evaluated alternatives
   - Read `@engineering-codex/facets/[relevant-facet]/best-practices.md` for implementation guidance
   - Check `@engineering-codex/tech-radar.md` to see where relevant technologies sit (Adopt/Trial/Assess/Hold)
   - This provides industry context that complements the golden paths' Pax8-specific patterns

2. **Compare to Golden Path**
   - Does the codebase follow the expected patterns?
   - Are there deviations? Why might they exist?
   - Which pattern should the new work follow?

3. **Find Reference Implementations**
   - Search for similar functionality in the codebase
   - Identify code that can serve as a template
   - Note any patterns that should be replicated

### Phase 4: Output Generation

Generate comprehensive findings based on investigation:

#### Code Locations to Modify

Identify specific files that will need changes:

| File | Purpose | Change Type |
|------|---------|-------------|
| `path/to/file.kt` | [What this file does] | Create/Modify/Delete |

#### Patterns to Follow

Show existing code that demonstrates the pattern:

```kotlin
// Example from: src/service/ExistingService.kt
// This shows how we handle [pattern]
[relevant code snippet]
```

Explain how to apply this pattern to the new work.

#### Architecture Decision (if needed)

If the investigation reveals an architecture decision is needed:

1. Check `@engineering-codex/facets/[facet]/options.md` for pre-evaluated options (if codex available)
2. Document the options considered (augmented with codex insights)
3. List pros and cons for each
4. Check Pax8 standards: `@engineering-codex/pax8-context/standards-map.md` — Pax8 may have already decided
5. Make a recommendation with rationale
6. Offer to create a draft ADR if significant

Reference ADR format from `finance/docs/adr/` for structure.

#### Spike Tasks (if still unclear)

If investigation cannot fully resolve the unknowns:

- Define specific, time-boxed research tasks
- Each spike should have a clear question to answer
- Suggest maximum time investment (e.g., 2 hours, half day)

### Phase 5: Technical Confidence Update

Reassess technical confidence:

```
## Updated Technical Confidence

Based on this deep dive:
- **Before:** 1/3 (Low)
- **After:** [2/3 or 3/3]
- **Justification:** [Why confidence has improved]
```

### Phase 6: Return to Refinement (if applicable)

If this deep dive was triggered from refinement:

1. Present the findings summary
2. Ask: "Would you like to continue refinement with this technical context?"
3. If yes, guide back to refinement skill with enhanced context
4. The technical findings should inform the implementation plan

## Output Format

```markdown
## Technical Deep Dive: [Topic]

### Investigation Summary
[1-2 sentence summary of what was investigated and key finding]

### Recommended Approach
[Clear recommendation with rationale - be specific about what to do]

---

### Code Locations to Modify

#### [Repository Name] (Backend/Frontend)

| File | Purpose | Change Type |
|------|---------|-------------|
| `src/path/to/File.kt` | [Description] | Modify |
| `src/path/to/NewFile.kt` | [Description] | Create |

---

### Patterns to Follow

**Reference Implementation:** `src/path/to/similar/Feature.kt`

```kotlin
// Existing pattern showing [what pattern]
[code snippet from codebase]
```

**Apply to New Work:**

```kotlin
// Suggested implementation following the pattern
[suggested code structure]
```

---

### Architecture Decision

**Decision Required:** Yes/No

**Options Considered:**

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| A | [Description] | [Pros] | [Cons] |
| B | [Description] | [Pros] | [Cons] |

**Recommendation:** Option [X]

**Rationale:** [Why this option is recommended]

**ADR Needed:** Yes/No - [If yes, offer to create draft]

---

### Spike Tasks

If further investigation needed before implementation:

| Spike | Question to Answer | Time Box |
|-------|-------------------|----------|
| [Title] | [Specific question] | [Hours] |

---

### Integration Points

| System | Integration Type | Notes |
|--------|-----------------|-------|
| [Service/API] | [REST/Event/etc.] | [Details] |

---

### Updated Technical Confidence

- **Before:** 1/3 (Low)
- **After:** [Score]/3 ([Level])
- **Justification:** [What was clarified]

---

### Next Steps

1. [Immediate next action]
2. [Follow-up action]
3. Return to refinement? [Yes/No recommendation]
```

## Error Handling

### MCP Not Available (for Jira context)

**If a ticket key is provided but Atlassian MCP is not enabled:**

Present options using AskQuestion:
```
You provided a Jira ticket key, but the Atlassian MCP (user-mcp-atlassian) 
isn't enabled. This is optional for deep dives.

How would you like to proceed?
1. Enable the MCP - I'll wait while you enable user-mcp-atlassian
2. Describe the context - Tell me what the ticket is about
3. Skip ticket context - I'll focus only on the technical question
```

### Repository Not Found
- Ask user to confirm the repository path
- List available repositories in the workspace using LS tool
- Suggest: "Here are the repositories in your workspace: [list]. Which would you like to investigate?"

### No Similar Patterns Found
- Check `@engineering-codex/facets/[relevant-facet]/architecture.md` for industry patterns (if codex available)
- Note this as a potential new pattern
- Suggest looking at golden paths for guidance
- Reference: `@workspace-standards/golden-paths/`
- May indicate need for ADR

### Complex Architecture Decision
- Don't try to make the decision alone
- Document options clearly
- Recommend team discussion
- Offer to create ADR draft for async review

### Exploration Timeout or Large Codebase
- If codebase is very large, narrow the scope
- Ask user to specify which area/feature to focus on
- Use targeted searches rather than broad exploration

## Related Resources

- [Implement Ticket Skill](../implement-ticket/SKILL.md) - Structured implementation of refined tickets
- [Refinement Skill](../refine-ticket/SKILL.md) - For refining tickets after deep dive
- [Spike Skill](../spike/SKILL.md) - For longer, time-boxed research (days vs hours)
- [Refinement Best Practices](../../rules/refinement-best-practices.md)
- [Golden Paths](../../golden-paths/)
- [Finance ADRs](../../../finance/docs/adr/) - ADR format reference
