# Onboarding Guide

Quick orientation for new developers joining the team. This guide helps you set up your environment, learn the tools, and understand the workflows.

## Step 1: Add Workspace Standards to Cursor

Add `~/Development/workspace-standards` to your Cursor workspace. This gives you access to all rules, skills, and golden paths.

Optionally, also add:
- `~/Development/engineering-codex` — Best practices, architecture patterns, technology options
- `~/Development/adr` — Pax8 Architecture Decision Records

## Step 2: Register Skills Globally

Run the setup script to make all skills available across every Cursor workspace:

```bash
cd ~/Development/workspace-standards
./scripts/setup-skills.sh
```

This creates symlinks from `~/.cursor/skills/` to the workspace-standards skills directory. After running, restart Cursor (or reload the window). You should see all 13 skills in **Settings → Skills**.

The script also copies Pax8-wide Cursor rules (like Jira custom field standards) to `~/.cursor/rules/` so they apply globally.

> **Re-run after pulling updates.** If new skills are added to workspace-standards, run the setup script again to pick them up.

## Step 3: Copy Auto-Apply Rules

Copy the relevant auto-apply rules to your repository's `.cursor/rules/` directory:

| If your repo is... | Copy these rules |
|---------------------|------------------|
| Kotlin (Spring Boot) | `kotlin-standards.md`, `security-standards.md`, `jira-standards.md` |
| Kotlin (Axon) | `kotlin-standards.md`, `security-standards.md`, `jira-standards.md` |
| Vue MFE | `vue-standards.md`, `security-standards.md`, `jira-standards.md` |
| Terraform | `terraform-standards.md`, `security-standards.md` |
| Playwright tests | `playwright-standards.md` |

Rules live in `rules/auto-apply/`. Copy them to your repo:

```bash
cp ~/Development/workspace-standards/rules/auto-apply/kotlin-standards.md .cursor/rules/
cp ~/Development/workspace-standards/rules/auto-apply/security-standards.md .cursor/rules/
cp ~/Development/workspace-standards/rules/auto-apply/jira-standards.md .cursor/rules/
```

## Step 4: Learn the Golden Path for Your Project

Read the golden path that matches your repository:

| Repository | Golden Path |
|-----------|-------------|
| currency-manager, report-manager | [Kotlin Spring Boot](../golden-paths/kotlin-spring-boot.md) |
| einvoice-connector | [Kotlin Axon CQRS](../golden-paths/kotlin-axon-cqrs.md) |
| finance-mfe, order-management-mfe | [Vue MFE](../golden-paths/vue-mfe.md) |
| role-management | [Terraform IaC](../golden-paths/terraform-iac.md) |
| finance (integration tests) | [Integration Testing](../golden-paths/integration-testing.md) |
| pax8/console | [Groovy Monolith](../golden-paths/groovy-monolith.md) |

Golden paths define the expected package structure, layer responsibilities, testing strategy, and common patterns.

## Step 5: Understand the Workflow

The team uses these skills for daily work:

### When Starting a Ticket

```
@workspace-standards/skills/refine-ticket/SKILL.md refine ticket HRZN-123
```

This runs a Three Amigos analysis (Developer, Test, Product perspectives), calculates a confidence score, and generates an implementation plan.

### When Implementing

```
@workspace-standards/skills/implement-ticket/SKILL.md implement ticket HRZN-123
```

This validates Definition of Ready, loads standards, guides TDD, handles unknowns, runs self-review, and posts a summary to Jira.

### When You Hit a Technical Unknown

```
@workspace-standards/skills/technical-deep-dive/SKILL.md investigate [topic] in [repository]
```

This explores the codebase, finds patterns, references golden paths, and produces a technical recommendation.

### When Reviewing Code

```
@workspace-standards/skills/code-review/SKILL.md review PR 42 in currency-manager
```

This applies the team's code review checklist against the PR changes and produces structured feedback.

### When You Need to Research

```
@workspace-standards/skills/spike/SKILL.md spike HRZN-456
```

This runs a structured investigation with success criteria, documents findings, and posts results to Jira.

## Step 6: Score Your Repository

Run the scoring script to see where your repository stands:

```bash
cd ~/Development/workspace-standards
./scoring/score.sh ../currency-manager
```

Or use the interactive skill:

```
@workspace-standards/skills/score/SKILL.md score the currency-manager repository
```

This evaluates 8 categories (Architecture, Testing, Security, Code Quality, Documentation, Consistency, Dependencies, Observability) and generates a report with recommendations.

## Step 7: Browse the Full Skill Pipeline

For larger features, the full pipeline orchestrates the entire flow:

```
Idea → Opportunity Brief → PRD → Spike → Story Breakdown → Refine → Implement → Code Review → Post-Implementation Review
```

Invoke it with:

```
@workspace-standards/skills/idea-to-implementation/SKILL.md I have a feature idea: [description]
```

## Quick Reference

| I want to... | Use this |
|--------------|----------|
| Refine a ticket | `skills/refine-ticket/SKILL.md` |
| Implement a ticket | `skills/implement-ticket/SKILL.md` |
| Investigate code | `skills/technical-deep-dive/SKILL.md` |
| Run a spike | `skills/spike/SKILL.md` |
| Review a PR | `skills/code-review/SKILL.md` |
| Score a repo | `skills/score/SKILL.md` |
| Generate a PR description | `skills/generate-pr-description/SKILL.md` |
| Generate an ADR | `skills/generate-adr/SKILL.md` |
| Full feature pipeline | `skills/idea-to-implementation/SKILL.md` |
| Quick ticket breakdown | `rules/refinement.md` |
| Code review checklist | `rules/code-review.md` |

## Further Reading

- [Pattern Inventory](../patterns/pattern-inventory.md) — Current state of all repositories
- [Migration Paths](../patterns/migration-paths.md) — How we're evolving the architecture
- [Security Checklist](../security/security-checklist.md) — Security requirements for all projects
- [Refinement Best Practices](../rules/refinement-best-practices.md) — Three Amigos guide
- [CONTRIBUTING.md](../CONTRIBUTING.md) — How to add to this repository
