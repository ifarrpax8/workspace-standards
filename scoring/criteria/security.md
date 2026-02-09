# Scoring Criteria: Security (15 points)

Evaluates security practices, secret management, and vulnerability prevention.

## Scoring Rubric

### Secret Management (5 points)

| Score | Criteria |
|-------|----------|
| 5 | No secrets in code, proper env var usage, .gitignore configured |
| 4 | Minor issues (e.g., example secrets in comments) |
| 3 | Some hardcoded values that should be externalized |
| 2 | Secrets present but not production values |
| 1 | Production secrets in code or config |
| 0 | Critical secrets exposed |

**Detection:**
```bash
# Check for potential secrets
grep -rE "(password|secret|api_key|apikey|token).*=.*['\"]" src/ --include="*.kt" --include="*.ts" --include="*.vue"
grep -rE "Bearer [A-Za-z0-9]+" src/

# Check .gitignore exists and covers sensitive files
test -f ".gitignore" && grep -E "\.env|credentials|secrets" .gitignore
```

### Input Validation (5 points)

| Score | Criteria |
|-------|----------|
| 5 | All inputs validated, proper sanitization |
| 4 | Most inputs validated |
| 3 | Core inputs validated, some gaps |
| 2 | Inconsistent validation |
| 1 | Minimal validation |
| 0 | No input validation |

**Detection:**
```bash
# Kotlin - Check for validation annotations
grep -r "@Valid\|@NotNull\|@NotBlank\|@Size\|@Pattern" src/main/kotlin/ | wc -l

# Kotlin - Check for controller advice (error handling)
grep -r "@RestControllerAdvice\|@ControllerAdvice" src/main/kotlin/ | wc -l

# Vue - Check for input validation
grep -r "yup\|vee-validate\|validator" src/ | wc -l
```

### Security Packages & Patterns (5 points)

| Score | Criteria |
|-------|----------|
| 5 | Security packages configured, auth implemented, CORS set up |
| 4 | Most security concerns addressed |
| 3 | Basic security in place |
| 2 | Some security gaps |
| 1 | Minimal security |
| 0 | No security measures |

**Detection:**
```bash
# Kotlin - Check for Spring Security
grep -r "spring-boot-starter-security\|spring-security" build.gradle.kts | wc -l

# Kotlin - Check for OAuth/JWT
grep -r "oauth2\|jwt\|JwtDecoder" src/main/kotlin/ | wc -l

# Vue - Check for auth handling
grep -r "@auth0\|useAuth\|authService" src/ | wc -l

# Check for XSS protection
grep -r "dompurify\|sanitize\|xss" src/ | wc -l

# Check for CORS configuration
grep -r "CorsConfiguration\|@CrossOrigin\|cors" src/main/kotlin/ | wc -l
```

## Security Checklist by Project Type

### Kotlin Backend
- [ ] Spring Security configured
- [ ] JWT/OAuth2 validation
- [ ] CORS properly configured
- [ ] Input validation on all endpoints
- [ ] No SQL injection vulnerabilities (use parameterized queries)
- [ ] Proper error handling (no stack traces to client)
- [ ] Rate limiting considered

### Vue MFE
- [ ] XSS prevention (DOMPurify or similar)
- [ ] No eval() or innerHTML with user input
- [ ] Auth token handling (not in localStorage if sensitive)
- [ ] CORS awareness
- [ ] Input sanitization

## High-Risk Patterns to Detect

```bash
# Dangerous patterns
grep -r "eval(" src/                           # JavaScript eval
grep -r "innerHTML.*=" src/                    # Potential XSS
grep -r "dangerouslySetInnerHTML" src/         # React XSS risk
grep -r "v-html=" src/                         # Vue XSS risk (check sanitization)
grep -r "Runtime.getRuntime().exec" src/       # Command injection risk
grep -r "ProcessBuilder" src/                  # Command injection risk
```

## Manual Review Points

- [ ] Authentication required for sensitive endpoints
- [ ] Authorization checks in place
- [ ] Sensitive data encrypted at rest
- [ ] Audit logging for security events
- [ ] No debug endpoints in production
- [ ] Dependencies scanned for vulnerabilities

## Golden Path References

To improve your score in this category, reference these golden paths:

| Project Type | Golden Path | Relevant Sections |
|-------------|-------------|-------------------|
| Kotlin (Spring Boot) | [Kotlin Spring Boot](../../golden-paths/kotlin-spring-boot.md) | Layer Responsibilities (endpoint/model DTOs with validation annotations), Common Patterns (Controller Advice) |
| Kotlin (Axon) | [Kotlin Axon CQRS](../../golden-paths/kotlin-axon-cqrs.md) | Core Components (Commands, Events), Controllers |
| Vue MFE | [Vue MFE](../../golden-paths/vue-mfe.md) | Services (environment config), Component Patterns (typed props), Checklist (no hardcoded API URLs) |
| Terraform | [Terraform IaC](../../golden-paths/terraform-iac.md) | Security (No Hardcoded Secrets, Backend Encryption, Sensitive Outputs) |
| Playwright | [Integration Testing](../../golden-paths/integration-testing.md) | credentials/ (Credential Management) |
