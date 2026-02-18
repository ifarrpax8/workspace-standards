---
description: Standards for Groovy/Java monolith (pax8/console)
globs: ["**/*.groovy", "**/*.java"]
alwaysApply: true
---

# Groovy/Java Monolith Standards

This is a legacy codebase. Follow existing patterns and position new code for future extraction.

## Build and Verification

- Run `./gradlew check` to execute tests, PMD, and CodeNarc — always before pushing
- Do NOT use `./gradlew test` alone — `check` includes static analysis that CI enforces
- Fix new PMD/CodeNarc violations; do not add to the baseline
- Use `@SuppressWarnings` only with documented justification

## Controller Pattern

- Controllers follow the Interface + Implementation pattern
- Interface in the controller module with `@Endpoint`, implementation in the service module
- Implementation extends `AbstractBaseController`
- Controllers delegate to services — no business logic
- Use `@Param` and `@RequiredParam` for parameter mapping
- Use `@PreAuthorize` for authorization

## Service Layer

- All business logic belongs in services
- One service per cohesive domain concern
- Services call other services or DAOs; never controllers or framework HTTP types
- Prefer constructor injection for new code; `@Inject` field injection exists in legacy code
- Use `@Transactional` for data-modifying operations
- Split services exceeding ~500 lines or handling unrelated responsibilities

## Domain Objects

- Keep domain objects anemic — behavior belongs in services
- Use `Long id` for primary key, `UUID guid` for external identifiers
- Do not add HTTP or framework-specific types to domain objects
- Avoid circular dependencies between domain packages

## Testing

- Prefer Spock for new Groovy tests (given/when/then structure)
- JUnit 5 + Mockito is acceptable for Java tests
- Test naming: descriptive strings in Spock (`"creates invoice and records ledger entry"`)
- Mock external dependencies (DAOs, other services, Kafka)
- Add tests when modifying existing code

## Groovy-Specific

- Avoid `def` when the type is known — explicit types improve refactoring
- Use `@CompileStatic` for performance-critical paths
- Do not reassign method parameters — use a local variable (CodeNarc enforces this)
- Be cautious with `==` (Groovy's equals) vs `is()` (identity)

## Migration-Safe Patterns

- New bounded contexts go in `service/{newdomain}/` with clear boundaries
- Minimize cross-domain dependencies — prefer interfaces over concrete types
- Keep new functionality cohesive within a single domain
- Consider publishing domain events for significant state changes

## Adding Code

- Match the structure of the closest existing feature
- Add new services under the appropriate domain package in `service/`
- Add new DAO methods to existing DAOs for the same table
- Create new top-level packages only when functionality is clearly outside existing domains

Reference: [@workspace-standards/golden-paths/groovy-monolith.md](../../golden-paths/groovy-monolith.md)
