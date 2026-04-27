# Workspace Standards

A shared documentation repository for coding standards, architecture patterns, quality scoring, and ways of working across all Pax8 development repositories.

## Quick Start

### Refine a Jira Ticket (Three Amigos)
```
@workspace-standards/.cursor/skills/refine-ticket/SKILL.md refine ticket HRZN-123
```

### Technical Deep Dive
```
@workspace-standards/.cursor/skills/technical-deep-dive/SKILL.md investigate [topic] in [repository]
```

### Spike Investigation
```
@workspace-standards/.cursor/skills/spike/SKILL.md spike HRZN-456
```

### Implement a Refined Ticket
```
@workspace-standards/.cursor/skills/implement-ticket/SKILL.md implement ticket HRZN-123
```

### Generate Opportunity Brief
```
@workspace-standards/.cursor/skills/generate-opportunity-brief/SKILL.md Generate an opportunity brief for [feature idea]
```

### Generate PRD from Opportunity Brief
```
@workspace-standards/.cursor/skills/generate-prd/SKILL.md Generate PRD for [feature name]
```

### Full Idea-to-Implementation Pipeline
```
@workspace-standards/.cursor/skills/idea-to-implementation/SKILL.md I have a feature idea: [brief description]
```

### Code Review (PR or Branch)
```
@workspace-standards/.cursor/skills/code-review/SKILL.md review PR 42 in currency-manager
```

### Assess Test Completeness
```
@workspace-standards/.cursor/skills/assess-tests/SKILL.md assess tests for the invoice aggregate in einvoice-connector
```

### Score a Repository
```
@workspace-standards/.cursor/skills/score/SKILL.md score the currency-manager repository
```

### Generate PR Description
```
@workspace-standards/.cursor/skills/generate-pr-description/SKILL.md generate PR description for my current branch
```

### Generate ADR
```
@workspace-standards/.cursor/skills/generate-adr/SKILL.md generate ADR for the decision to use Kafka in currency-manager
```

### Post-Implementation Review
```
@workspace-standards/.cursor/skills/post-implementation-review/SKILL.md review how HRZN-123 went
```

### Quick Refinement Helper
```
@workspace-standards/rules/refinement.md help me break down <ticket-id>
```

### Run Codebase Scoring (CLI)
```bash
cd ~/Development/workspace-standards
./scoring/score.sh ../currency-manager
```

## Directory Structure

```
workspace-standards/
├── README.md                      # This file
├── CONTRIBUTING.md                # How to add rules, skills, golden paths
├── CHANGELOG.md                   # Change history
├── docs/
│   └── onboarding.md              # New developer orientation guide
├── golden-paths/                  # Reference architectures
│   ├── kotlin-spring-boot.md      # Standard layered architecture
│   ├── kotlin-axon-cqrs.md        # Event sourcing + CQRS
│   ├── vue-mfe.md                 # Feature-based MFE
│   ├── terraform-iac.md           # Infrastructure as Code (Terraform)
│   ├── integration-testing.md     # Playwright page object model (E2E)
│   └── groovy-monolith.md         # Legacy monolith working standards
├── scoring/                       # Automated scoring system
│   ├── score.sh                   # Main scoring script
│   ├── criteria/                  # Scoring rubrics (8 categories)
│   └── reports/                   # Generated score reports
├── skills/                        # Interactive Cursor skills
│   ├── idea-to-implementation/    # End-to-end pipeline orchestrator
│   │   └── SKILL.md               # Idea → Brief → PRD → ... → Review (9 stages)
│   ├── generate-opportunity-brief/# Draft Pax8 Opportunity Briefs
│   │   └── SKILL.md               # Codex-enriched brief generation
│   ├── generate-prd/              # Draft Pax8 PRDs from Opp Briefs
│   │   └── SKILL.md               # Standards-aware PRD generation
│   ├── refine-ticket/             # Three Amigos ticket refinement
│   │   └── SKILL.md               # Jira integration, confidence scoring
│   ├── implement-ticket/          # Structured implementation workflow
│   │   └── SKILL.md               # DoR/DoD gates, TDD, unknowns triage
│   ├── code-review/               # Standalone PR/branch review
│   │   └── SKILL.md               # Standards-based review with structured feedback
│   ├── post-implementation-review/# Closing the feedback loop
│   │   └── SKILL.md               # Estimate accuracy, learnings, action items
│   ├── score/                     # Interactive repository scoring
│   │   └── SKILL.md               # Run score.sh with interpretation and fixes
│   ├── generate-pr-description/   # PR description from implementation context
│   │   └── SKILL.md               # Structured PR body from git + Jira context
│   ├── generate-adr/              # Architecture Decision Records
│   │   └── SKILL.md               # ADR generation from spikes or discussions
│   ├── technical-deep-dive/       # Codebase investigation
│   │   └── SKILL.md               # Pattern analysis, code locations
│   └── spike/                     # Time-boxed research
│       └── SKILL.md               # Investigation, findings, follow-ups
├── rules/                         # Cursor rules
│   ├── code-review.md             # Manual: PR review checklist
│   ├── refinement.md              # Quick: ticket breakdown template
│   ├── refinement-best-practices.md  # Comprehensive: Three Amigos guide
│   └── auto-apply/                # Copy to each repo's .cursor/rules/
│       ├── kotlin-standards.md
│       ├── vue-standards.md
│       ├── terraform-standards.md
│       ├── playwright-standards.md
│       ├── security-standards.md
│       └── jira-standards.md
├── patterns/                      # Pattern documentation
│   ├── pattern-inventory.md       # Current state of all repos
│   └── migration-paths.md         # Legacy to target state transitions
├── .cursor/
│   ├── skills/                    # Cursor skills (auto-discovered)
│   ├── agents/                    # Custom subagents (auto-discovered)
│   │   ├── standards-auditor.md   # Repo scoring and compliance auditing
│   │   └── ticket-refiner.md      # Jira ticket refinement assistant
│   └── rules/                     # Auto-discovered global rules
│       ├── jira-standards.md
│       └── security-standards.md
├── .agents/
│   └── skills -> .cursor/skills   # Augment skill discovery (symlink)
├── .augment/
│   └── rules -> .cursor/rules     # Augment rule discovery (symlink)
├── AGENTS.md                      # Cross-tool project context
└── security/                      # Security guidelines
    └── security-checklist.md      # Requirements and packages
```

## Scoring Categories

The automated scoring evaluates repositories across 8 categories (100 points total):

| Category | Points | Description |
|----------|--------|-------------|
| Architecture | 13 | Package structure, pattern adherence, separation of concerns |
| Testing | 13 | Coverage %, test existence, naming conventions |
| Security | 14 | No secrets, security packages, auth patterns |
| Code Quality | 13 | Linter config, complexity, naming |
| Documentation | 10 | README, ADRs, inline docs |
| Consistency | 13 | Pattern uniformity within repo |
| Dependencies | 14 | Up-to-date deps, no vulnerabilities |
| Observability | 10 | Logging, metrics, tracing setup |

## Skills (Ways of Working)

Interactive skills for team processes and workflows.

### Refine Ticket Skill

Three Amigos-style ticket refinement with Jira integration:

```
@workspace-standards/.cursor/skills/refine-ticket/SKILL.md refine ticket HRZN-123
```

**Features:**
- Auto-fetches Jira ticket details and linked PRD from Confluence
- Analyzes from Developer, Test, and Product perspectives
- Calculates confidence score (1-12) based on requirements, technical clarity, test coverage, and dependencies
- Recommends Fibonacci estimate
- Posts implementation plan as Jira comment

**Confidence Scoring:**
| Score | Level | Action |
|-------|-------|--------|
| 10-12 | High | Ready for sprint |
| 7-9 | Medium | Proceed with documented unknowns |
| 4-6 | Low | Needs technical deep dive or clarification |
| 1-3 | Not Ready | Do not commit to sprint |

### Implement Ticket Skill

Structured implementation workflow for refined tickets:

```
@workspace-standards/.cursor/skills/implement-ticket/SKILL.md implement ticket HRZN-123
```

**Features:**
- Validates Definition of Ready before starting (with abandon/proceed choice)
- Loads codebase standards and golden paths for the target repository
- Pragmatic TDD with red-green-refactor cycles where appropriate
- Guided triage for unknown unknowns with cumulative scope monitoring
- Self-review against code-review.md before final commit
- Definition of Done gate before Jira update
- Posts implementation summary with test evidence and QA handoff notes

**Workflow Phases:**
1. Fetch and Validate DoR
2. Setup (standards, branch creation)
3. Plan and TDD Assessment
4. Implementation Loop (with unknowns triage)
5. Self-Review
6. Definition of Done
7. Jira Update

### Technical Deep Dive Skill

Codebase investigation for resolving technical unknowns:

```
@workspace-standards/.cursor/skills/technical-deep-dive/SKILL.md investigate [topic] in [repository]
```

**Features:**
- Explores codebase to find relevant files and patterns
- References golden paths for architecture alignment
- Identifies specific code locations to modify
- Suggests patterns to follow with code examples
- Creates draft ADRs for architecture decisions

**Use Cases:**
- Low technical confidence during refinement
- Unfamiliar codebase exploration
- Quick technical questions (hours, not days)

### Spike Skill

Time-boxed research and investigation:

```
@workspace-standards/.cursor/skills/spike/SKILL.md spike HRZN-456
```

**Features:**
- Structured investigation with success criteria
- Supports all spike types (feasibility, architecture, third-party, performance, integration)
- Documents findings with recommendations and trade-offs
- Handles partial/inconclusive results with follow-up spike creation
- Posts findings as Jira comment

**Use Cases:**
- Technical feasibility research
- Architecture decision exploration
- Third-party tool evaluation
- Performance investigation
- Integration research

### Skill Connection

The skills can be used standalone or chained via the **Idea to Implementation** orchestrator (9 stages):

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Opp Brief  │───▶│     PRD      │───▶│    Spike     │
│  Generation  │    │  Generation  │    │ (if needed)  │
└──────────────┘    └──────────────┘    └──────────────┘
                                               │
                                               ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Implement   │◀───│   Refine     │◀───│    Story     │
│   Ticket     │    │   Ticket     │    │  Breakdown   │
└──────────────┘    └──────────────┘    └──────────────┘
       │                   │
       ▼                   ▼
┌──────────────┐    ┌──────────────┐
│  Code Review │    │  Deep Dive   │
│  + PR Desc   │    │(low confid.) │
└──────────────┘    └──────────────┘
       │
       ▼
┌──────────────┐
│  Post-Impl   │
│  Review      │
└──────────────┘
```

**Pipeline skills (chained by orchestrator):**
1. **Idea to Implementation**: Full 9-stage pipeline orchestrator
2. **Generate Opp Brief**: Draft a Pax8 Opportunity Brief enriched with codex content
3. **Generate PRD**: Expand approved brief into PRD with Pax8 standards and decisions
4. **Spike**: Time-boxed research (days) for unknowns identified in the PRD
5. **Refine Ticket**: Three Amigos analysis with confidence scoring
6. **Implement Ticket**: Structured implementation with DoR/DoD gates
7. **Code Review**: Standards-based PR review with structured feedback
8. **Post-Implementation Review**: Estimate accuracy, learnings, feedback loop

**Utility skills (standalone):**
9. **Deep Dive**: Quick codebase investigation (hours) when technical confidence is low
10. **Score**: Interactive repository scoring with actionable recommendations
11. **Assess Tests**: Test completeness audit across the test pyramid with gap analysis
12. **Generate PR Description**: Structured PR body from git and Jira context
13. **Generate ADR**: Architecture Decision Records from spikes or discussions

### Engineering Codex Integration

All workflow skills optionally leverage the [Engineering Codex](https://github.com/ifarrpax8/engineering-codex) when it's in the workspace — best practices, gotchas, decision frameworks, Pax8 standards, and tech radar data. Add the codex to your workspace for the full experience; all skills degrade gracefully without it.

## Golden Path Architectures

### Backend (Kotlin)

**Standard Layered** (currency-manager, report-manager):
- `endpoint/` → `service/` → `repository/`
- Suitable for simpler CRUD-style services

**Event Sourcing + CQRS** (einvoice-connector):
- Axon Framework with commands, events, sagas
- For audit-critical, complex domain logic
- Reference: [finance ADR-0002](../finance/docs/adr/0002-event-sourcing.md)

### Frontend (Vue 3 MFE)

**Feature-Based Architecture** (finance-mfe, order-management-mfe):
- `components/` grouped by feature domain
- `composables/` for reusable logic
- `services/` for API layer
- Pinia for state management

## Getting Started

Clone `workspace-standards` alongside your existing project repos — all three tools discover content from a shared parent directory:

```
<your-dev-folder>/
├── workspace-standards/   ← this repo
├── my-service/
├── my-mfe/
└── engineering-codex/     ← optional but recommended
```

### Step 1 — Clone the repos

```bash
cd <your-dev-folder>
git clone <workspace-standards-url> workspace-standards
git clone <engineering-codex-url> engineering-codex   # optional
```

### Step 2 — Run setup

```bash
bash workspace-standards/scripts/setup.sh
```

That's it for Claude Code. The script self-locates — it works regardless of where your development folder lives. It:

- Links all skills into `.claude/skills/` (Claude Code) and `.agents/skills/` (Augment)
- Writes the `SessionStart` hook into `.claude/settings.json` with the correct absolute path
- Creates a starter `CLAUDE.md` in the parent directory if one doesn't exist

**Re-run whenever you add a new repository that contains `.cursor/skills/`.**

### Step 3 — Edit your CLAUDE.md

The starter `CLAUDE.md` is created one level above `workspace-standards/`. Uncomment the rules that apply to your stack:

```markdown
@workspace-standards/.cursor/rules/security-standards.md
@workspace-standards/.cursor/rules/kotlin-standards.md     # if Kotlin
@workspace-standards/.cursor/rules/vue-standards.md        # if Vue
@workspace-standards/.cursor/rules/playwright-standards.md # if Playwright
@engineering-codex/.cursor/rules/security-gotchas.md       # if codex cloned
```

Rules prefixed `@` are loaded into every Claude Code session opened in that directory or any subdirectory.

### Step 4 — Wire up Cursor

1. Add `<your-dev-folder>/workspace-standards` to your Cursor workspace
2. Optionally add `<your-dev-folder>/engineering-codex`
3. Reload the Cursor window — skills, subagents, and rules auto-discovered from `.cursor/`

For Augment parity in a project repo, symlink its rule directory:

```bash
ln -s ../.cursor/rules my-repo/.augment/rules
```

### Step 5 — Wire up Augment

1. Add `<your-dev-folder>/workspace-standards` to your Augment workspace
2. Skills auto-discovered from `.agents/skills/` — use `/skills` to browse
3. Rules auto-loaded from `.augment/rules/` and `AGENTS.md`
4. Configure MCP servers (Jira, GitHub) for full skill functionality — all skills degrade gracefully without them

### Skills and Subagents

Skills follow the [agentskills.io](https://agentskills.io/) specification and are auto-discovered by Cursor, Augment, and Claude Code. No manual registration required.

| Type | Claude Code | Cursor | Augment |
|------|-------------|--------|---------|
| Skills | `.claude/skills/` symlinks | `.cursor/skills/` | `.agents/skills/` |
| Rules | `CLAUDE.md` @imports | `.cursor/rules/` | `.augment/rules/` + `AGENTS.md` |
| Subagents | — | `.cursor/agents/` | — |

**Claude Code**: Invoke skills with `/skill-name` in the chat.

**Cursor**: Invoke subagents explicitly with `/standards-auditor`, `/ticket-refiner`, or let the agent delegate automatically.

**Augment**: Use `/skills` to browse, then invoke by describing the task (e.g. "refine ticket HRZN-123").

## Related Resources

### Ways of Working
- [Onboarding Guide](docs/onboarding.md) - New developer orientation
- [Refinement Best Practices](references/refinement-best-practices.md) - Three Amigos guide, Definition of Ready
- [Migration Paths](patterns/migration-paths.md) - Legacy to target state transitions
- [Pattern Inventory](patterns/pattern-inventory.md) - Current state of all repos

### Architecture
- [Finance ADRs](../finance/docs/adr/)
- [Role Management ADRs](../role-management/docs/adr/)
- [Engineering Codex](https://github.com/ifarrpax8/engineering-codex) - Technical knowledge base
