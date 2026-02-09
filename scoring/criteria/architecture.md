# Scoring Criteria: Architecture (15 points)

Evaluates adherence to golden path architecture patterns and separation of concerns.

## Scoring Rubric

### Package Structure (5 points)

| Score | Criteria |
|-------|----------|
| 5 | Follows golden path structure exactly |
| 4 | Minor deviations, clear organization |
| 3 | Some organizational issues, but logical |
| 2 | Inconsistent structure |
| 1 | Flat or chaotic structure |
| 0 | No discernible structure |

**Detection:**
- Kotlin: Check for `endpoint/`, `service/`, `repository/` packages
- Axon: Check for `commands.kt`, `events.kt`, aggregate files
- Vue: Check for `components/`, `composables/`, `services/`, `views/`

### Separation of Concerns (5 points)

| Score | Criteria |
|-------|----------|
| 5 | Perfect layer separation, no leaky abstractions |
| 4 | Minor violations (e.g., occasional business logic in controller) |
| 3 | Some cross-layer dependencies |
| 2 | Significant layer mixing |
| 1 | Little separation |
| 0 | Monolithic code |

**Detection:**
- Controllers importing repository classes directly (violation)
- Business logic in controllers (violation)
- Database annotations in service layer (violation)

### Pattern Adherence (5 points)

| Score | Criteria |
|-------|----------|
| 5 | Uses appropriate pattern for complexity (CQRS where needed) |
| 4 | Correct pattern, minor implementation issues |
| 3 | Pattern partially implemented |
| 2 | Wrong pattern for the problem |
| 1 | Anti-patterns present |
| 0 | No architectural pattern |

**Detection:**
- Axon apps: Check for @Aggregate, @CommandHandler, @EventSourcingHandler
- Standard apps: Check for service layer pattern
- MFE: Check for composable pattern usage

## Automated Checks

```bash
# Kotlin - Check package structure
find src/main/kotlin -type d -name "endpoint" | wc -l  # Should be >= 1
find src/main/kotlin -type d -name "service" | wc -l   # Should be >= 1

# Kotlin - Check for controller/repository separation
grep -r "Repository" src/main/kotlin/**/endpoint/ | wc -l  # Should be 0

# Axon - Check for CQRS components
grep -r "@Aggregate" src/main/kotlin/ | wc -l
grep -r "@CommandHandler" src/main/kotlin/ | wc -l
grep -r "@EventSourcingHandler" src/main/kotlin/ | wc -l

# Vue - Check component structure
ls -d src/components/*/ 2>/dev/null | wc -l  # Feature folders
ls src/composables/use*.ts 2>/dev/null | wc -l  # Composables
ls -d src/services/*/ 2>/dev/null | wc -l  # Service folders
```

## Manual Review Points

- [ ] Controllers only handle HTTP concerns
- [ ] Services contain all business logic
- [ ] No circular dependencies between packages
- [ ] Aggregates are properly bounded
- [ ] Event handlers have no side effects in @EventSourcingHandler

## Golden Path References

To improve your score in this category, reference these golden paths:

| Project Type | Golden Path | Relevant Sections |
|-------------|-------------|-------------------|
| Kotlin (Spring Boot) | [Kotlin Spring Boot](../../golden-paths/kotlin-spring-boot.md) | Package Structure, Layer Responsibilities (endpoint/, service/, repository/, model/entities/) |
| Kotlin (Axon) | [Kotlin Axon CQRS](../../golden-paths/kotlin-axon-cqrs.md) | Package Structure, Core Components, Aggregate Root, Query Side (Projections), Controllers |
| Vue MFE | [Vue MFE](../../golden-paths/vue-mfe.md) | Package Structure, Component Patterns, Composables, Services |
| Terraform | [Terraform IaC](../../golden-paths/terraform-iac.md) | Package Structure, Module Structure |
| Playwright | [Integration Testing](../../golden-paths/integration-testing.md) | Project Structure, Layer Responsibilities (pages/, services/, fixtures/) |
| Groovy (Console) | [Groovy Monolith](../../golden-paths/groovy-monolith.md) | Package Structure, Layer Responsibilities (controller/, service/, dao/, domain/) |
