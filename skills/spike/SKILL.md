---
name: spike
description: Time-boxed research and investigation skill for answering specific technical questions, evaluating options, and reducing uncertainty before committing to implementation. Use when the user needs to spike on a topic, investigate a technical question, evaluate options, or research before building.
---
# Spike Skill

Time-boxed research and investigation skill for answering specific technical questions, evaluating options, and reducing uncertainty before committing to implementation.

## Prerequisites

### Required MCP Servers

| MCP Server | Tools Used | Purpose | Required? |
|------------|------------|---------|-----------|
| **user-mcp-atlassian** | `jira_get_issue` | Fetch spike ticket details | Recommended |
| | `jira_update_issue` | Update spike ticket with findings | Recommended |
| | `jira_add_comment` | Post findings to spike ticket | Recommended |
| **user-github** | `search_code` | Search patterns across Pax8 org repos | Optional |
| | `search_repositories` | Find relevant repos | Optional |
| | `get_file_contents` | Retrieve files from GitHub repos | Optional |
| **cursor-ide-browser** | `browser_navigate` | Fallback: Browse GitHub with SSO session | Optional |
| | `browser_snapshot`, `browser_click` | Interact with GitHub UI | Optional |

> **Important:** See [Jira Standards](../../rules/auto-apply/jira-standards.md) for custom field usage. Spikes use `customfield_14303` (Spike Description field), not the standard description field.

### Research Capabilities

This skill can leverage multiple sources during investigation:

| Source | Capability | Use Case |
|--------|------------|----------|
| **Local Workspace** | Explore repos in current workspace | Patterns in repos you're working with |
| **GitHub (Pax8 Org)** | Search across all org repos via MCP or Browser | Find patterns in repos not in workspace |
| **Web Search** | Search external documentation, blogs | Third-party evaluation, best practices |
| **Engineering Codex** | Read facets, options, gotchas, tech radar | Best practices, decision frameworks, trade-offs (preferred over web search) |

### GitHub Access Methods

**Method 1: GitHub MCP** (Preferred if configured)
- Uses `user-github` MCP with `search_code`, `search_repositories`, `get_file_contents`
- Requires GitHub token with org access configured

**Method 2: Browser MCP** (Fallback)
- Uses `cursor-ide-browser` to navigate GitHub directly
- Works with your SSO/authenticated browser session
- Flow: Navigate to GitHub → Sign in if needed → Search/browse via UI

If GitHub MCP returns permission errors, the skill will offer to use Browser MCP instead:
```
GitHub MCP doesn't have access to Pax8 private repos. Would you like me to:
1. Search via Browser MCP (uses your authenticated session)
2. Skip GitHub search and continue with local workspace only
```

### Related Skills

This skill may invoke other skills during investigation:
- **Technical Deep Dive** - For codebase exploration
- **Refine Ticket** - For refining follow-up tickets created from spike findings

### Graceful Degradation

If the Atlassian MCP is not available:
1. **Prompt to enable**: "The Atlassian MCP (`user-mcp-atlassian`) is not enabled. Would you like to enable it, or provide spike details manually?"
2. **Offer manual input**: Accept pasted spike ticket content
3. **Generate markdown**: Produce findings as markdown for manual copy/paste to Jira

## When to Use

Invoke this skill when:
- Starting a spike ticket (time-boxed research)
- Need to answer specific technical questions before implementation
- Evaluating third-party tools, libraries, or services
- Investigating performance issues or bottlenecks
- Researching integration approaches with external systems
- Making architecture decisions that need exploration

## Spike Types Supported

| Type | Purpose | Typical Questions |
|------|---------|-------------------|
| **Technical Feasibility** | Can we build X? | Is this possible? What are the constraints? |
| **Architecture Decision** | How should we design X? | Which pattern? What trade-offs? |
| **Third-Party Evaluation** | Which tool should we use? | Compare options, licensing, fit |
| **Performance Investigation** | Why is X slow? | Where are bottlenecks? What can we optimize? |
| **Integration Research** | How do we connect to X? | API capabilities, auth, data formats |

## Invocation

```
Spike HRZN-456
```

Or with context:
```
Spike HRZN-456 - investigating caching options for currency rates
```

## Workflow

### Phase 1: Input and Understanding

1. **Fetch Spike Ticket**
   ```
   Use jira_get_issue with:
   - issue_key: [spike ticket key]
   - fields: "*all"
   ```

2. **Assess Clarity**
   
   Evaluate if the spike ticket has:
   - Clear questions to answer
   - Defined scope
   - Context on what triggered it
   
   **If the ticket is clear**: Proceed to Phase 2 (Success Criteria)
   
   **If the ticket is vague**: Proceed to Phase 1b (Discovery)

### Phase 1b: Discovery (for Vague Spikes)

When a spike ticket lacks clarity, follow the [Discovery Guide](discovery-guide.md) to conduct a structured conversation that captures context, identifies the core uncertainty, and formulates clear questions.

The discovery guide walks through 7 steps: acknowledge, understand the trigger, explore existing knowledge, identify the core uncertainty, formulate clear questions, determine spike type, and document findings.

The discovery summary becomes part of the final spike findings, ensuring the context isn't lost.

### Phase 2: Define Success Criteria

Before investigating, establish what "done" looks like:

```
## Success Criteria

This spike will be complete when we can answer:
- [ ] [Specific question 1]
- [ ] [Specific question 2]

Deliverables:
- [ ] Recommendation with rationale
- [ ] Documented trade-offs/risks
- [ ] Follow-up tickets identified (if any)
```

Present to user for confirmation before proceeding.

### Phase 3: Investigation

Based on spike type, conduct appropriate research using available sources:

#### Research Sources

**0. Engineering Codex (Preferred — if available)**

If `@engineering-codex` is in the workspace, check it first before web search:

- **For Architecture Decisions**: Read `@engineering-codex/facets/[relevant-facet]/options.md` for evaluated options with trade-offs already documented, and `architecture.md` for patterns and diagrams
- **For Third-Party Evaluation**: Check `@engineering-codex/tech-radar.md` for the codex's current assessment of the tool, and `@engineering-codex/tech-radar-pax8.md` for Pax8-specific stance
- **For Best Practices**: Read `@engineering-codex/facets/[relevant-facet]/best-practices.md` instead of searching the web — these are curated and stack-specific
- **For Risk Identification**: Read `@engineering-codex/facets/[relevant-facet]/gotchas.md` for known pitfalls
- **For Pax8 Standards**: Read `@engineering-codex/pax8-context/standards-map.md` to check if Pax8 has already decided

Only fall back to web search for information not covered by the codex (e.g., specific third-party API documentation, very recent releases, library-specific configuration).

**1. Local Workspace Repositories**
- Use explore subagent, Read, Grep, Glob tools
- Best for: Repos you're actively working with
- Invoke Technical Deep Dive skill for detailed codebase exploration

**2. GitHub (Pax8 Organization)**
If the GitHub MCP (`user-github`) is enabled:
```
Search for patterns across all Pax8 repos:
- search_code with q: "org:pax8 [search term]"
- search_repositories with query: "org:pax8 [topic]"

Examples:
- "org:pax8 redis caching" - Find caching implementations
- "org:pax8 filename:EventHandler.kt" - Find event handler patterns
- "org:pax8 path:src/service authentication" - Find auth in service layers
```

Retrieve specific files found in search:
```
get_file_contents with:
- owner: "pax8"
- repo: [repository name]
- path: [file path from search results]
```

**3. Web Search (External Research)**
Use web search for:
- Third-party tool documentation and comparisons
- Industry best practices and patterns
- Library/framework capabilities
- Community discussions and recommendations

Always cite sources in findings when using external research.

#### Investigation by Spike Type

#### For Technical Feasibility
- Explore relevant codebases (invoke Deep Dive if needed)
- Identify technical constraints
- Check for existing patterns or prior art
- Assess complexity and risks

#### For Architecture Decisions
- Check Engineering Codex first: `@engineering-codex/facets/[facet]/options.md` for pre-evaluated options
- Reference golden paths: `@workspace-standards/golden-paths/`
- Check Pax8 standards: `@engineering-codex/pax8-context/standards-map.md` (if Pax8 project)
- Explore existing patterns in codebase
- Fall back to web search only for information not in the codex
- Document options with trade-offs

#### For Third-Party Evaluation
- Research candidate tools/libraries
- Check licensing compatibility
- Evaluate community support and maintenance
- Assess integration complexity
- Consider security implications

#### For Performance Investigation
- Identify suspected bottlenecks
- Explore relevant code paths
- Research optimization strategies
- Consider caching, indexing, async patterns

#### For Integration Research
- Research external API documentation
- Identify authentication requirements
- Map data formats and transformations
- Consider error handling and resilience

### Phase 4: Document Findings

Structure findings based on investigation:

```markdown
## Spike Findings: [Spike Title]

**Ticket:** [HRZN-XXX]
**Time-box:** [X days]
**Status:** Complete / Partial (requires follow-up)

---

### Discovery Context (if spike was initially vague)

> **Trigger:** [What prompted this spike]
> **Prior Knowledge:** [What was already known before investigation]
> **Constraints:** [Limitations that shaped the investigation]

---

### Questions Investigated

1. **[Question 1]**
   - **Answer:** [Clear answer]
   - **Evidence:** [How we determined this]

2. **[Question 2]**
   - **Answer:** [Clear answer]
   - **Evidence:** [How we determined this]

---

### Recommendation

[Clear recommendation with rationale]

**Confidence:** High / Medium / Low
**Rationale:** [Why this recommendation]

---

### Options Considered

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| A | [Description] | [Pros] | [Cons] |
| B | [Description] | [Pros] | [Cons] |

---

### Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk] | Low/Med/High | Low/Med/High | [How to address] |

---

### Implementation Readiness Assessment

**Overall Confidence:** [High/Medium/Low]

#### Ready to Implement
| Task | Evidence |
|------|----------|
| [Task] | [Why we're confident] |

#### Gaps to Resolve
| Gap | Impact | Owner | Resolution |
|-----|--------|-------|------------|
| [Gap] | [Blocks X] | [Team] | [How to resolve] |

#### Prerequisites
| Prerequisite | Status | Blocks |
|--------------|--------|--------|
| [Item] | [Unknown/In Progress] | [Which tasks] |

---

### Follow-up Actions

- [ ] [Action 1 - may be a new ticket]
- [ ] [Action 2]

---

### Resources and References

- [Link to documentation]
- [Link to code examples]
- [Link to external resources]
```

### Phase 5: Implementation Readiness Assessment

Before concluding a spike, assess confidence in the ability to implement the recommendation. This helps identify gaps that could block or delay implementation.

#### Step 1: Categorize Implementation Tasks

List all tasks that would be needed to implement the recommendation:

```markdown
## Implementation Tasks

### High Confidence (Ready to Implement)
| Task | Why Ready |
|------|-----------|
| [Task] | [Evidence: patterns exist, code reviewed, etc.] |

### Medium Confidence (Minor Clarification Needed)
| Task | Gap | Resolution |
|------|-----|------------|
| [Task] | [What's unclear] | [How to resolve] |

### Lower Confidence (Needs Investigation)
| Task | Gap | Impact |
|------|-----|--------|
| [Task] | [What's unknown] | [Risk if not resolved] |
```

#### Step 2: Identify Blocking Gaps

For any task with Medium or Lower confidence, determine:

1. **Is this a blocker?** - Can implementation start without this answer?
2. **Who can resolve it?** - Team, platform/infra, external vendor?
3. **Effort to resolve** - Quick question vs. separate spike needed?

#### Step 3: Document Prerequisites

List any prerequisites that must be resolved before implementation:

```markdown
## Implementation Prerequisites

| Prerequisite | Owner | Status | Blocks |
|--------------|-------|--------|--------|
| [Item] | [Team/Person] | Unknown/In Progress/Done | [Which tasks] |
```

#### Step 4: Provide Overall Confidence

Summarize implementation readiness:

```markdown
## Implementation Readiness

**Overall Confidence:** [High/Medium/Low]

- **High**: All tasks have clear patterns, minimal unknowns
- **Medium**: Core tasks ready, some peripheral gaps to resolve
- **Low**: Significant unknowns that should be resolved first

**Recommendation:** [Proceed / Resolve gaps first / Needs follow-up spike]
```

Include this assessment in the spike findings posted to Jira. If gaps are identified, recommend creating specific tickets to address them before or in parallel with implementation.

---

### Phase 6: Handle Outcomes

#### If Spike is Conclusive

1. Update the spike ticket description with findings:
   ```
   Use jira_update_issue with:
   - issue_key: [spike ticket key]
   - fields: {}
   - additional_fields: { "customfield_14303": "[formatted findings]" }
   ```
   
   > **Note:** Spikes use `customfield_14303` (Spike Description field), not the standard description. See [Jira Standards](../../rules/auto-apply/jira-standards.md).
   
   Alternatively, add findings as a comment:
   ```
   Use jira_add_comment with:
   - issue_key: [spike ticket key]
   - comment: [formatted findings]
   ```

2. Identify follow-up work:
   - Implementation tickets to create
   - ADR to write (if architecture decision)
   - Documentation to update

3. Offer to help with follow-up:
   ```
   The spike is complete. Would you like me to:
   1. Help refine the follow-up implementation ticket
   2. Draft an ADR for the architecture decision
   3. Create the follow-up tickets in Jira
   ```

#### If Spike is Inconclusive (Partial Findings)

1. Document what was learned (still include Implementation Readiness Assessment for any actionable findings):
   ```markdown
   ## Partial Spike Findings: [Title]
   
   **Status:** Inconclusive - requires follow-up spike
   
   ### What We Learned
   - [Finding 1]
   - [Finding 2]
   
   ### What Remains Unknown
   - [Question still unanswered]
   - [Blocker encountered]
   
   ### Recommended Next Steps
   - [ ] Follow-up spike: [Specific focus]
   - [ ] Escalate to: [Person/team who can help]
   - [ ] Wait for: [Dependency to be resolved]
   
   ### Time Spent
   - [X hours/days] of [Y hours/days] time-box used
   ```

2. Post partial findings to Jira

3. Offer to create follow-up spike ticket:
   ```
   The spike reached partial findings. Would you like me to:
   1. Create a follow-up spike ticket with narrowed scope
   2. Document blockers and wait
   ```

## Output Format Summary

The spike always produces a Jira comment with:

1. **Header**: Ticket, time-box, status
2. **Questions & Answers**: What was investigated and findings
3. **Recommendation**: Clear recommendation with confidence level
4. **Options**: If decision-based, comparison of alternatives
5. **Risks**: Identified risks and mitigations
6. **Implementation Readiness**: Confidence assessment with gaps and prerequisites
7. **Follow-ups**: Next actions or tickets to create
8. **References**: Links to resources discovered

## Error Handling

### MCP Not Available

Present options using AskQuestion:
```
The Atlassian MCP (user-mcp-atlassian) isn't enabled.

How would you like to proceed?
1. Enable the MCP - I'll wait while you enable it
2. Provide spike details manually - Paste the ticket content
3. Skip Jira integration - I'll generate findings as markdown
```

### Spike Scope Too Broad

If the spike has too many questions or unclear scope:
- Suggest narrowing to 1-2 key questions
- Recommend splitting into multiple spikes
- Help prioritize which question to tackle first

### Discovery Doesn't Converge or User Lacks Context

See the [Discovery Guide](discovery-guide.md) for handling these scenarios, including when to escalate, split into smaller spikes, or proceed with documented assumptions.

### External Research Needed

If the spike requires information not in the codebase:
- Use web search for documentation, best practices
- Clearly note which findings came from external sources
- Verify external information against codebase constraints

### Time-box Exceeded

If investigation is taking longer than expected:
- Pause and assess progress
- Document partial findings
- Ask user whether to continue or close with partial results

## Related Resources

- [Implement Ticket Skill](../implement-ticket/SKILL.md) - Structured implementation after spike findings inform a refined ticket
- [Technical Deep Dive Skill](../technical-deep-dive/SKILL.md) - For codebase investigation
- [Refine Ticket Skill](../refine-ticket/SKILL.md) - For refining follow-up tickets
- [Refinement Best Practices](../../rules/refinement-best-practices.md)
- [Golden Paths](../../golden-paths/) - Architecture patterns
