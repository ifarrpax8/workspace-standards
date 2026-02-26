# Glossary

Shared terminology used across workspace-standards skills, rules, and golden paths.

## Process

- **Three Amigos** -- Refinement approach with Developer, Test, and Product perspectives collaborating on a ticket.
- **Refinement** -- Process of clarifying and planning Jira tickets before implementation begins.
- **DoR (Definition of Ready)** -- Criteria a ticket must meet before implementation can start.
- **DoD (Definition of Done)** -- Criteria that must be met before a ticket is considered complete.
- **Spike** -- Time-boxed research ticket with Jira deliverables for reducing uncertainty.
- **Time-boxed** -- Fixed time limit for an activity (typically spikes); stop when time expires regardless of completeness.
- **Confidence score** -- 1–12 score across four dimensions (Requirements, Technical, Test Coverage, Dependencies) used during refinement to assess readiness.
- **Fibonacci estimate** -- Story sizing using the sequence 1, 2, 3, 5, 8, 13.
- **T-shirt sizing** -- Coarse complexity estimate using S, M, L.
- **QA handoff** -- Structured handover to QA with test evidence, environment details, and tester guidance.
- **Post-implementation review (PIR)** -- Post-merge retrospective comparing estimates to actuals and capturing learnings.
- **Unknown unknowns triage** -- Process for handling unexpected discoveries during implementation: SOLVE INLINE, FOLLOW-UP TICKET, or ESCALATE.
- **Pipeline skill** -- A skill designed to be chained by the idea-to-implementation orchestrator.
- **Idea-to-implementation** -- Full 10-stage pipeline from idea through PRD, spike, story breakdown, refinement, and implementation.

## Testing

- **TDD (Test-Driven Development)** -- Red–green–refactor cycle: write a failing test, make it pass, then refactor.
- **Red-green-refactor** -- The three steps of TDD.
- **Test pyramid** -- Distribution of tests: Unit 70–80%, Integration 15–20%, E2E 5–10%.
- **AAA pattern** -- Arrange–Act–Assert structure for unit tests.
- **Given/When/Then** -- BDD-style test structure used in Spock (Groovy).
- **Page Object Model (POM)** -- E2E testing pattern where each page or component is represented by a class.
- **Test persona** -- Six perspectives for generating test scenarios: The Optimist, The Saboteur, The Boundary Walker, The Explorer, The Auditor, The User.

## Architecture

- **Golden path** -- Standard reference architecture for a given tech stack. Defines the recommended project structure, patterns, and conventions.
- **CQRS (Command Query Responsibility Segregation)** -- Pattern separating read and write models.
- **Event sourcing** -- Storing state as an append-only log of domain events.
- **Aggregate** -- DDD aggregate root; the consistency boundary for commands in Axon Framework.
- **Saga** -- Long-running process that coordinates multiple aggregates via events in Axon Framework.
- **Axon Framework** -- Java/Kotlin framework for event sourcing and CQRS.
- **MFE (Micro-Frontend)** -- Vue 3 micro-frontend using Module Federation for independent deployment.
- **Module Federation** -- Webpack feature enabling runtime sharing of code between independently deployed applications.
- **Composable** -- Vue Composition API function (use-prefixed) for reusable stateful logic.
- **Barrel export** -- An `index.ts` file that re-exports public API from a feature folder.
- **Feature folder** -- Directory structure grouping components, composables, stores, and services by feature rather than type.
- **Monolith** -- The Groovy/Java monolith codebase (`pax8/console`).
- **IaC (Infrastructure as Code)** -- Managing infrastructure through Terraform configuration files.

## Documentation

- **ADR (Architecture Decision Record)** -- Structured document recording an architectural decision, its context, and consequences.
- **Opportunity Brief** -- Lightweight document proposing a feature idea with problem statement, user impact, and risks.
- **PRD (Product Requirements Document)** -- Detailed requirements document expanded from an approved Opportunity Brief.
- **Pattern inventory** -- Catalogue of documented patterns discovered during implementation and review.

## Quality

- **MUST FIX** -- Critical code review finding that blocks PR approval.
- **PMD** -- Java/Groovy static analysis tool run via `./gradlew check`.
- **CodeNarc** -- Groovy-specific static analysis tool run via `./gradlew check`.
- **OWASP** -- Open Web Application Security Project; security standards referenced in security reviews.
- **Self-review** -- Developer review of their own changes before pushing, using the pre-review checklist.

## Pax8 / Jira

- **HRZN** -- Jira project key for Finance Enablement.
- **Engineering Codex** -- The authoritative reference guide for building modern web applications; provides best practices, gotchas, and decision frameworks.
- **Facet** -- An Engineering Codex topic covering one engineering concern (e.g. testing, caching, API design).
- **Tech radar** -- Assessment of tools and libraries extracted from Engineering Codex content.
- **Standards map** -- Mapping of Pax8 ADRs to Engineering Codex standards.
