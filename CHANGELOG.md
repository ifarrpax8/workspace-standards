# Changelog

All notable changes to the Workspace Standards repository.

## 2026-02-09 (v2)

### New Skills
- Added `skills/code-review/SKILL.md` — Standalone interactive PR/branch review against team standards, golden paths, and codex
- Added `skills/post-implementation-review/SKILL.md` — Closing-the-loop skill capturing estimate accuracy, learnings, and action items
- Added `skills/score/SKILL.md` — Interactive repository scoring with interpretation and actionable fix recommendations
- Added `skills/generate-pr-description/SKILL.md` — Structured PR description generation from git and Jira context
- Added `skills/generate-adr/SKILL.md` — Architecture Decision Record generation from spikes or discussions

### New Golden Paths
- Added `golden-paths/groovy-monolith.md` — Working standards for the pax8/console legacy codebase (Groovy/Java, Grails-style)

### New Auto-Apply Rules
- Added `rules/auto-apply/terraform-standards.md` — Terraform IaC standards with module structure, naming, and state management
- Added `rules/auto-apply/playwright-standards.md` — Playwright E2E testing standards with Page Object Model and fixture patterns

### New Documentation
- Added `CONTRIBUTING.md` — Guidelines for adding rules, skills, golden paths, and scoring criteria
- Added `docs/onboarding.md` — New developer orientation guide with quick-start setup

### Orchestrator Update
- Updated `idea-to-implementation` pipeline from 7 to 9 stages (added Code Review and Post-Implementation Review)
- Added `generate-pr-description` and `generate-adr` as utility skills in the pipeline

### Scoring Improvements
- Added "Golden Path References" section to all 8 scoring criteria files, cross-referencing specific golden path sections

## 2026-02-09

### Engineering Codex Integration
- All four workflow skills (`refine-ticket`, `implement-ticket`, `spike`, `technical-deep-dive`) now optionally leverage the Engineering Codex when available in the workspace
- Skills check codex facets for best practices, gotchas, options, and Pax8 standards before falling back to web search
- Falls back to previous behaviour (golden paths + web search) when the codex is not in the workspace

### Quality Review Fixes
- Fixed spike SKILL.md MCP prerequisites table — blockquote was interrupting table rows
- Fixed README scoring table — updated from 7 to 8 categories with correct weights (added Observability)
- Fixed score.sh header comment to reflect 8 categories
- Fixed score report generation — recommendations section no longer produces empty lines for passing categories
- Aligned security-checklist.md with security-standards.md — DOMPurify is now the sole recommended sanitization library
- Clarified relationship between `refinement.md` (quick template) and `refinement-best-practices.md` (comprehensive guide)

### New Golden Paths
- Added `golden-paths/terraform-iac.md` — Terraform Infrastructure as Code golden path covering module structure, state management, environment promotion, security, testing, and CI/CD
- Added `golden-paths/integration-testing.md` — Playwright integration testing golden path covering Page Object Model, fixtures, authentication, API testing, and CI configuration

### New Patterns
- Added `patterns/migration-paths.md` — documented transition strategies for 5 migration paths: monolith to microservices, flat to domain-focused, adding CQRS, frontend alignment, and testing maturity

### Added
- `CHANGELOG.md` — this file

## 2026-02-08

### Idea-to-Implementation Pipeline
- Added `skills/idea-to-implementation/SKILL.md` — end-to-end orchestrator skill chaining opportunity brief, PRD, spike, story breakdown, refinement, and implementation
- Added `skills/generate-opportunity-brief/SKILL.md` — Pax8 Opportunity Brief generation skill (moved from engineering-codex)
- Added `skills/generate-prd/SKILL.md` — Pax8 PRD generation skill (moved from engineering-codex)
- Updated README with quick-start commands and skill connection diagram

## 2026-01-28

### Initial Release
- Golden paths: `kotlin-spring-boot.md`, `kotlin-axon-cqrs.md`, `vue-mfe.md`
- Skills: `refine-ticket`, `implement-ticket`, `technical-deep-dive`, `spike` (with discovery guide)
- Rules: `code-review.md`, `refinement.md`, `refinement-best-practices.md`
- Auto-apply rules: `kotlin-standards.md`, `vue-standards.md`, `security-standards.md`, `jira-standards.md`
- Scoring system: `score.sh` with 8 criteria and report generation
- Patterns: `pattern-inventory.md`
- Security: `security-checklist.md`
