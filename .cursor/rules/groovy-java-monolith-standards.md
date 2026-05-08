---
description: Standards for Groovy/Java monolith (pax8/console)
globs: ["**/*.groovy", "**/*.java"]
alwaysApply: true
type: "always"
---

# Groovy/Java Monolith Standards

This is a legacy codebase. Follow existing patterns and position new code for future extraction.

## Build and Verification

- Run `./gradlew check` to execute tests, PMD, and CodeNarc — always before pushing
- Do NOT use `./gradlew test` alone — `check` includes static analysis that CI enforces
- Fix new PMD/CodeNarc violations; do not add to the baseline
- Use `@SuppressWarnings` only with documented justification
- **Never use `--no-verify`** to bypass pre-commit hooks — fix the violations instead

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

### Java Test Style (JUnit 5 + Mockito)

New Java tests must comply with the project's PMD ruleset. Use `SeaInvoiceAlternateIdParserTest` as the canonical reference. Key rules:

**Class structure:**
```java
@SuppressWarnings("PMD.CommentDefaultAccessModifier")
@ExtendWith(MockitoExtension.class)
class MyServiceTest {                          // package-private — no public keyword

    @Mock
    private DependencyService dependency;      // private on all @Mock / @InjectMocks fields

    @InjectMocks
    private MyService service;

    private static final String S3_KEY = "finance.evt.invoice/test.json"; // private static final
}
```

**Method naming** — camelCase verb phrases, no `test` prefix or underscores:
```java
@Test
void returnsParsedDocumentOnHappyPath() { ... }      // ✓

@Test
void testHappyPath_ReturnsDocument() { ... }          // ✗ — test prefix + PascalCase fragment
```

**`final` everywhere in Java** — PMD requires `final` on all method parameters and local variables that are never reassigned:
```java
void indexesSif(final SifDocument sifDocument) {
    final Long invoiceId = SeaInvoiceAlternateIdParser.parse(event.getId());
    final boolean indexed = processor.process(invoiceId, sifDocument);
    ...
}
```

**Assertion messages** — all non-`assertEquals` assertions need a message (PMD `JUnitAssertionsShouldIncludeMessage`; `assertEquals` is suppressed by the project config):
```java
assertTrue(result, "indexing must return true on success");
assertNotNull(invoice.getGuid(), "GUID must be set");
```

**Numeric literals** — use underscores for readability in long numbers, and prefer primitive types for constants:
```java
private static final long INVOICE_ID = 12_345L;    // ✓ — primitive, readable
private static final Long INVOICE_ID = 12345L;      // ✗ — boxed + no underscores
```
Use `Long` (boxed) only when the constant is passed directly to methods that require `Long` to avoid per-call boxing at every use site.

**Static imports** — PMD caps at 4 (`TooManyStaticImports`). Use `Mockito.` and `ArgumentMatchers.` as regular class prefixes rather than static imports to stay under the limit:
```java
import org.mockito.Mockito;
import org.mockito.ArgumentMatchers;

// Then in tests:
Mockito.when(service.foo()).thenReturn(bar);
Mockito.verify(service).foo();
ArgumentMatchers.eq(INVOICE_ID)
```
When you genuinely need more than 4 static imports (e.g. six assertion types), add `@SuppressWarnings("PMD.TooManyStaticImports")` to the class with a comment explaining why. Do not use `import static org.mockito.Mockito.*` or `import static org.junit.jupiter.api.Assertions.*` wildcards — PMD flags these as `UnnecessaryImport`.

## Typing

- Type request parameters with a dedicated DTO — don't accept `MultiValueMap<String, String>` or `Map<String, Object>` when the accepted params are known
- Use specific generic types for response maps — `Map<String, FacetDTO>` not `Map<String, Object>`
- Don't mix Groovy and Java syntax in the same file — pick the file's language and stay consistent

## Java-Specific (PMD)

These rules apply when writing new Java files in the monolith. PMD enforces them via `generatePmdReport`; violations block the build.

- **`final` on params and locals** — declare every method parameter and every local variable `final` unless it is genuinely mutated (e.g. a loop counter). PMD `MethodArgumentCouldBeFinal` and `LocalVariableCouldBeFinal` fire on anything assignable-once that isn't `final`.
- **Variable names ≥ 3 characters** — PMD `ShortVariable` rejects names like `bp`, `ex`, `in`, `id`, `u`, `h`. Use descriptive names: `billingPeriod`, `thrown`, `sifStream`, `invoiceId`, `nameUuid`, `hashBits`.
- **No `new` inside loops** — PMD `AvoidInstantiatingObjectsInLoops` fires when `new` appears directly in a loop body. Extract the loop body into a `private static` helper method; the instantiation is then in the helper (no loop), and the main method just collects results.
- **CyclomaticComplexity ≤ 10** — methods with more than 10 decision points (each `if`, ternary `?:`, `&&`, `||` adds one) trigger `CyclomaticComplexity` and `NPathComplexity`. Fix by extracting small, named helper methods for repeated null-checks and conditional parsing patterns (e.g. `coalesceZero(BigDecimal)`, `parseOrDefault(String, LocalDate)`, `setBillingPeriods(...)`). Each helper has a complexity of 2 and a descriptive name that documents intent.
- **Try-with-resources for `Closeable` resources** — use try-with-resources instead of try-finally for any `Closeable` (streams, S3 objects, JDBC resources). Multiple resources can be chained in a single declaration. Close failures propagate rather than being swallowed — this is the correct fail-fast behaviour:
```java
// ✓ — both resources closed automatically; close() failures propagate
try (final S3Object s3Object = s3Client.getObject(bucket, key);
     final S3ObjectInputStream stream = s3Object.getObjectContent()) {
    return objectMapper.readValue(stream, SifDocument.class);
} catch (Exception e) {
    throw new IllegalStateException("Failed to read from S3: " + e.getMessage(), e);
}

// ✗ — manual null-check, swallowed close exception, 12 extra lines
S3ObjectInputStream stream = null;
try {
    stream = s3Object.getObjectContent();
    ...
} finally {
    if (stream != null) { try { stream.close(); } catch (Exception ignored) { } }
}
```

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
