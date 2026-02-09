# Golden Path: Kotlin Axon CQRS (Event Sourcing)

Standard architecture for Kotlin/Spring Boot microservices using Axon Framework with event sourcing and CQRS.

**Use when:** Audit requirements, complex domain logic, eventual consistency acceptable, saga orchestration needed.

**Reference implementations:** einvoice-connector

**ADR References:**
- [ADR-0002: Event Sourcing](../../finance/docs/adr/0002-event-sourcing.md)
- [ADR-0003: Use Axon Framework](../../finance/docs/adr/0003-use-axon-framework.md)
- [ADR-0007: Axon Code Standardization](../../finance/docs/adr/0007-axon-code-standardization.md)

---

## Package Structure

```
com.pax8.finance/              # Base package (shared across finance services)
├── api/                       # Shared: Commands, Events, Queries, Types
│   ├── commands.kt
│   ├── events.kt
│   ├── queries.kt
│   ├── entities.kt
│   ├── types.kt
│   └── views.kt
├── client/                    # External API clients (Feign)
├── config/                    # Configuration classes
├── endpoint/                  # REST controllers
│   ├── model/                 # Request/Response DTOs
│   └── validation/            # Request validators
├── {aggregate}/               # Per-aggregate package
│   ├── {Aggregate}.kt         # Aggregate root + handlers
│   ├── Commands.kt            # Aggregate-specific commands
│   ├── Events.kt              # Aggregate-specific events
│   ├── Queries.kt             # Aggregate-specific queries
│   ├── listeners/             # Event handlers
│   ├── query/                 # Query handlers + projections
│   └── sagas/                 # Saga definitions
├── repository/                # Spring Data repositories
├── service/                   # Supporting services
└── util/                      # Utilities
```

**Note:** Use `com.pax8.finance` as base package for all finance Axon services (enables Kafka event sharing).

---

## Core Components

### Commands (commands.kt or {Aggregate}/Commands.kt)

Commands express intent. Use data classes with target aggregate identifier.

```kotlin
data class CreateInvoiceCommand(
    @TargetAggregateIdentifier
    val invoiceId: String,
    val partnerId: String,
    val companyId: String,
    val lineItems: List<LineItem>,
    val dueDate: LocalDate
)

data class CancelInvoiceCommand(
    @TargetAggregateIdentifier
    val invoiceId: String,
    val reason: String
)
```

**Naming:** `{Action}{Aggregate}Command` (e.g., CreateInvoiceCommand, UpdateInvoiceCommand)

### Events (events.kt or {Aggregate}/Events.kt)

Events represent facts that happened. Immutable, past tense.

```kotlin
data class InvoiceCreatedEvent(
    val invoiceId: String,
    val partnerId: String,
    val companyId: String,
    val lineItems: List<LineItem>,
    val dueDate: LocalDate,
    val createdAt: Instant
)

data class InvoiceCancelledEvent(
    val invoiceId: String,
    val reason: String,
    val cancelledAt: Instant
)
```

**Naming:** `{Aggregate}{Action}Event` (e.g., InvoiceCreatedEvent, InvoiceCancelledEvent)

### Queries (queries.kt or {Aggregate}/Queries.kt)

Queries request read model data.

```kotlin
data class FindInvoiceQuery(
    val invoiceId: String
)

data class GetInvoicesByPartnerQuery(
    val partnerId: String,
    val status: InvoiceStatus? = null
)
```

**Naming:** `{Find|Get}{Subject}Query`

---

## Aggregate Root

Aggregate root handles commands and applies events.

```kotlin
@Aggregate
class Invoice {
    @AggregateIdentifier
    private lateinit var invoiceId: String
    private lateinit var status: InvoiceStatus
    private lateinit var partnerId: String

    constructor()

    @CommandHandler
    constructor(command: CreateInvoiceCommand) {
        AggregateLifecycle.apply(
            InvoiceCreatedEvent(
                invoiceId = command.invoiceId,
                partnerId = command.partnerId,
                companyId = command.companyId,
                lineItems = command.lineItems,
                dueDate = command.dueDate,
                createdAt = Instant.now()
            )
        )
    }

    @CommandHandler
    fun handle(command: CancelInvoiceCommand) {
        require(status != InvoiceStatus.CANCELLED) { "Invoice already cancelled" }
        AggregateLifecycle.apply(
            InvoiceCancelledEvent(
                invoiceId = invoiceId,
                reason = command.reason,
                cancelledAt = Instant.now()
            )
        )
    }

    @EventSourcingHandler
    fun on(event: InvoiceCreatedEvent) {
        invoiceId = event.invoiceId
        partnerId = event.partnerId
        status = InvoiceStatus.DRAFT
    }

    @EventSourcingHandler
    fun on(event: InvoiceCancelledEvent) {
        status = InvoiceStatus.CANCELLED
    }
}
```

**Rules:**
- Empty constructor required for Axon
- @CommandHandler on constructor for creation commands
- @CommandHandler on methods for mutation commands
- @EventSourcingHandler updates internal state ONLY (no side effects)
- Validate business rules in command handlers before applying events

---

## Query Side (Projections)

### Query Handler

```kotlin
@Component
class InvoiceQueryHandlers(
    private val repository: InvoiceStatusRepository
) {
    @QueryHandler
    fun handle(query: FindInvoiceQuery): InvoiceStatusEntity? {
        return repository.findById(query.invoiceId).orElse(null)
    }

    @QueryHandler
    fun handle(query: GetInvoicesByPartnerQuery): List<InvoiceStatusEntity> {
        return if (query.status != null) {
            repository.findByPartnerIdAndStatus(query.partnerId, query.status)
        } else {
            repository.findByPartnerId(query.partnerId)
        }
    }
}
```

### Projection (Event Handler)

```kotlin
@Component
class InvoiceStatusProjection(
    private val repository: InvoiceStatusRepository
) {
    @EventHandler
    fun on(event: InvoiceCreatedEvent) {
        val entity = InvoiceStatusEntity(
            invoiceId = event.invoiceId,
            partnerId = event.partnerId,
            status = InvoiceStatus.DRAFT,
            createdAt = event.createdAt
        )
        repository.save(entity)
    }

    @EventHandler
    fun on(event: InvoiceCancelledEvent) {
        repository.findById(event.invoiceId).ifPresent { entity ->
            entity.status = InvoiceStatus.CANCELLED
            entity.cancelledAt = event.cancelledAt
            repository.save(entity)
        }
    }
}
```

**Rules:**
- @EventHandler updates read models (projections)
- Projections are eventually consistent
- Can rebuild from event store if needed

---

## Sagas

Sagas coordinate long-running processes across aggregates.

```kotlin
@Saga
class InvoiceEmailSaga {
    @Autowired
    @Transient
    private lateinit var commandGateway: CommandGateway

    @Autowired
    @Transient
    private lateinit var notificationService: NotificationService

    private lateinit var invoiceId: String

    @StartSaga
    @SagaEventHandler(associationProperty = "invoiceId")
    fun on(event: InvoiceCreatedEvent) {
        invoiceId = event.invoiceId
        notificationService.sendInvoiceCreatedEmail(event)
    }

    @SagaEventHandler(associationProperty = "invoiceId")
    fun on(event: InvoiceCancelledEvent) {
        notificationService.sendInvoiceCancelledEmail(event)
        SagaLifecycle.end()
    }
}
```

**Rules:**
- Use @Transient for injected dependencies
- @StartSaga begins the saga
- SagaLifecycle.end() completes the saga
- Handle compensation logic for failures

---

## Controllers

Controllers dispatch commands and queries.

```kotlin
@RestController
@RequestMapping("/api/v1/invoices")
class InvoiceController(
    private val commandGateway: CommandGateway,
    private val queryGateway: QueryGateway
) {
    @PostMapping
    fun createInvoice(@RequestBody request: CreateInvoiceRequest): ResponseEntity<String> {
        val invoiceId = UUID.randomUUID().toString()
        commandGateway.sendAndWait<Unit>(
            CreateInvoiceCommand(
                invoiceId = invoiceId,
                partnerId = request.partnerId,
                companyId = request.companyId,
                lineItems = request.lineItems,
                dueDate = request.dueDate
            )
        )
        return ResponseEntity.status(HttpStatus.CREATED).body(invoiceId)
    }

    @GetMapping("/{invoiceId}")
    fun getInvoice(@PathVariable invoiceId: String): ResponseEntity<InvoiceStatusEntity> {
        val result = queryGateway.query(
            FindInvoiceQuery(invoiceId),
            ResponseTypes.instanceOf(InvoiceStatusEntity::class.java)
        ).join()
        return ResponseEntity.ok(result)
    }
}
```

---

## Testing

### Aggregate Tests (AggregateTestFixture)

```kotlin
class InvoiceAggregateTest {
    private lateinit var fixture: AggregateTestFixture<Invoice>

    @BeforeEach
    fun setup() {
        fixture = AggregateTestFixture(Invoice::class.java)
    }

    @Test
    fun `should create invoice`() {
        val command = CreateInvoiceCommand(
            invoiceId = "inv-123",
            partnerId = "partner-1",
            companyId = "company-1",
            lineItems = listOf(),
            dueDate = LocalDate.now().plusDays(30)
        )

        fixture.givenNoPriorActivity()
            .`when`(command)
            .expectSuccessfulHandlerExecution()
            .expectEvents(
                InvoiceCreatedEvent(
                    invoiceId = "inv-123",
                    partnerId = "partner-1",
                    companyId = "company-1",
                    lineItems = listOf(),
                    dueDate = LocalDate.now().plusDays(30),
                    createdAt = any()
                )
            )
    }

    @Test
    fun `should not cancel already cancelled invoice`() {
        fixture.given(
            InvoiceCreatedEvent(...),
            InvoiceCancelledEvent(...)
        )
            .`when`(CancelInvoiceCommand("inv-123", "duplicate"))
            .expectException(IllegalArgumentException::class.java)
    }
}
```

### Saga Tests (SagaTestFixture)

```kotlin
class InvoiceEmailSagaTest {
    private lateinit var fixture: SagaTestFixture<InvoiceEmailSaga>

    @BeforeEach
    fun setup() {
        fixture = SagaTestFixture(InvoiceEmailSaga::class.java)
    }

    @Test
    fun `should start saga on invoice created`() {
        fixture.givenNoPriorActivity()
            .whenPublishingA(InvoiceCreatedEvent(...))
            .expectActiveSagas(1)
    }
}
```

---

## Configuration

### Axon Config

```kotlin
@Configuration
class AxonConfig {
    @Bean
    fun snapshotTriggerDefinition(
        snapshotter: Snapshotter
    ): SnapshotTriggerDefinition {
        return EventCountSnapshotTriggerDefinition(snapshotter, 100)
    }
}
```

### application.yml

```yaml
axon:
  serializer:
    general: jackson
    messages: jackson
    events: jackson
  eventhandling:
    processors:
      invoice-projection:
        mode: tracking
        source: eventStore
```

---

## Checklist

Before completing a feature, verify:

- [ ] Commands express intent (imperative naming)
- [ ] Events represent facts (past tense naming)
- [ ] Aggregate validates business rules before applying events
- [ ] @EventSourcingHandler has no side effects
- [ ] Projections can be rebuilt from events
- [ ] Sagas handle compensation for failures
- [ ] AggregateTestFixture tests exist
- [ ] Event versioning considered for schema changes
