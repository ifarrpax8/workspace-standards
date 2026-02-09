# Golden Path: Kotlin Spring Boot (Layered Architecture)

Standard architecture for Kotlin/Spring Boot microservices that don't require event sourcing.

**Use when:** Building CRUD-style services, simple domain logic, no audit trail requirements.

**Reference implementations:** currency-manager, report-manager

---

## Package Structure

```
com.pax8.{servicename}/
├── config/              # Configuration classes
├── endpoint/            # REST controllers
│   └── model/           # Request/Response DTOs
├── exception/           # Custom exceptions
├── model/               # Domain models
│   ├── entities/        # Database entities
│   └── events/          # Domain events (if using Kafka)
├── repository/          # Data access layer
├── service/             # Business logic
│   └── helper/          # Service helpers
├── validation/          # Custom validators
└── {ServiceName}Application.kt
```

---

## Layer Responsibilities

### endpoint/ (Controllers)

Controllers handle HTTP concerns only. No business logic.

```kotlin
@RestController
@RequestMapping("/api/v1/rates")
class CurrencyExchangeRatesController(
    private val service: CurrencyExchangeRateService
) {
    @GetMapping("/{baseCurrency}/{quoteCurrency}")
    fun getRate(
        @PathVariable baseCurrency: String,
        @PathVariable quoteCurrency: String
    ): ResponseEntity<CurrencyExchangeRateResponse> {
        return ResponseEntity.ok(service.getRate(baseCurrency, quoteCurrency))
    }
}
```

**Rules:**
- Constructor injection only
- Map request → service call → response
- Use ResponseEntity for HTTP semantics
- Validation annotations on request parameters

### endpoint/model/ (DTOs)

Separate request and response models from domain entities.

```kotlin
data class CurrencyExchangeRateRequest(
    @field:NotBlank val baseCurrency: String,
    @field:NotBlank val quoteCurrency: String,
    @field:Positive val rate: BigDecimal
)

data class CurrencyExchangeRateResponse(
    val baseCurrency: String,
    val quoteCurrency: String,
    val rate: BigDecimal,
    val effectiveDate: Instant
)
```

**Rules:**
- Use data classes
- Validation annotations on request fields
- No domain logic in DTOs

### service/ (Business Logic)

All business rules live here.

```kotlin
@Service
class CurrencyExchangeRateService(
    private val repository: CurrencyExchangeRateRepository,
    private val validationHelper: RateValidationHelper,
    private val eventDispatcher: CurrencyExchangeRateEventDispatcher
) {
    fun createRate(request: CurrencyExchangeRateRequest): CurrencyExchangeRate {
        validationHelper.validateNewRate(request)
        val rate = CurrencyExchangeRate(
            baseCurrency = request.baseCurrency,
            quoteCurrency = request.quoteCurrency,
            rate = request.rate
        )
        val saved = repository.save(rate)
        eventDispatcher.dispatch(RateCreatedEvent(saved))
        return saved
    }
}
```

**Rules:**
- Single responsibility per service
- Inject repositories and other services via constructor
- Throw domain exceptions, not HTTP exceptions
- Use helper classes to avoid bloated services

### repository/ (Data Access)

Spring Data repositories for database operations.

```kotlin
interface CurrencyExchangeRateRepository : MongoRepository<CurrencyExchangeRate, String> {
    fun findByBaseCurrencyAndQuoteCurrency(
        baseCurrency: String,
        quoteCurrency: String
    ): CurrencyExchangeRate?
}
```

**Rules:**
- Extend Spring Data interfaces
- Use query methods or @Query for custom queries
- Keep repository interface clean (no default implementations)

### model/entities/ (Domain Entities)

```kotlin
@Document(collection = "currency_exchange_rates")
data class CurrencyExchangeRate(
    @Id val id: String? = null,
    val baseCurrency: String,
    val quoteCurrency: String,
    val rate: BigDecimal,
    val effectiveDate: Instant = Instant.now(),
    @Version val version: Long? = null
)
```

**Rules:**
- Use data classes for entities
- Include @Version for optimistic locking
- Use appropriate persistence annotations (@Document, @Entity)

### exception/ (Custom Exceptions)

```kotlin
class RateNotFoundException(
    baseCurrency: String,
    quoteCurrency: String
) : RuntimeException("Rate not found for $baseCurrency/$quoteCurrency")

class InvalidRequestException(
    message: String
) : RuntimeException(message)
```

**Rules:**
- Extend RuntimeException
- Descriptive exception names
- Include context in message

### config/ (Configuration)

```kotlin
@Configuration
class MongoConfig {
    @Bean
    fun mongoCustomConversions(): MongoCustomConversions {
        return MongoCustomConversions(listOf(
            BigDecimalToDecimal128Converter(),
            Decimal128ToBigDecimalConverter()
        ))
    }
}
```

**Rules:**
- One config class per concern (Kafka, Mongo, OpenAPI, etc.)
- Use @ConfigurationProperties for external config
- Document non-obvious configuration

---

## Configuration Files

### application.yml

```yaml
spring:
  application:
    name: currency-manager
  data:
    mongodb:
      uri: ${MONGO_URI:mongodb://localhost:27017/currency-manager}

server:
  port: 8080

management:
  endpoints:
    web:
      exposure:
        include: health,info,prometheus
```

### bootstrap.yml (if using Spring Cloud Config)

```yaml
spring:
  cloud:
    config:
      uri: ${CONFIG_SERVER_URI:http://localhost:8888}
```

---

## Testing Strategy

### Integration Tests (Preferred)

```kotlin
@SpringBootTest
@AutoConfigureMockMvc
class CurrencyExchangeRateControllerIntegrationTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var repository: CurrencyExchangeRateRepository

    @BeforeEach
    fun setup() {
        repository.deleteAll()
    }

    @Test
    fun `should create rate`() {
        mockMvc.perform(
            post("/api/v1/rates")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""{"baseCurrency":"USD","quoteCurrency":"EUR","rate":0.85}""")
        )
            .andExpect(status().isCreated)
            .andExpect(jsonPath("$.rate").value(0.85))
    }
}
```

### Unit Tests (When Necessary)

```kotlin
class RateValidationHelperTest {
    private val helper = RateValidationHelper()

    @Test
    fun `should reject negative rate`() {
        val request = CurrencyExchangeRateRequest("USD", "EUR", BigDecimal("-1"))
        assertThrows<InvalidRequestException> {
            helper.validateNewRate(request)
        }
    }
}
```

---

## Common Patterns

### Controller Advice for Exception Handling

```kotlin
@RestControllerAdvice
class ControllerAdvice {
    @ExceptionHandler(RateNotFoundException::class)
    fun handleNotFound(ex: RateNotFoundException): ResponseEntity<ErrorResponse> {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(ErrorResponse(ex.message ?: "Not found"))
    }

    @ExceptionHandler(InvalidRequestException::class)
    fun handleBadRequest(ex: InvalidRequestException): ResponseEntity<ErrorResponse> {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(ErrorResponse(ex.message ?: "Invalid request"))
    }
}
```

### Auditing with Interceptors

```kotlin
@Component
class AuditInterceptor : HandlerInterceptor {
    override fun preHandle(
        request: HttpServletRequest,
        response: HttpServletResponse,
        handler: Any
    ): Boolean {
        MDC.put("requestId", UUID.randomUUID().toString())
        return true
    }
}
```

---

## Checklist

Before completing a feature, verify:

- [ ] Controllers have no business logic
- [ ] Request/Response DTOs are separate from entities
- [ ] Services handle all business rules
- [ ] Custom exceptions are thrown (not HTTP exceptions from services)
- [ ] Integration tests cover the full flow
- [ ] Configuration is externalized (no hardcoded values)
- [ ] Logging uses SLF4J with appropriate levels
