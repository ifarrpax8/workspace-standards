# Workspace Standards

A shared repository of coding standards, architecture patterns, quality scoring, and interactive skills for Pax8 development.

## Coding Standards

- Follow existing codebase patterns
- Use idiomatic Kotlin when working with Kotlin
- Never add or remove existing code comments
- Check language syntax from documentation before writing code
- Run `./gradlew check` for tests, PMD, and CodeNarc in the groovy monolith codebase

## Jira Conventions

The HRZN project uses custom description fields instead of the standard description field:

- **Story**: `customfield_12636`
- **Spike**: `customfield_14303`
- **Epic**: `customfield_12637`

Always read the custom field first. If empty, fall back to the standard description.

## Detailed Rules

This repository contains detailed coding standards for specific technologies. They are available in `.cursor/rules/` (Cursor) and `.augment/rules/` (Augment):

- **kotlin-standards.md** -- Spring Boot, Axon Framework, Kotlin idioms
- **groovy-standards.md** -- Monolith conventions
- **vue-standards.md** -- Vue 3, Pinia, composables, MFE patterns
- **api-standards.md** -- REST API design, versioning, error handling
- **security-standards.md** -- OWASP, secrets, auth patterns
- **terraform-standards.md** -- Infrastructure as Code conventions
- **playwright-standards.md** -- E2E testing with page object model
- **jira-standards.md** -- Custom fields, ticket templates, workflows

## Skills

This repository provides 15 interactive skills for team workflows. They are available in `.cursor/skills/` (Cursor) and `.agents/skills/` (Augment).

**Pipeline skills** (chained by the idea-to-implementation orchestrator):
- **refine-ticket** -- Three Amigos refinement with confidence scoring
- **implement-ticket** -- Structured implementation with DoR/DoD gates
- **code-review** -- PR review against team standards and golden paths
- **spike** -- Time-boxed research with Jira deliverables
- **generate-opportunity-brief** -- Draft Pax8 Opportunity Briefs
- **generate-prd** -- Expand approved briefs into PRDs
- **post-implementation-review** -- Estimate accuracy and learnings
- **idea-to-implementation** -- Full 9-stage pipeline orchestrator

**Utility skills** (standalone):
- **technical-deep-dive** -- Codebase investigation for unknowns
- **score** -- Interactive repository scoring
- **assess-tests** -- Test completeness audit across the test pyramid
- **generate-pr-description** -- PR body from git and Jira context
- **generate-adr** -- Architecture Decision Records
- **fix-bug** -- Test-first bug fixing
- **api-migration-test** -- Three-phase migration test scripts

## Golden Path Architectures

- **kotlin-spring-boot.md** -- Standard layered (endpoint/service/repository)
- **kotlin-axon-cqrs.md** -- Event sourcing + CQRS with Axon Framework
- **vue-mfe.md** -- Feature-based Vue 3 micro-frontend
- **groovy-monolith.md** -- Legacy monolith working standards
- **terraform-iac.md** -- Infrastructure as Code
- **integration-testing.md** -- Playwright page object model

## Engineering Codex Integration

All workflow skills optionally leverage the Engineering Codex when it is in the workspace -- best practices, gotchas, decision frameworks, Pax8 standards, and tech radar data. Skills degrade gracefully without it.
