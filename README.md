# Workspace Standards

A shared documentation repository for coding standards, architecture patterns, quality scoring, and ways of working across all Pax8 development repositories.

## Quick Start

### Refine a Jira Ticket (Three Amigos)
```
@workspace-standards/skills/refine-ticket/SKILL.md refine ticket HRZN-123
```

### Technical Deep Dive
```
@workspace-standards/skills/technical-deep-dive/SKILL.md investigate [topic] in [repository]
```

### Spike Investigation
```
@workspace-standards/skills/spike/SKILL.md spike HRZN-456
```

### Implement a Refined Ticket
```
@workspace-standards/skills/implement-ticket/SKILL.md implement ticket HRZN-123
```

### Generate Opportunity Brief
```
@workspace-standards/skills/generate-opportunity-brief/SKILL.md Generate an opportunity brief for [feature idea]
```

### Generate PRD from Opportunity Brief
```
@workspace-standards/skills/generate-prd/SKILL.md Generate PRD for [feature name]
```

### Full Idea-to-Implementation Pipeline
```
@workspace-standards/skills/idea-to-implementation/SKILL.md I have a feature idea: [brief description]
```

### Code Review (PR or Branch)
```
@workspace-standards/skills/code-review/SKILL.md review PR 42 in currency-manager
```

### Score a Repository
```
@workspace-standards/skills/score/SKILL.md score the currency-manager repository
```

### Generate PR Description
```
@workspace-standards/skills/generate-pr-description/SKILL.md generate PR description for my current branch
```

### Generate ADR
```
@workspace-standards/skills/generate-adr/SKILL.md generate ADR for the decision to use Kafka in currency-manager
```

### Post-Implementation Review
```
@workspace-standards/skills/post-implementation-review/SKILL.md review how HRZN-123 went
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
├── scripts/                       # Setup and utility scripts
│   └── setup-skills.sh            # Register all skills globally in Cursor
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
@workspace-standards/skills/refine-ticket/SKILL.md refine ticket HRZN-123
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
@workspace-standards/skills/implement-ticket/SKILL.md implement ticket HRZN-123
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
@workspace-standards/skills/technical-deep-dive/SKILL.md investigate [topic] in [repository]
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
@workspace-standards/skills/spike/SKILL.md spike HRZN-456
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
11. **Generate PR Description**: Structured PR body from git and Jira context
12. **Generate ADR**: Architecture Decision Records from spikes or discussions

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

1. Add `~/Development/workspace-standards` to your Cursor workspace
2. Run the setup script to register all skills globally:
   ```bash
   ./scripts/setup-skills.sh
   ```
   This creates symlinks in `~/.cursor/skills/` so all 13 skills are available across every workspace. It also copies Pax8-wide Cursor rules (e.g. Jira custom field standards) to `~/.cursor/rules/`.
3. Restart Cursor (or reload window) — skills will appear in **Settings → Skills**
4. For repo-specific auto-apply rules, copy files from `rules/auto-apply/` to your repo's `.cursor/rules/`
5. See the [Onboarding Guide](docs/onboarding.md) for a full walkthrough
6. See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add new content

## Related Resources

### Ways of Working
- [Onboarding Guide](docs/onboarding.md) - New developer orientation
- [Refinement Best Practices](rules/refinement-best-practices.md) - Three Amigos guide, Definition of Ready
- [Migration Paths](patterns/migration-paths.md) - Legacy to target state transitions
- [Pattern Inventory](patterns/pattern-inventory.md) - Current state of all repos

### Architecture
- [Finance ADRs](../finance/docs/adr/)
- [Role Management ADRs](../role-management/docs/adr/)
- [Engineering Codex](https://github.com/ifarrpax8/engineering-codex) - Technical knowledge base
