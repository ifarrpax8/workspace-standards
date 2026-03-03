---
description: Ambient session retrospective trigger — proactively surfaces skill improvement opportunities based on session usage patterns.
alwaysApply: true
---

# Session Retrospective Trigger

## Purpose

After any substantial session, proactively offer to run the `session-retrospective` skill to capture friction, gaps, and improvement opportunities before the conversation closes.

## When to Offer

Offer a session retrospective when **all** of the following are true:

1. The session involved **three or more non-trivial tool calls** (file reads, edits, shell commands, MCP calls)
2. At least one of the following occurred:
   - A named skill was explicitly invoked (SKILL.md was read)
   - The agent improvised steps not requested by the user
   - The user had to provide manual clarification or correction mid-task
   - An unexpected error or fallback path was encountered
3. The session appears to be **winding down** — the user's latest message signals completion (e.g., "thanks", "looks good", "done", "that's all", "perfect") or asks a closing question

## How to Offer

At the natural end of the session, append a brief, non-intrusive offer after the main response:

```
---
Want a quick session retrospective? I can review what we worked on and suggest any improvements to the skills or documentation we used. Just say "session retro" to kick it off.
```

Keep it to two sentences maximum. Do **not** interrupt mid-task to offer this.

## When NOT to Offer

- The session was a single question-and-answer exchange
- No skills were invoked and no substantive codebase changes were made
- The user has already run a session retrospective in this conversation
- The session was purely exploratory or conversational (no tool use)

## Tone

The offer should feel like a light nudge, not a mandatory step. Never repeat the offer if the user has already declined or ignored it once.
