---
name: pax8-workflow
description: Pax8 agentic workflow orchestrator — when to use which skill, Jira + local plans, Superpowers, Qodo shift-left, GitHub access, retrospectives, and prerequisites. Use when unsure which skill to run next or onboarding to the full pipeline.
complexity: high
prompt-version: "1.0"
---

# Pax8 Workflow Skill

Single entry point for **which Pax8 skill to use when**, how **Superpowers** fits, **Jira vs local specs**, **Qodo (pr-agent-settings)**, **GitHub access**, and the **self-improving loop** (retrospectives). Authoritative copy lives in workspace-standards; link here from other repos rather than duplicating long tables.

## Instruction priority

1. **User's explicit instructions** (per-chat, project `AGENTS.md`, user rules) — highest
2. **Team standards** (workspace-standards, engineering-codex when in workspace)
3. **Default skill behavior** — lowest

If Superpowers skills conflict with Pax8 skills on process, **user instructions win**, then team `AGENTS.md`, then skills.

## Prerequisites checklist

Before relying on the full workflow, confirm:

- [ ] **[workspace-standards](https://github.com/pax8/workspace-standards)** cloned and on disk (this repo — skills and rules)
- [ ] **[engineering-codex](https://github.com/pax8/engineering-codex)** in workspace when you need facets, checklists, `pax8-context/`, or tech radar
- [ ] **Target application repository(ies)** in the workspace for implementation
- [ ] **Atlassian MCP** (`user-mcp-atlassian`) for Jira/Confluence when skills need live tickets — or be ready to paste ticket content
- [ ] **Superpowers** (optional) — Cursor plugin for `writing-plans`, TDD, debugging, verification skills; layer on top of Pax8 skills where useful
- [ ] **[pr-agent-settings](https://github.com/pax8/pr-agent-settings)** — clone or reference when working with **Qodo Merge** rules (`metadata.yaml` maps repos to `codebase_standards/**`)
- [ ] **devlab** (optional) — containerized dev from [devlab](https://github.com/pax8/devlab); `~/Development` mount keeps the same repos; `make sync-all` can sync agents to `~/.cursor/` (additive to repo skills)
- [ ] **GitHub access** — see [GitHub access](#github-access-mcp-gh-cli-clones); MCP may be limited for private `pax8` org repos

## Mental model: Pax8 vs Superpowers

- **Pax8 skills (workspace-standards)** — *what* to do for HRZN/Pax8 delivery: refine, implement, spike, code review, ADRs, Jira field conventions.
- **Superpowers** — *how* to execute with discipline: brainstorm before big changes, **writing-plans** for bite-sized plans, TDD, systematic debugging, verification-before-completion, parallel subagents when independent.

Invoke Pax8 skills with `@workspace-standards/.cursor/skills/.../SKILL.md` (or your clone path). Layer Superpowers when the task matches (e.g. multi-step feature → `writing-plans` + `implement-ticket`).

## Skill orchestrator (scenarios → skills)

| Scenario | Primary Pax8 skill | Superpowers / other |
| -------- | ------------------- | ------------------- |
| New feature from scratch | [idea-to-implementation](../idea-to-implementation/SKILL.md) | brainstorming → writing-plans |
| Ticket needs Three Amigos | [refine-ticket](../refine-ticket/SKILL.md) | — |
| Time-boxed research + Jira deliverables | [spike](../spike/SKILL.md) | — |
| Codebase / pattern questions | [technical-deep-dive](../technical-deep-dive/SKILL.md) | explore subagent (per that skill) |
| Refined story, implement | [implement-ticket](../implement-ticket/SKILL.md) | TDD, verification-before-completion |
| Bug | [fix-bug](../fix-bug/SKILL.md) | systematic-debugging |
| After merge / shipped | [post-implementation-review](../post-implementation-review/SKILL.md) | [session-retrospective](../session-retrospective/SKILL.md) for process tweaks |
| Many independent failures | — | dispatching-parallel-agents |
| PR body | [generate-pr-description](../generate-pr-description/SKILL.md) | — |
| Document a decision | [generate-adr](../generate-adr/SKILL.md) | ADR repo + codex `sync-pax8-adrs` skill if used |
| Pre-PR automated review | Qodo (see [Qodo and pr-agent-settings](#qodo-and-pr-agent-settings)) | Then [code-review](../code-review/SKILL.md) |

## Spec-driven stack: Jira + local plans

- **Jira** is **canonical** for HRZN: stories use `customfield_12636` (see [jira-standards](../../rules/jira-standards.md)). Refinement, acceptance criteria, and DoR for [implement-ticket](../implement-ticket/SKILL.md) live there.
- **Local markdown** helps across sessions and fast iteration: optional plan under `docs/superpowers/plans/YYYY-MM-DD-<feature>.md` (Superpowers default) or your repo’s convention.

**Local plan file header (suggested lines):**

- `Jira: HRZN-xxx`
- Last synced from Jira: (date you copied context)

**Greenfield:** [idea-to-implementation](../idea-to-implementation/SKILL.md) runs Brief → PRD → stories. Use **writing-plans** when you need file-level steps in the app repo.

## Qodo and pr-agent-settings

- [pr-agent-settings](https://github.com/pax8/pr-agent-settings) configures **Qodo Merge**: `metadata.yaml` lists `best_practices_paths` per repository; standards live under `codebase_standards/`.
- **Placement:** after implementation and tests, **before** push/open PR — run your org’s Qodo entrypoint on the **branch or diff** (CLI, IDE, or GitHub App — **confirm the one sentence** your org uses and put it in team docs if not here).
- Qodo enforces those rules; the [code-review](../code-review/SKILL.md) skill is the **human/agent** checklist — complementary.
- **Context:** do not load the entire pr-agent-settings tree for every review — only when **editing** metadata or standards. Daily review uses the tool + local clone as needed.
- **Maintaining** standards content: see pr-agent-settings `AI_AGENTS.md` and devlab’s Qodo-related agents.

### Pre-PR bundle (suggested order)

1. **Qodo** against the diff (rules from pr-agent-settings via `metadata.yaml`).
2. [code-review](../code-review/SKILL.md) skill on the change.
3. [generate-pr-description](../generate-pr-description/SKILL.md) for the PR body.

Order is suggestive — adapt to team practice.

## GitHub access: MCP, gh CLI, clones

Private **pax8** org repos often fail **GitHub MCP** (`user-github`) until tokens and SSO align. Treat **local clones** in `~/Development` as the reliable default for navigation and search.

**Spike checklist (record your org’s results in team notes or next skill revision):**

1. **Fine-grained PAT:** org access + **Configure SSO** for the Pax8 org if required.
2. **MCP:** exercise `search_code` and `get_file_contents` on a known private repo; note error strings if any.
3. **`gh` CLI** in the terminal (`gh auth status`, `gh api`, `gh pr diff`) — narrow output, works when MCP does not.
4. **Browser MCP** — authenticated GitHub web search (see [technical-deep-dive](../technical-deep-dive/SKILL.md)).

Even with working MCP, heavy exploration stays in **local clones**; MCP is for targeted remote reads.

## Subagents

Cursor can delegate to **Task** / explore-style workers so exploration returns a **summary** without filling the main context. [technical-deep-dive](../technical-deep-dive/SKILL.md) instructs using the explore subagent for investigation. Skills cannot spawn subagents unless the runtime supports delegation and the model follows the skill.

## Self-improving loop: when to run retrospectives

| Skill | Trigger | Minimum bar |
| ----- | ------- | ----------- |
| [post-implementation-review](../post-implementation-review/SKILL.md) | PR **merged** or ticket **Done** with deploy | Once per ticket or feature slice, not every commit |
| [session-retrospective](../session-retrospective/SKILL.md) | End of focused session, or weekly batch | After heavy sessions (spike, large refactor, painful debug) |

**Forget-proofing:** project `.cursor/rules` can suggest these when the user says they merged, closed a ticket, or are done for the day; PR/Jira DoD checkboxes optional; [implement-ticket](../implement-ticket/SKILL.md) may offer a **skippable** one-line reminder after work completes.

**Capture:** one concrete improvement per cycle into workspace-standards when it helps the team. Revisit this orchestrator table **quarterly** or when tools (Superpowers, MCP, Qodo) change.

## Start here (onboarding)

1. Add **workspace-standards**, **engineering-codex**, and your **app repo** to the Cursor workspace.
2. Enable **Atlassian MCP** (and GitHub MCP if available).
3. Open this skill: `@workspace-standards/.cursor/skills/pax8-workflow/SKILL.md`.
4. Dry run: `@refine-ticket` with a ticket key, or paste ticket text if MCP is off.

## Lunch-and-learn outline (30–45 min)

- Show [idea-to-implementation](../idea-to-implementation/SKILL.md) for greenfield vs jumping to [implement-ticket](../implement-ticket/SKILL.md) when the ticket is already refined.
- Show Superpowers **writing-plans** for a repo-local implementation plan.
- Show where **Jira** (`customfield_12636`) vs **local plan file** fit.

## MCP health (~30 seconds)

- Atlassian: can you call Jira tools or paste content?
- GitHub: MCP works, or run `gh auth status`?
- If both fail for remote: use **local clones** + **browser MCP** for GitHub web as last resort.

## Troubleshooting

| Symptom | Action |
| ------- | ------ |
| Wrong or empty Jira description | Read [jira-standards](../../rules/jira-standards.md); stories use **customfield_12636**. |
| Refinement missing | Run [refine-ticket](../refine-ticket/SKILL.md) before implement-ticket. |
| Superpowers vs Pax8 conflict | User rules → team AGENTS → skills. |

## Multi-repo or contract changes

Use [spike](../spike/SKILL.md) or [technical-deep-dive](../technical-deep-dive/SKILL.md) across repos. Prefer **one PR per repo** or coordinated PRs with clear ordering; use [generate-pr-description](../generate-pr-description/SKILL.md) per repo as needed.

## Security (minimal)

- Do not stringify full `process.env` in bundler config (see team rsbuild/Vite rules).
- Do not paste secrets into chat or commit them.

## When to write an ADR

After a spike or architecture fork with a durable decision, use [generate-adr](../generate-adr/SKILL.md) and the **adr** repository; keep pointers short — do not duplicate full ADR policy here.

## Async handoff

If another developer continues the work: put **Jira key** and **last-synced date** in the local plan header; note **assignee change** in Jira.

## Meta

- **Review this skill quarterly** or when Cursor / Superpowers / MCP / Qodo behavior shifts materially.
- **`prompt-version`** in frontmatter tracks iterations.

## Invocation

```
@workspace-standards/.cursor/skills/pax8-workflow/SKILL.md
```

Or: “Which skill should I use for [scenario]?”

## Related skills

- [idea-to-implementation](../idea-to-implementation/SKILL.md) — full pipeline orchestrator
- [implement-ticket](../implement-ticket/SKILL.md) — implementation with DoR/DoD
- [refine-ticket](../refine-ticket/SKILL.md) — Three Amigos
- [session-retrospective](../session-retrospective/SKILL.md) — improve skills and process
