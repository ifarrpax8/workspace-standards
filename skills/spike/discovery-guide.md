# Spike Discovery Guide

Structured discovery conversation for vague or open-ended spike tickets. Use this when a spike ticket lacks clear questions, defined scope, or context on what triggered it.

## Step 1: Acknowledge and Set Expectations

```
The spike ticket [HRZN-XXX] is fairly open-ended. Before we dive in, let's 
have a quick conversation to clarify what we're really trying to learn.

This will help us:
- Define clear questions to answer
- Set realistic success criteria
- Focus the investigation effectively
```

## Step 2: Understand the Trigger

Ask using AskQuestion tool:
```
What triggered this spike?
1. A blocked story/feature - we can't proceed without this answer
2. Team discussion - we realized we don't know enough about X
3. Technical concern - something might not work as expected
4. Customer/stakeholder request - someone asked if we can do X
5. Tech debt/improvement idea - we think there's a better way
6. Other - let me explain
```

Follow up based on response to understand the context.

## Step 3: Explore What's Already Known

Have a conversation to capture tribal knowledge:

```
Before we start fresh, let's capture what's already known or suspected:

1. **What do you already know or believe about this topic?**
   (Even hunches or assumptions are valuable)

2. **What has already been tried or considered?**
   (Previous attempts, rejected ideas, conversations)

3. **Are there any constraints we should know about?**
   (Time, budget, technology limitations, team preferences)

4. **Who else has context on this?**
   (People we might need to consult)
```

Document responses - these become part of the spike findings.

## Step 4: Identify the Core Uncertainty

Help narrow down what we're really trying to learn:

```
Based on our conversation, it sounds like the core uncertainty is:
[Summarize in one sentence]

Is that accurate, or is there something else at the heart of this?
```

Iterate until the user confirms.

## Step 5: Formulate Clear Questions

Transform the vague spike into specific, answerable questions:

```
Let me propose some specific questions for this spike:

1. [Specific question derived from discussion]
2. [Another specific question]
3. [Optional: third question if needed]

Do these capture what we need to learn? Should we add, remove, or refine any?
```

## Step 6: Determine Spike Type

Based on the questions, identify the spike type:

```
Based on these questions, this looks like a [type] spike:
- Technical Feasibility: Can we build X?
- Architecture Decision: How should we design X?
- Third-Party Evaluation: Which tool should we use?
- Performance Investigation: Why is X slow?
- Integration Research: How do we connect to X?

Does that sound right?
```

## Step 7: Document Discovery

Before proceeding, summarize what was learned:

```markdown
## Spike Discovery Summary

**Original Ticket:** [HRZN-XXX] - [vague title]

### Context Captured
- **Trigger:** [What prompted this spike]
- **Prior Knowledge:** [What was already known/suspected]
- **Previous Attempts:** [What's been tried]
- **Constraints:** [Limitations to work within]
- **Key Stakeholders:** [Who has context]

### Clarified Questions
1. [Specific question 1]
2. [Specific question 2]

### Spike Type
[Identified type]

---
Proceeding to investigation...
```

This discovery summary becomes part of the final spike findings, ensuring the context isn't lost.

## When Discovery Doesn't Converge

If after the conversation the spike is still unclear:

1. **Summarize what we learned** - Document even partial understanding
2. **Identify the blocker** - What's preventing clarity?
   - Missing stakeholder input needed
   - Prerequisite knowledge gap
   - Scope is actually multiple spikes
3. **Recommend next steps**:
   ```
   We've had a good discussion but the spike still feels unclear. 
   This might indicate:
   
   1. We need input from [specific person/team]
   2. There's a prerequisite question to answer first
   3. This is actually 2-3 separate spikes
   
   Would you like to:
   - Schedule a conversation with [stakeholder]
   - Create a smaller prerequisite spike first
   - Split this into multiple focused spikes
   ```

## When the User Doesn't Have Context

If the user invoking the spike doesn't have the background context:

1. **Check ticket for clues** - Reporter, linked tickets, comments
2. **Suggest consultation** - "Who created this spike? They may have context."
3. **Offer to proceed with assumptions** - Document assumptions clearly
4. **Partial discovery** - Capture what is known, flag gaps
