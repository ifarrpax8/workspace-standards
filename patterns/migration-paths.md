# Migration Paths

Documented transition strategies from current patterns to target state across all repositories. Complements the [Pattern Inventory](pattern-inventory.md) which captures the current state.

**Target State:** DDD with Vertical Slice Architecture and CQRS where appropriate.

---

## 1. Monolith to Microservices

**Current:** pax8/console (Groovy/Java, Grails-style N-tier MVC, 1000+ service files)
**Target:** Bounded context microservices (Kotlin Spring Boot, event-driven)

### Triggers

- Feature development velocity in the monolith is significantly slower than in microservices
- Deployment of one domain blocks or risks another
- Team boundaries align with domain boundaries
- A bounded context has clear data ownership

### Strategy

1. **Identify bounded contexts** — Map the monolith's service layer to domain boundaries (billing, pricing, partners, subscriptions). Use domain events as boundary markers.
2. **Strangle the edges first** — Extract leaf bounded contexts (those with fewer inbound dependencies) before core domains. Start with read-heavy contexts where the risk is lower.
3. **Introduce an anti-corruption layer** — New microservices communicate with the monolith through a well-defined API or event bridge, never by sharing the database.
4. **Event-driven integration** — Publish domain events from the monolith via Kafka. New services consume these events rather than calling the monolith directly.
5. **Database decomposition** — Each extracted service gets its own datastore. Use change data capture (CDC) or dual-write with reconciliation during the transition.
6. **Feature flag the cutover** — Route traffic between old and new implementations using feature flags. Run both in parallel during validation.

### Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Data consistency during split | Event sourcing + compensating transactions |
| Shared database coupling | Anti-corruption layer, CDC |
| Distributed transaction complexity | Saga pattern (see [kotlin-axon-cqrs](../golden-paths/kotlin-axon-cqrs.md)) |
| Team capacity for dual maintenance | Extract one context at a time, deprecate monolith features progressively |

### Effort

**XL** — 6-12 months per bounded context extraction.

### References

- [Kotlin Spring Boot Golden Path](../golden-paths/kotlin-spring-boot.md)
- [Kotlin Axon CQRS Golden Path](../golden-paths/kotlin-axon-cqrs.md)

---

## 2. Flat Layered to Domain-Focused

**Current:** currency-manager (flat `endpoint/service/repository/` packages)
**Target:** Domain-focused packaging (features grouped by business capability)

### Triggers

- Service file count exceeds ~30 in a single `service/` package
- New developers struggle to find related code
- Changes to a single feature touch files scattered across many packages
- The service is gaining distinct sub-domains (e.g., rates + providers + auditing)

### Strategy

1. **Group by feature** — Move related endpoint, service, repository, and model files into feature packages:
   ```
   com.pax8.currencymanager/
   ├── rates/
   │   ├── RatesEndpoint.kt
   │   ├── RatesService.kt
   │   └── RatesRepository.kt
   ├── providers/
   │   ├── ProviderEndpoint.kt
   │   ├── ProviderService.kt
   │   └── ProviderRepository.kt
   └── shared/
       ├── config/
       └── exception/
   ```
2. **Preserve cross-cutting concerns** — Keep `config/`, `exception/`, and `validation/` in a `shared/` or root package.
3. **Internal boundaries** — Make feature packages communicate through interfaces, not by reaching into each other's internals.
4. **Incremental migration** — Move one feature at a time. Each move is a single refactoring PR with no behaviour change.

### Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Circular dependencies between features | Introduce shared interfaces or events |
| Large diff in a single PR | Move one feature package per PR |
| Breaking imports across test files | Run full test suite after each move |

### Effort

**M** — 2-4 weeks for a service with 30-50 files.

### References

- [Kotlin Spring Boot Golden Path](../golden-paths/kotlin-spring-boot.md)

---

## 3. Adding CQRS to Layered Services

**Current:** Standard layered service (e.g., currency-manager, report-manager)
**Target:** CQRS with optional event sourcing (e.g., einvoice-connector pattern)

### Triggers

- Significant read/write asymmetry (many more reads than writes, or vice versa)
- Complex read projections that don't map to the write model
- Audit trail requirements (every state change must be traceable)
- Need for saga orchestration across multiple operations
- Performance: reads and writes benefit from different data models or stores

### Strategy

**Phase 1: Query Separation (Low risk)**
1. Introduce a `query/` package alongside the existing `service/` layer
2. Create read-only query handlers that return purpose-built projections
3. Controllers route reads to query handlers, writes to existing services
4. No infrastructure change — just code organisation

**Phase 2: Command Separation (Medium risk)**
1. Introduce a `command/` package with explicit command objects
2. Services become command handlers that validate and execute writes
3. Commands and queries have distinct models (no shared DTOs)

**Phase 3: Axon Adoption (Higher risk, only if needed)**
1. Add Axon Framework dependencies
2. Convert domain entities to aggregate roots with `@Aggregate`
3. Define commands, events, and queries as Axon messages
4. Implement event sourcing handlers and projections
5. Add sagas for multi-step workflows

### Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Eventual consistency surprises | Start with synchronous projections, move to async only when needed |
| Over-engineering simple services | Only proceed past Phase 1 if triggers are clearly present |
| Axon learning curve | Follow the [Axon golden path](../golden-paths/kotlin-axon-cqrs.md) and pair with engineers experienced on einvoice-connector |

### Effort

- Phase 1 (query separation): **S** — 1-2 weeks
- Phase 2 (command separation): **M** — 2-3 weeks
- Phase 3 (Axon adoption): **L** — 4-8 weeks

### References

- [Kotlin Axon CQRS Golden Path](../golden-paths/kotlin-axon-cqrs.md)
- Finance ADR-0002 (Event Sourcing), ADR-0003 (Axon Framework)

---

## 4. Frontend Pattern Alignment

**Current:** order-management-mfe (Vue 3, no Pinia, props/events only, older Vitest/Propulsion)
**Target:** finance-mfe patterns (Pinia state management, composables, aligned dependency versions)

### Triggers

- Prop drilling deeper than 3 levels
- Duplicated state logic across components
- Inconsistent service layer patterns between MFEs
- Propulsion or Vitest version drift causing compatibility issues
- New developers switching between MFEs and finding different patterns

### Strategy

1. **Add Pinia** — Install Pinia, create stores for shared state (start with the most prop-drilled state). Follow the [Vue MFE golden path](../golden-paths/vue-mfe.md) store pattern.
2. **Extract composables** — Identify repeated reactive logic across components and extract to `composables/` with the `use{Feature}` naming convention.
3. **Standardize the service layer** — Ensure all API calls go through class-based services in `services/` with `use{Service}` factory functions.
4. **Align dependency versions** — Update Propulsion, Vitest, and other shared dependencies to match finance-mfe versions. Run the full test suite after each upgrade.
5. **Add barrel exports** — Create `index.ts` files for feature component directories.

### Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Regression during Pinia introduction | Add component tests before refactoring, test store actions independently |
| Breaking changes in Propulsion upgrade | Check Propulsion release notes, test visually after upgrade |
| Vitest major version jump | Run existing tests on new version in a branch before merging |

### Effort

**L** — 3-4 weeks for full alignment.

### References

- [Vue MFE Golden Path](../golden-paths/vue-mfe.md)

---

## 5. Testing Maturity

**Current:** Varies across repositories (see [Pattern Inventory](pattern-inventory.md#testing-patterns))
**Target:** Comprehensive test coverage: integration tests for all backend services, component tests for all frontends, contract tests for service boundaries, E2E tests for critical user flows.

### Triggers

- Production bugs that would have been caught by integration tests
- Confidence issues during deployments
- Refactoring blocked by lack of test safety net
- New service boundaries introduced (contract testing needed)

### Strategy

**Backend (Kotlin services):**
1. Prioritize integration tests for API endpoints using `@SpringBootTest` + `MockMvc`
2. Add Testcontainers for database and Kafka integration tests
3. Introduce contract tests (Pact) for service-to-service boundaries
4. Target: every endpoint has at least one happy-path integration test

**Frontend (Vue MFEs):**
1. Add component tests for all feature components using Vitest + Testing Library
2. Add composable unit tests for business logic
3. Target: every feature component has at least one render + interaction test

**E2E (Playwright):**
1. Cover critical user flows (login, core CRUD operations, payment flows)
2. Use the [integration testing golden path](../golden-paths/integration-testing.md) for structure
3. Run in CI with test sharding for parallelism

### Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Slow test suites blocking CI | Use Testcontainers for isolation, test sharding for Playwright |
| Flaky E2E tests | Proper waiting strategies, test isolation, no shared state |
| Diminishing returns on unit tests | Focus on integration and component tests over isolated unit tests |

### Effort

- Per backend service: **M** — 2-3 weeks to reach baseline coverage
- Per frontend MFE: **M** — 2-3 weeks
- E2E test suite: **L** — 4-6 weeks for initial critical flow coverage

### References

- [Integration Testing Golden Path](../golden-paths/integration-testing.md)
- [Kotlin Spring Boot Golden Path](../golden-paths/kotlin-spring-boot.md#testing-strategy)
- [Vue MFE Golden Path](../golden-paths/vue-mfe.md#testing)

---

## Migration Priority Matrix

Recommended order based on impact and risk:

| Priority | Migration | Impact | Risk | Effort |
|----------|-----------|--------|------|--------|
| 1 | Testing Maturity | High (safety net for all other work) | Low | M per repo |
| 2 | Frontend Pattern Alignment | Medium (developer experience) | Low | L |
| 3 | Flat Layered to Domain-Focused | Medium (maintainability) | Low | M |
| 4 | Adding CQRS (Phase 1 only) | Medium (architecture clarity) | Low | S |
| 5 | Monolith to Microservices | High (velocity, independence) | High | XL |

Testing maturity is the highest priority because it provides the safety net that makes all other migrations less risky.
