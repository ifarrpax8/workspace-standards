---
name: pre-qodo-review
description: Same standards stack as code review, plus pr-agent-settings (Qodo) paths and optional Jira AC — works on local branches or uncommitted changes; push and PR are not required.
complexity: medium
prompt-version: "1.1"
---
# Pre-Qodo Review Skill

Code review pass that combines **what Qodo Merge will enforce** (via [pr-agent-settings](https://github.com/pax8/pr-agent-settings)) with **[Code Review](../code-review/SKILL.md)**-class checks (**[code-review.md](../../rules/code-review.md)**, file-type rules, golden paths) and optional **Engineering Codex**. Use it as **part of the normal review workflow** on **any** local changes — including uncommitted or unpushed work. A remote push, open PR, or CI run is **not** required; those are optional ways to supply a diff when convenient.

**Optional Jira:** When a ticket key is provided (or pasted context), add acceptance-criteria alignment. When omitted, skip ticket alignment and still run Pax8 standards + pr-agent-settings Qodo paths (when available).

## Prerequisites

### Repositories and paths

| Path | Purpose | Required? |
|------|---------|-----------|
| **pr-agent-settings** clone in workspace | `metadata.yaml` + `codebase_standards/**` | **Recommended** — without it, skip the Qodo-rules section and note the gap |
| **workspace-standards** (this repo) | `rules/*.md`, golden paths | **Recommended** |
| **engineering-codex** | Facets/experiences for changed areas | Optional |
| **Target app repo(s)** | `git diff` / PR changes | **Required** (local clone or supplied diff) |

### MCP servers

| MCP / access | Tools / usage | Required? |
|--------------|---------------|-----------|
| **Atlassian** (e.g. `plugin-atlassian-atlassian`) | `getJiraIssue` — ticket summary, refinement notes (`description`), repos line | Optional — omit when reviewing without a ticket |
| **GitHub** | PR file list / contents | Optional (`git diff` / local files are enough) |

Use [Jira Standards](../../rules/jira-standards.md): read the native **`description`** field for all issue types.

### Graceful degradation

- **No Jira key / no Jira MCP**: Skip ticket fetch and AC alignment (Phases 2 and 7); continue with pr-agent-settings paths + Pax8 + codex. If the user pastes refinement text later, you can still align to it in a follow-up.
- **No Jira MCP but user has a key**: Ask the user to paste the ticket description; continue.
- **No pr-agent-settings in workspace**: Run Pax8 + codex review only; state clearly that **Qodo rules were not loaded**.
- **Repo key missing from `metadata.yaml`**: Review with Pax8 + codex only for that repo; list the missing key and suggest adding it to pr-agent-settings.

## When to Use

- **Same situations as [Code Review](../code-review/SKILL.md)** — reviewing local changes, a branch, a PR, or a pasted diff — when you also want **pr-agent-settings** (`metadata.yaml` / `best_practices_paths`) loaded so findings match **Qodo** on the eventual PR.
- **Uncommitted or unpushed work** — use `git diff`, `git diff --cached`, or `git diff <base>...HEAD`; no push required.
- **With a ticket** — optional; adds HRZN acceptance-criteria alignment (Phases 2 and 7).

## When NOT to Use

- **You only need Pax8 + golden paths + Codex and do not care about pr-agent-settings Qodo paths** — [Code Review](../code-review/SKILL.md) is sufficient (slightly lighter load).
- **Whole-repo audit** — [Score](../score/SKILL.md); with `engineering-codex` in the workspace, use its **architecture-review** skill on the repo.
- **Test pyramid gap analysis** — [Assess Tests](../assess-tests/SKILL.md).

## Invocation

```
Pre-qodo review
```

```
Pre-qodo review my uncommitted changes
```

```
Pre-qodo review HRZN-123
```

```
Pre-qodo review HRZN-503 in finance-mfe, einvoice-connector
```

```
Pre-qodo review HRZN-123 with base origin/main
```

If the user **names a ticket**, **infer target repos** from the Jira refinement **Repositories** line when possible; if still ambiguous, use the **current working directory’s** git remote name (e.g. `origin` → repo basename) or ask the user. If there is **no ticket**, use the **current repo** (or paths the user specifies).

## Workflow

### Phase 1 — Parse input

1. Extract **Jira issue key** if present (e.g. `HRZN-123`); if **absent**, proceed without ticket context.
2. Optional: **repository keys** for `metadata.yaml` (GitHub repo names: `finance-mfe`, `einvoice-connector`, …); if missing, infer from cwd / remote.
3. Optional: **diff source** — unstaged (`git diff`), staged (`git diff --cached`), branch vs base (`git diff <BASE>...HEAD`), explicit files, or pasted diff. Optional **diff base** (default `origin/main` or `main` when comparing branches — confirm with user if neither exists).

### Phase 2 — Fetch ticket context

**If no Jira key:** Skip this phase; note in the review header **Ticket: none**.

**If Jira key present:**

1. Call Atlassian MCP **`getJiraIssue`** with `cloudId` from accessible resources, `issueIdOrKey`, and fields needed for summary + story panel (or use pasted content if MCP unavailable).
2. From **`description`**, extract:
   - **Repositories** (or equivalent) for scope
   - **Success Criteria / Acceptance Criteria** for alignment checks
3. Summarise **scope** in one short paragraph for the review header.

### Phase 3 — Resolve Qodo rule paths per repo

For each **repository key** that has changes to review:

1. Open **`pr-agent-settings/metadata.yaml`** and find the key (e.g. `finance-mfe`).
2. Read **`best_practices_paths`** for that key.
3. For each path entry, load standards under **`pr-agent-settings/codebase_standards/<path>/`**:
   - Prefer **`best_practices.md`** when present.
   - Include other **`.md`** files in that directory if they exist (do not read unrelated subtrees).

If the repo key is **absent** from `metadata.yaml`, record **SKIPPED (no metadata entry)** for Qodo rules and continue with Pax8-only for that repo.

### Phase 4 — Collect the diff

**Push and PR are not required.** For each target repo (or single repo workspace), obtain changes using **any** of these (prefer what the user asked for):

1. **Uncommitted:** `git diff` (working tree) and/or `git diff --cached` (staged).
2. **Branch vs base:** `git diff <BASE>...HEAD` or merge-base form if the user specifies.
3. **Explicit paths** — file list from the user.
4. **Pasted diff** — if the user provides it.
5. **PR** — if the user names a PR number, use GitHub MCP or `gh` to list changed files and contents.

If there are **no changed files**, stop and ask the user to stage changes, switch branch, set `BASE`, name files, or paste a diff.

### Phase 5 — Pax8 workspace standards

1. Read and apply **[code-review.md](../../rules/code-review.md)** and **[pre-review-checklist.md](../../rules/pre-review-checklist.md)** to the changed files.
2. For each file type present in the diff, load matching rules from **`.cursor/rules/`** (e.g. `vue-standards.md`, `kotlin-standards.md`, `api-standards.md`, `security-standards.md`, `terraform-standards.md`, `playwright-standards.md`, `groovy-standards.md`).

### Phase 6 — Engineering Codex (optional)

If **`engineering-codex`** is in the workspace: for facets/experiences that match the change (API, security, testing, tables, etc.), read only **`best-practices.md`** and **`gotchas.md`** for those topics — not the entire codex.

### Phase 7 — Ticket alignment

**If Phase 2 was skipped:** Skip this phase or state **Ticket alignment: not applicable**.

**Otherwise:** Cross-check the diff against **acceptance / success criteria** from Phase 2. Flag gaps as **(Ticket)**.

### Phase 8 — Deliver the review

Produce **markdown** with:

1. **Context** — Ticket key (or **none**), summary line if applicable, repos reviewed, how the diff was obtained (unstaged, staged, branch vs base, PR, or paste), which standards were loaded (Qodo paths + Pax8 rules + codex topics).
2. **Must fix** — correctness, security, contract/CI breaks, clear AC misses.
3. **Should fix** — maintainability, missing tests for new behaviour, likely Qodo failures.
4. **Nice to have** — style, minor refactors.
5. For **each finding**: file (and line if known), short description, tag **`(Qodo)`**, **`(Pax8)`**, **`(Codex)`**, or **`(Ticket)`** as appropriate.
6. **Likely Qodo hits** — bullet list of what probably still triggers when the change reaches Qodo / the PR if not fixed.
7. **Residual risks / could not assess** — e.g. secrets, integration-only behaviour.

Do **not** commit or push as part of this skill; it is review-only unless the user explicitly asks for fixes in a follow-up.

## Verification

- If a ticket was requested: confirm **Jira** fetch succeeded or user provided paste; if no ticket, note that explicitly.
- Confirm **at least one** changed file or explicit diff (local diff counts).
- Confirm **which** `metadata.yaml` keys were used; if none, state that Qodo rules were not applied.

## Related Resources

- [Pax8 Workflow](../pax8-workflow/SKILL.md) — where this skill fits in the pipeline
- [Code Review](../code-review/SKILL.md) — same Pax8 checklist and phases for standards; use when you **do not** need pr-agent-settings Qodo paths. **Either** skill supports **local-only** review (no push).
- [Generate PR Description](../generate-pr-description/SKILL.md) — after fixes, for PR body
- [Implement Ticket](../implement-ticket/SKILL.md) — Phase 5 self-review; run this skill before opening PR for a stricter Qodo-aligned pass
- [Jira Standards](../../rules/jira-standards.md)
- [pr-agent-settings AI_AGENTS.md](https://github.com/pax8/pr-agent-settings/blob/main/AI_AGENTS.md) — maintaining Qodo standards content
