---
description: Security standards for all projects
globs: ["**/*"]
alwaysApply: true
---

# Security Standards

Follow these security practices in all code.

## Secret Management

**Never hardcode secrets:**
```kotlin
// BAD
val apiKey = "sk_live_abc123"

// GOOD
val apiKey = System.getenv("API_KEY")
```

```typescript
// BAD
const apiKey = 'sk_live_abc123'

// GOOD
const apiKey = import.meta.env.VITE_API_KEY
```

**Check before committing:**
- No passwords, API keys, tokens in code
- No connection strings with credentials
- No private keys or certificates
- Use environment variables or secret managers

## Input Validation

**Backend (Kotlin):**
```kotlin
data class CreateRequest(
    @field:NotBlank @field:Size(max = 100) val name: String,
    @field:Email val email: String,
    @field:Positive val amount: BigDecimal
)

@PostMapping
fun create(@Valid @RequestBody request: CreateRequest) { }
```

**Frontend (Vue):**
```typescript
import { object, string, number } from 'yup'

const schema = object({
  name: string().required().max(100),
  email: string().email().required(),
  amount: number().positive().required()
})
```

## XSS Prevention

**Never use v-html with untrusted content:**
```vue
// BAD
<div v-html="userInput"></div>

// GOOD
<div v-html="sanitize(userInput)"></div>

<script setup>
import DOMPurify from 'dompurify'
const sanitize = (html: string) => DOMPurify.sanitize(html)
</script>
```

**Use text interpolation for user content:**
```vue
// GOOD - automatically escaped
<p>{{ userInput }}</p>
```

## Authentication & Authorization

**Always verify authentication:**
```kotlin
@GetMapping("/protected")
fun protectedEndpoint(@AuthenticationPrincipal user: User): Response {
    // user is authenticated
}
```

**Check authorization for sensitive operations:**
```kotlin
fun deleteResource(resourceId: String, user: User) {
    val resource = repository.findById(resourceId)
    require(resource.ownerId == user.id) { "Not authorized" }
    // proceed with deletion
}
```

## Error Handling

**Never expose stack traces:**
```kotlin
// BAD
@ExceptionHandler(Exception::class)
fun handleError(ex: Exception) = ResponseEntity
    .status(500)
    .body(ex.stackTraceToString())  // Exposes internals

// GOOD
@ExceptionHandler(Exception::class)
fun handleError(ex: Exception): ResponseEntity<ErrorResponse> {
    logger.error("Unexpected error", ex)  // Log full details
    return ResponseEntity
        .status(500)
        .body(ErrorResponse("An unexpected error occurred"))  // Generic message
}
```

## SQL Injection Prevention

**Use parameterized queries:**
```kotlin
// BAD
@Query("SELECT * FROM users WHERE name = '$name'")
fun findByName(name: String): User

// GOOD
@Query("SELECT * FROM users WHERE name = :name")
fun findByName(@Param("name") name: String): User
```

## Dependency Security

- Keep dependencies updated
- Use Dependabot for automated updates
- Review security advisories
- Run `npm audit` / dependency-check regularly

## Sensitive Data Handling

**Mask sensitive data in logs:**
```kotlin
logger.info("Processing payment for card ending in ${cardNumber.takeLast(4)}")
```

**Don't log:**
- Full credit card numbers
- Passwords or tokens
- Personal identification numbers
- Full social security numbers

## CORS Configuration

**Be specific with allowed origins:**
```kotlin
// BAD
@CrossOrigin(origins = ["*"])

// GOOD
@CrossOrigin(origins = ["\${app.allowed-origins}"])
```

## Security Checklist

Before committing:
- [ ] No hardcoded secrets
- [ ] Input validation on all endpoints
- [ ] XSS protection (sanitized HTML, escaped output)
- [ ] SQL injection protection (parameterized queries)
- [ ] Proper error handling (no stack traces to client)
- [ ] Authentication required for protected endpoints
- [ ] Authorization checked for sensitive operations
- [ ] Sensitive data masked in logs
