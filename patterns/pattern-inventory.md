# Pattern Inventory

Current state analysis of all repositories in the workspace. Use this to understand existing patterns and identify improvement opportunities.

## Repository Overview

| Repository | Language | Framework | Architecture | Maturity |
|------------|----------|-----------|--------------|----------|
| currency-manager | Kotlin | Spring Boot | Layered | Modern |
| einvoice-connector | Kotlin | Spring Boot + Axon | Event Sourcing / CQRS | Modern |
| report-manager | Kotlin | Spring Boot | Domain-focused Layered | Modern |
| finance-mfe | TypeScript | Vue 3 + Pinia | Feature-based | Modern |
| order-management-mfe | TypeScript | Vue 3 | Feature-based | Modern |
| finance (integration) | TypeScript | Playwright | Page Object Model | Modern |
| pax8/console | Groovy/Java | Grails-style | N-tier MVC | Legacy |
| role-management | HCL | Terraform + OpenFGA | Infrastructure as Code | Modern |

## Architecture Patterns

### Backend Pattern Comparison

| Pattern | currency-manager | einvoice-connector | report-manager | console |
|---------|------------------|-------------------|----------------|---------|
| DDD (Domain-Driven Design) | Partial | Yes | Partial | No |
| CQRS | No | Yes | No | No |
| Event Sourcing | No | Yes | No | No |
| Vertical Slice | No | Partial | No | No |
| Layered Architecture | Yes | Yes | Yes | Yes |
| Hexagonal/Ports & Adapters | No | No | No | No |

### Frontend Pattern Comparison

| Pattern | finance-mfe | order-management-mfe |
|---------|-------------|---------------------|
| Feature-based Architecture | Yes | Yes |
| Composition API | Yes | Yes |
| Pinia State Management | Yes | No (uses props/events) |
| Service Layer | Yes | Yes |
| TypeScript | Yes | Yes |

## Package Structure Analysis

### currency-manager (Kotlin - Layered)

```
com.pax8.currencymanager/
├── audit/           # Cross-cutting: audit interceptors
├── config/          # Kafka, Mongo, OpenAPI config
├── dispatcher/      # Event dispatching
├── endpoint/        # REST controllers + request/response models
├── exception/       # Custom exceptions
├── fx/              # External FX rate integration
├── model/           # Domain models, entities, events, commands
├── repository/      # Data access layer
├── service/         # Business logic
└── validation/      # Custom validators
```

**Observations:**
- Traditional layered approach
- Models include commands/events but no CQRS separation
- Good separation of concerns

### einvoice-connector (Kotlin - Event Sourcing)

```
com.pax8.finance/
├── businessunit/    # Business unit domain
├── client/          # External API clients
├── config/          # Axon, AWS, LaunchDarkly config
├── endpoint/        # REST controllers + models
├── event/           # Event processors and listeners
├── exception/       # Custom exceptions
├── industryclassification/  # Classification domain
├── invoice/
│   ├── Commands.kt          # Command definitions
│   ├── Events.kt            # Event definitions
│   ├── Invoice.kt           # Aggregate root
│   ├── Queries.kt           # Query definitions
│   ├── listeners/           # Event handlers
│   ├── query/               # Query handlers + projections
│   └── sagas/               # Saga orchestration
├── repository/      # Data access
├── service/         # Supporting services
├── transform/       # Data transformation
└── util/            # Utilities
```

**Observations:**
- Full CQRS implementation with Axon
- Clear command/event/query separation
- Saga pattern for complex workflows
- Follows finance ADR-0007 standards

### finance-mfe (Vue 3 - Feature-based)

```
src/
├── components/
│   ├── billing/         # Billing feature components
│   ├── fxrate/          # FX rate feature components
│   ├── payments/        # Payment components
│   ├── report/          # Reporting components
│   ├── tasks/           # Task management components
│   ├── common/          # Shared components
│   ├── forms/           # Form components
│   ├── inputs/          # Input components
│   ├── modals/          # Modal components
│   └── tooltips/        # Tooltip components
├── composables/         # Vue composition hooks
│   ├── direct-debit/
│   ├── permissions/
│   ├── tasks/
│   └── use*.ts          # Individual composables
├── services/            # API service layer
├── store/               # Pinia stores
├── interfaces/          # TypeScript types by domain
├── views/               # Page components
├── helpers/             # Utility functions
├── lang/                # i18n translations
└── expose/              # Exposed MFE components
```

**Observations:**
- Feature-based organization in components
- Good composable pattern usage
- Typed interfaces by domain
- MFE federation support via expose/

### pax8/console (Groovy/Java - Legacy)

```
com.pax8/
├── controller/          # MVC controllers (interface + impl pattern)
│   ├── billing/
│   └── pricing/
├── domain/              # Domain objects
└── service/             # Business logic services (1000+ files)
```

**Observations:**
- Traditional MVC/N-tier architecture
- Interface + Implementation pattern for controllers
- Large service layer indicates monolith
- Mix of Groovy and Java

## Testing Patterns

| Repository | Test Framework | Test Type | Location | Coverage Tool |
|------------|---------------|-----------|----------|---------------|
| currency-manager | JUnit 5 | Integration | `src/test/` | Jacoco |
| einvoice-connector | JUnit 5 | Unit + Integration | `src/test/` | Jacoco |
| report-manager | JUnit 5 | Integration + Contract | `src/test/` | Jacoco |
| finance-mfe | Vitest | Unit + Snapshot | `**/*.test.ts` | Istanbul |
| order-management-mfe | Vitest | Unit + Snapshot | `**/*.test.ts` | Istanbul |
| finance (integration) | Playwright | E2E Integration | `tests/` | N/A |
| role-management | OpenFGA CLI | Model tests | `fga/tests/` | N/A |

## Cursor Rules Status

| Repository | Has .cursor/rules/ | Rule Count | Key Rules |
|------------|-------------------|------------|-----------|
| currency-manager | Yes | 7 | code-organization, testing, code-quality |
| einvoice-connector | Yes | 8 | kotlin-axon-rules, contract-testing |
| report-manager | No | 0 | - |
| finance-mfe | Yes | 2 | internationalization, propulsion |
| order-management-mfe | No | 0 | - |
| role-management | Yes | 4 | create-permission, create-role, assign-permissions |

## ADR Status

| Repository | Has ADRs | Count | Key Decisions |
|------------|----------|-------|---------------|
| currency-manager | No | 0 | - |
| einvoice-connector | No | 0 | (follows finance ADRs) |
| report-manager | No | 0 | - |
| finance | Yes | 16 | Event sourcing, Axon, SDLC, Invoice state |
| finance-mfe | Yes | 1 | MFE integration |
| role-management | Yes | 16 | Permissions, FGA, roles |

## Target Architecture Alignment

**Target State:** DDD with Vertical Slice Architecture and CQRS (where appropriate)

| Repository | Current Gap | Recommended Path |
|------------|-------------|------------------|
| currency-manager | No CQRS, flat structure | Add command/query separation if complexity grows |
| einvoice-connector | Already aligned | Continue pattern, add more sagas if needed |
| report-manager | No CQRS | Consider for report generation workflows |
| finance-mfe | N/A (frontend) | Continue feature-based, add Pinia where needed |
| order-management-mfe | N/A (frontend) | Align with finance-mfe patterns |
| console | Full rewrite needed | Extract bounded contexts to microservices |

## Dependency Analysis

### Kotlin Backend Shared Dependencies

| Dependency | currency-manager | einvoice-connector | report-manager |
|------------|------------------|-------------------|----------------|
| Spring Boot | 3.x | 3.x | 3.x |
| Kotlin | 1.9.x | 1.9.x | 1.9.x |
| MongoDB | Yes | No | Yes |
| PostgreSQL | No | Yes | No |
| Kafka | Yes | Yes | No |
| Axon Framework | No | Yes | No |

### Vue MFE Shared Dependencies

| Dependency | finance-mfe | order-management-mfe |
|------------|-------------|---------------------|
| Vue | 3.5.x | 3.5.x |
| TypeScript | 5.3.x | 5.3.x |
| Pinia | 2.2.x | No |
| @pax8/propulsion | 1.64.x | 1.52.x |
| Vitest | 3.2.x | 1.1.x |
| Tailwind CSS | 3.4.x | 3.4.x |

**Note:** Version differences in Vitest and Propulsion indicate sync opportunities.
