# Security Checklist

Comprehensive security requirements for all projects.

## Pre-Development

- [ ] Security requirements identified in ticket
- [ ] Threat model considered for new features
- [ ] Authentication/Authorization requirements defined

## During Development

### Secret Management
- [ ] No hardcoded credentials, API keys, or tokens
- [ ] Environment variables used for configuration
- [ ] `.gitignore` includes sensitive files (`.env`, `credentials.json`)
- [ ] Secret scanning enabled (detect-secrets, gitleaks)

### Input Validation
- [ ] All user inputs validated server-side
- [ ] Validation annotations on DTOs (`@NotBlank`, `@Size`, `@Pattern`)
- [ ] Frontend validation matches backend validation
- [ ] File uploads validated (type, size, content)

### Output Encoding
- [ ] HTML output escaped by default
- [ ] `v-html` only used with DOMPurify sanitization
- [ ] JSON responses properly encoded
- [ ] No sensitive data in error messages

### Authentication
- [ ] Endpoints require authentication where appropriate
- [ ] JWT tokens validated properly
- [ ] Session management follows best practices
- [ ] Password requirements enforced (if applicable)

### Authorization
- [ ] Resource-level authorization checked
- [ ] Role-based access control implemented
- [ ] Permission checks at service layer
- [ ] No authorization bypass via direct object reference

### Data Protection
- [ ] Sensitive data encrypted in transit (HTTPS)
- [ ] Sensitive data encrypted at rest (where required)
- [ ] PII handled according to compliance requirements
- [ ] Data retention policies followed

## Code Review Security Checks

### Kotlin/Java
```
- [ ] @Valid on request bodies
- [ ] Parameterized queries (no string concatenation in SQL)
- [ ] No Runtime.exec() with user input
- [ ] Proper exception handling (no stack traces to client)
- [ ] Logging doesn't include sensitive data
```

### Vue/TypeScript
```
- [ ] No eval() or Function() constructor
- [ ] No innerHTML without sanitization
- [ ] No document.write()
- [ ] XSS-safe template usage
- [ ] API keys not in frontend code
```

### General
```
- [ ] No TODO/FIXME for security items
- [ ] Dependencies up to date
- [ ] No known vulnerable dependencies
- [ ] CORS configured appropriately
```

## Pre-Deployment

- [ ] Security scan completed (SAST)
- [ ] Dependency vulnerabilities addressed
- [ ] Secrets rotated if exposed during development
- [ ] Access controls verified in target environment

## Security Packages Reference

### Kotlin/Spring Boot
```kotlin
// build.gradle.kts
implementation("org.springframework.boot:spring-boot-starter-security")
implementation("org.springframework.boot:spring-boot-starter-oauth2-resource-server")
implementation("org.springframework.boot:spring-boot-starter-validation")
```

### Vue/Node
```json
// package.json
{
  "dependencies": {
    "dompurify": "^3.x"
  },
  "devDependencies": {
    "@auth0/auth0-spa-js": "^2.x"
  }
}
```

> **Note:** Prefer `dompurify` over the `xss` package. DOMPurify is the recommended sanitization library per our [security standards](../rules/auto-apply/security-standards.md).

## Common Vulnerabilities to Avoid

### OWASP Top 10 Reference

| Vulnerability | Prevention |
|--------------|------------|
| **Injection** | Parameterized queries, input validation |
| **Broken Authentication** | Strong session management, MFA |
| **Sensitive Data Exposure** | Encryption, proper data handling |
| **XML External Entities** | Disable DTD processing |
| **Broken Access Control** | Authorization checks at every layer |
| **Security Misconfiguration** | Secure defaults, remove debug features |
| **Cross-Site Scripting (XSS)** | Output encoding, Content Security Policy |
| **Insecure Deserialization** | Validate serialized data, use safe formats |
| **Using Vulnerable Components** | Keep dependencies updated, scan regularly |
| **Insufficient Logging** | Log security events, monitor for anomalies |

## Incident Response

If a security issue is discovered:

1. **Do not** commit a fix that reveals the vulnerability
2. **Notify** security team immediately
3. **Assess** impact and affected systems
4. **Contain** the issue (rotate secrets, disable features)
5. **Remediate** with proper fix
6. **Document** in post-incident review

## Resources

- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [Spring Security Reference](https://docs.spring.io/spring-security/reference/)
- [Vue Security Best Practices](https://vuejs.org/guide/best-practices/security.html)
