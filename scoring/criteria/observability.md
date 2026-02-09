# Scoring Criteria: Observability (10 points)

Evaluates logging, metrics, and tracing setup for backend services.

**Note:** This category primarily applies to backend (Kotlin/Java) services. Frontend MFEs should use the `@pax8/observability` package and have console.log disabled via ESLint.

## Scoring Rubric

### Logging Setup (4 points)

| Score | Criteria |
|-------|----------|
| 4 | Logback configured with JSON encoder, OpenTelemetry appender, proper log levels |
| 3 | Logback configured with JSON encoder |
| 2 | Logback configured (basic) |
| 1 | Some logging configuration |
| 0 | No logging configuration |

**Detection:**
```bash
# Check for logback config
test -f "src/main/resources/logback-spring.xml" && echo "1" || echo "0"

# Check for JSON encoder (structured logging)
grep -q "LogstashEncoder\|JsonEncoder" src/main/resources/logback-spring.xml 2>/dev/null && echo "1" || echo "0"

# Check for OpenTelemetry appender (trace correlation)
grep -q "OpenTelemetryAppender" src/main/resources/logback-spring.xml 2>/dev/null && echo "1" || echo "0"
```

### Metrics Setup (3 points)

| Score | Criteria |
|-------|----------|
| 3 | Micrometer + Prometheus configured, actuator endpoints exposed |
| 2 | Micrometer configured |
| 1 | Basic actuator endpoints |
| 0 | No metrics setup |

**Detection:**
```bash
# Check for Micrometer/Prometheus in build file
grep -q "micrometer-registry-prometheus\|micrometer" build.gradle.kts 2>/dev/null && echo "1" || echo "0"

# Check for actuator endpoints
grep -q "prometheus\|health" src/main/resources/application.yml 2>/dev/null && echo "1" || echo "0"
```

### Tracing Setup (3 points)

| Score | Criteria |
|-------|----------|
| 3 | OpenTelemetry SDK configured with instrumentation |
| 2 | OpenTelemetry SDK present |
| 1 | Basic tracing setup |
| 0 | No tracing |

**Detection:**
```bash
# Check for OpenTelemetry dependencies
grep -q "opentelemetry" build.gradle.kts 2>/dev/null && echo "1" || echo "0"

# Check for instrumentation annotations
grep -rq "opentelemetry-instrumentation-annotations" build.gradle.kts 2>/dev/null && echo "1" || echo "0"

# Check for Axon tracing (if Axon project)
grep -q "axon-tracing-opentelemetry" build.gradle.kts 2>/dev/null && echo "1" || echo "0"
```

## Expected Stack (Backend Kotlin)

### Dependencies (build.gradle.kts)
```kotlin
implementation("io.opentelemetry:opentelemetry-sdk")
implementation("io.opentelemetry.instrumentation:opentelemetry-instrumentation-annotations")
runtimeOnly("io.micrometer:micrometer-registry-prometheus")

// For Axon services
implementation("org.axonframework:axon-tracing-opentelemetry")
```

### Logging Configuration (logback-spring.xml)
```xml
<configuration>
    <springProfile name="!local &amp; !test">
        <appender name="jsonConsole" class="ch.qos.logback.core.ConsoleAppender">
            <encoder class="net.logstash.logback.encoder.LogstashEncoder">
                <timestampPattern>yyyy-MM-dd'T'HH:mm:ss.SSSZ</timestampPattern>
            </encoder>
        </appender>

        <appender name="OTEL" class="io.opentelemetry.instrumentation.logback.mdc.v1_0.OpenTelemetryAppender">
            <appender-ref ref="jsonConsole"/>
        </appender>

        <root level="INFO">
            <appender-ref ref="OTEL"/>
        </root>
    </springProfile>
</configuration>
```

### Actuator Configuration (application.yml)
```yaml
management:
  endpoints:
    web:
      exposure:
        include: prometheus,health,info
  metrics:
    export:
      prometheus:
        enabled: true
```

## Logging Best Practices

### Do
```kotlin
private val logger = LoggerFactory.getLogger(MyService::class.java)

fun processOrder(orderId: String) {
    logger.info("Processing order", kv("orderId", orderId))
    try {
        // business logic
        logger.info("Order processed successfully", kv("orderId", orderId))
    } catch (e: Exception) {
        logger.error("Failed to process order", kv("orderId", orderId), e)
        throw e
    }
}
```

### Don't
```kotlin
// BAD: No structured data
logger.info("Processing order $orderId")

// BAD: Logging sensitive data
logger.info("User password: $password")

// BAD: Excessive logging in loops
items.forEach { logger.debug("Processing item $it") }

// BAD: Using println
println("Debug: $value")
```

## Frontend Observability

For Vue MFEs, observability is handled by:
- `@pax8/observability` package (required dependency)
- ESLint rule disabling `console.log`

**Detection for Vue:**
```bash
# Check for observability package
grep -q "@pax8/observability" package.json && echo "1" || echo "0"

# Check for console.log ESLint rule
grep -rq "no-console" .eslintrc* && echo "1" || echo "0"
```

## Manual Review Points

- [ ] Structured logging used (key-value pairs)
- [ ] Appropriate log levels (INFO for business events, DEBUG for troubleshooting)
- [ ] No sensitive data in logs (passwords, tokens, PII)
- [ ] Trace correlation enabled (trace IDs in logs)
- [ ] Custom metrics defined for business KPIs
- [ ] Health checks include dependency checks
- [ ] Error logs include stack traces
