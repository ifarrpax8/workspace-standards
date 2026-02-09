# Golden Path: Groovy/Java Monolith (pax8/console)

Practical guidance for working within the legacy Groovy/Java monolith. This document describes how to work effectively in the existing codebase while positioning code for eventual extraction per the migration strategy.

**Use when:** Adding or modifying features in pax8/console, working within existing bounded contexts, or preparing code for future extraction.

**Reference implementations:** pax8/console

---

## Package Structure

```
com.pax8/
├── controller/              # Request handling (interface + impl in service module)
│   ├── billing/
│   │   ├── invoice/
│   │   └── payment/
│   └── pricing/
├── dao/                     # Data access layer
├── domain/                  # Grails-style domain objects
│   ├── account/
│   ├── billing/
│   ├── catalog/
│   ├── invoice/
│   └── ...
├── dto/                     # Data transfer objects
├── service/                 # Business logic (1000+ files)
│   ├── controller/         # Controller implementations (Interface + Impl)
│   ├── billing/
│   ├── catalog/
│   ├── order/
│   └── ...
├── framework/               # Shared framework components
├── search/                  # Search abstractions
└── util/                    # Utilities
```

Controller interfaces live in the controller module; implementations live in `service/src/main/groovy/com/pax8/controller/`. The service layer is organized by domain (billing, catalog, order, partner, etc.).

---

## Layer Responsibilities

### controller/ (Request Handling)

Controllers define the API contract via interfaces and handle HTTP concerns. Implementations delegate to services.

**Interface:** Declares method signatures, annotated with `@Endpoint` for routing. Use Java for interfaces when shared across modules.

```java
@Endpoint("billing")
public interface BillingController extends Controller {
    Long addLedgerEntry(LedgerEntry ledgerEntry);
    List<LedgerEntry> getLedger(Long companyId, Long partnerId);
}
```

**Implementation:** Extends `AbstractBaseController`, implements the interface. Uses `@Inject` for dependencies, `@ApiMethod` for exposed endpoints, `@PreAuthorize` for authorization. No business logic — marshal request, call service, return response.

```groovy
@PreAuthorize("hasRole('F_API_ACCESS')")
class BillingControllerImpl extends AbstractBaseController implements BillingController {
    @Inject InvoiceService invoiceService
    @Inject LedgerService ledgerService

    @ApiMethod
    @Override
    @PreAuthorize("hasRole('F_CAN_ADD_LEDGER_ENTRY')")
    Long addLedgerEntry(@Param("ledgerEntry") LedgerEntry ledgerEntry) {
        ledgerService.addEntry(ledgerEntry)
    }
}
```

**Rules:**
- Interface defines the contract; implementation is the wiring
- Controllers never call DAOs directly — go through services
- Use `@Param` and `@RequiredParam` for request parameter mapping
- Keep controller methods thin — single service call per action

### service/ (Business Logic)

All business rules live in the service layer. Services are organized by domain (billing, catalog, order, partner, subscription, etc.).

**Naming:** `{Domain}Service`, `{Domain}EntityService` (CRUD-focused), `{Domain}AggregateService` (orchestrates multiple services).

**Dependency injection:** Use `@Inject` for required dependencies. Prefer constructor injection when adding new code; field injection exists in legacy code.

**Transaction management:** Services that modify data should use `@Transactional` (or inherit from transactional base). Read-only operations can omit it for performance.

```groovy
@Transactional
class InvoiceService {
    @Inject InvoiceDao invoiceDao
    @Inject LedgerService ledgerService

    Invoice createInvoice(CreateInvoiceRequest request) {
        def invoice = buildInvoice(request)
        invoiceDao.save(invoice)
        ledgerService.recordInvoice(invoice)
        invoice
    }
}
```

**Rules:**
- One service per cohesive domain concern
- Avoid God services — split when a service exceeds ~500 lines or handles unrelated responsibilities
- Services call other services or DAOs; never controllers or framework HTTP types

### dao/ (Data Access)

DAOs provide database access. Use Groovy or Java; follow existing patterns in the package.

**Rules:**
- DAOs return domain objects or primitives
- No business logic in DAOs
- Use named parameters for SQL to avoid injection

### domain/ (Domain Objects)

Grails-style domain objects: POJOs/POGOs with properties, often mapped to database tables. Mix of Groovy and Java.

**Conventions:**
- Properties declared as `Type name` (Groovy) or with getters/setters (Java)
- Use `Long id` for primary key
- Use `UUID guid` for external identifiers where applicable
- Domain objects in `domain/` are shared; avoid adding HTTP or framework-specific types

**Rules:**
- Keep domain objects anemic for database-mapped entities — behavior belongs in services
- Avoid circular dependencies between domain packages

### dto/ (Data Transfer Objects)

DTOs for API request/response shapes when domain objects are not suitable. Use when the API contract differs from the persistence model.

---

## Working Within the Monolith

### Adding Features to Existing Bounded Contexts

Prefer extending existing packages over creating new ones. If adding billing logic, add to `service/billing/`; if adding a new controller action, add to the existing controller interface and impl.

**Rules:**
- Match the structure of the closest existing feature
- Add new services under the appropriate domain package
- Reuse existing DAOs where possible; add new DAO methods rather than new DAO classes for the same table

### Creating New Bounded Contexts (Rare)

Only create a new top-level package when the functionality is clearly outside existing domains and may be extracted as a separate service.

**Rules:**
- New package: `service/{newdomain}/` with its own services, plus controller if needed
- Minimize cross-package dependencies — new code should not depend on unrelated domains
- Document the boundary and extraction intent

---

## Controller Patterns

### Interface + Implementation

The interface lives in the controller module, the implementation in the service module. The framework wires them via Spring.

**Interface:** `BillingController` extends `Controller`, annotated with `@Endpoint("billing")`. Methods match the API.

**Implementation:** `BillingControllerImpl` extends `AbstractBaseController` implements `BillingController`. Injects services, delegates all logic.

### Request/Response Handling

Controllers receive parameters via `@Param`/`@RequiredParam`. Return domain objects, DTOs, or primitives. The framework handles serialization. For complex responses, use `Map` or a dedicated DTO — avoid exposing internal domain structure.

---

## Testing Strategy

Use Spock for new Groovy tests. The codebase also uses JUnit 5 with Mockito; Spock is preferred for new tests due to its Groovy-native syntax and given/when/then structure.

**Run tests:** `./gradlew check` — runs tests, PMD, and CodeNarc. Always run before pushing.

**Unit tests:** Test services in isolation with mocked DAOs and dependent services. Place in `src/test/groovy/` mirroring the main source structure.

**Controller tests:** Test controller implementations with mocked services. Assert correct service calls and response mapping.

**Integration tests:** Use `@SpringBootTest` or equivalent when testing full flows. Contract tests exist for API boundaries.

```groovy
class InvoiceServiceTest extends Specification {
    InvoiceDao invoiceDao = Mock()
    LedgerService ledgerService = Mock()
    InvoiceService service = new InvoiceService(invoiceDao: invoiceDao, ledgerService: ledgerService)

    def "creates invoice and records ledger entry"() {
        given:
        def request = new CreateInvoiceRequest(partnerId: 1L, amount: 100G)
        when:
        def result = service.createInvoice(request)
        then:
        1 * invoiceDao.save(_ as Invoice) >> { it[0] }
        1 * ledgerService.recordInvoice(_ as Invoice)
    }
}
```

**Rules:**
- Test new code; add tests when modifying existing code
- Mock external dependencies (DAOs, other services, Kafka)
- Use descriptive test names

---

## Build and Verification

`./gradlew check` runs:
- All tests (unit and integration)
- PMD (static analysis for Java)
- CodeNarc (static analysis for Groovy)

**Always run before pushing.** CI will fail on violations.

---

## Code Quality

### PMD

PMD runs on Java code. Violations are compared against a baseline; only new violations fail the build. Fix new violations or add justified suppressions.

### CodeNarc

CodeNarc runs on Groovy code. Config in `config/codenarc/codenarc.groovy`. Baseline violations are tracked; new violations fail the build.

**Common rules:** `ParameterReassignment` (use temp variable instead of reassigning params), `EmptyCatchBlock`, `UnusedImport`, brace and formatting rules.

**Handling violations:**
- Fix the violation when straightforward
- Use `@SuppressWarnings` or rule exclusion only when justified — document why
- Do not add new violations; improve the baseline over time

---

## When to Extract vs When to Add

Reference: [Migration Paths - Monolith to Microservices](../patterns/migration-paths.md)

**Add to monolith when:**
- Feature fits an existing bounded context
- Tight coupling to existing domain data
- No clear team ownership for a new service
- Extraction would require significant refactoring first

**Consider extraction when:**
- Feature development velocity is significantly slower in the monolith
- Deployment of one domain blocks another
- Team boundaries align with domain boundaries
- Bounded context has clear data ownership and fewer inbound dependencies

**Strategy:** Strangle the edges first. Extract leaf contexts (read-heavy, few dependencies) before core domains. When adding code that may be extracted later, keep it isolated.

---

## Migration-Safe Patterns

When adding code that may be extracted as a microservice later:

**Package isolation:** Use a dedicated package (e.g., `service/{newdomain}/`) with clear boundaries. Avoid scattering related code across unrelated packages.

**Minimal cross-dependencies:** New code should depend on as few other domains as possible. Prefer interfaces over concrete types for cross-domain calls.

**Clear domain boundaries:** Keep the new functionality cohesive. If it touches billing, partners, and subscriptions, extraction will be harder.

**Event-ready design:** Where practical, consider publishing domain events for significant state changes. This eases future event-driven integration.

---

## Common Pitfalls

**God services:** Services that grow to handle unrelated responsibilities. Split when a service exceeds ~500 lines or handles multiple distinct concerns.

**Shared mutable state:** Avoid static mutable state, session-scoped mutable caches, or singletons that hold mutable data. Use request-scoped or injectable dependencies.

**Groovy dynamic typing gotchas:** Use `@CompileStatic` for performance-critical paths. Avoid `def` when the type is known — explicit types improve refactoring and IDE support. Be cautious with `==` (Groovy's equals) vs `is()` (identity).

**Parameter reassignment:** CodeNarc flags reassigning method parameters. Use a local variable instead.

**Tight coupling to framework:** Minimize direct use of framework HTTP types in services. Keep services framework-agnostic where possible.

---

## Checklist

Before completing a feature, verify:

- [ ] `./gradlew check` passes (tests, PMD, CodeNarc)
- [ ] No new PMD or CodeNarc violations
- [ ] Controller has no business logic — delegates to services
- [ ] New services are in the appropriate domain package
- [ ] Domain objects stay anemic; logic in services
- [ ] If adding code that may be extracted: package isolated, minimal cross-dependencies
- [ ] Tests cover new behavior
