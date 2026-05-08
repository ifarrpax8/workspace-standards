---
description: Kotlin coding standards for Spring Boot and Axon Framework projects
globs: ["**/*.kt"]
alwaysApply: true
type: "always"
---

# Kotlin Standards

Follow these standards when writing Kotlin code.

## Code Style

- Use idiomatic Kotlin (nullable types over Optional, data classes for DTOs)
- Prefer `val` over `var` for immutability
- Use constructor injection (no @Autowired on fields)
- Keep functions under 50 lines
- Use meaningful names (no single-letter variables except in lambdas)

## Package Structure

### Standard Spring Boot
```
endpoint/     → REST controllers
service/      → Business logic
repository/   → Data access
model/        → Domain entities and DTOs
config/       → Configuration classes
exception/    → Custom exceptions
```

### Axon Framework
```
{aggregate}/           → Aggregate root + handlers
{aggregate}/Commands.kt → Command definitions
{aggregate}/Events.kt   → Event definitions
{aggregate}/Queries.kt  → Query definitions
{aggregate}/sagas/      → Saga definitions
{aggregate}/query/      → Query handlers + projections
```

## Naming Conventions

- Classes: PascalCase (`CurrencyExchangeRateService`)
- Functions/Properties: camelCase (`getExchangeRate`)
- Constants: SCREAMING_SNAKE_CASE (`DEFAULT_CURRENCY`)
- Axon Commands: `{Action}{Aggregate}Command` (`CreateInvoiceCommand`)
- Axon Events: `{Aggregate}{Action}Event` (`InvoiceCreatedEvent`)

## Controller Rules

- Controllers handle HTTP concerns only
- No business logic in controllers
- Use ResponseEntity for HTTP semantics
- Validation annotations on request parameters

```kotlin
@PostMapping
fun create(@Valid @RequestBody request: CreateRequest): ResponseEntity<Response> {
    val result = service.create(request)
    return ResponseEntity.status(HttpStatus.CREATED).body(result)
}
```

## Service Rules

- All business logic belongs in services
- Throw domain exceptions (not HTTP exceptions)
- Use helper classes to avoid bloated services
- Single responsibility per service

## Axon-Specific Rules

- @EventSourcingHandler must have no side effects
- Validate business rules in @CommandHandler before applying events
- Use data classes for commands and events
- Sagas coordinate across aggregates (use for long-running processes)

## Code Comments

- Write comments that explain **why**, not what — the code already shows what
- Avoid comments that merely restate the code (`// increment counter` above `count++`)
- Document design decisions, non-obvious side effects, and constraints
- Keep comments concise; update them when the code changes — stale comments are worse than none
- Use **KDoc** for all public APIs, service interfaces, and aggregate handlers:

```kotlin
/**
 * Calculates the exchange rate for the given currency pair.
 * Rates are cached for 15 minutes — do not call per-item in batch operations.
 */
fun getExchangeRate(from: Currency, to: Currency): ExchangeRate
```

## Quality Gates

- **Never use `--no-verify`** or any mechanism that bypasses pre-commit hooks or static analysis
- Fix Detekt and Spotless violations in the same PR that introduces them — do not defer
- If a genuine edge case requires suppression, add a targeted exclusion in `detekt.yml` with a comment explaining why — never suppress wholesale
- A build that fails static analysis is not releasable; fix it before asking for review

## Testing

- Prefer integration tests with @SpringBootTest
- Use AggregateTestFixture for Axon aggregates
- Test naming: `should [expected behavior] when [condition]`
- Given-When-Then structure for tests
- `BUILD SUCCESSFUL` in Gradle output is the pass signal — warning logs in test output do not constitute failure

## Common Patterns

### Dependency Injection
```kotlin
@Service
class MyService(
    private val repository: MyRepository,
    private val otherService: OtherService
) { }
```

### Exception Handling
```kotlin
@RestControllerAdvice
class ControllerAdvice {
    @ExceptionHandler(NotFoundException::class)
    fun handleNotFound(ex: NotFoundException) = 
        ResponseEntity.status(HttpStatus.NOT_FOUND).body(ErrorResponse(ex.message))
}
```

### Data Classes
```kotlin
data class CreateRequest(
    @field:NotBlank val name: String,
    @field:Positive val amount: BigDecimal
)
```
