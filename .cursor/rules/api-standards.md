---
description: API design and development standards for REST APIs and event-driven APIs
globs: ["**/endpoint/**/*.kt", "**/controller/**/*.kt", "**/api/**/*.kt", "**/events/**/*.kt"]
alwaysApply: false
---

# API Standards

Follow these standards when building REST APIs or event-driven APIs.

## REST API Design

- Use plural nouns in kebab-case for resource paths (`/orders`, `/business-units`)
- Never add HTTP verbs to the path (`/orders` not `/createOrder`)
- Use correct HTTP methods: GET (read), POST (create), PUT (replace), PATCH (update), DELETE (remove)
- Return correct status codes: 201 (POST create), 200 (GET/PUT/PATCH/DELETE), 400 (malformed), 401 (unauthenticated), 403 (unauthorised), 404 (not found), 409 (conflict), 422 (business rule violation)
- Use UUIDs (preferably UUIDv7) for all resource identifiers
- Use camelCase for JSON field names
- Use ISO 8601 UTC timestamps for all date/time fields

## API-First Development

- Design the API spec in TypeSpec or OpenAPI before writing implementation code
- Generate server stubs and client types from the spec
- Review API design with the team before implementation

## Pagination

- Use cursor-based pagination for all new list endpoints
- Response fields: `content`, `nextCursor`, `prevCursor`, `hasMore`, `limit`
- Never return unbounded collections

## Idempotency

- Support `Idempotency-Key` header on POST endpoints (and other mutations if org standard requires)
- Store idempotency keys with response; return cached response for duplicate keys with same payload
- Return 409 Conflict for same key with different payload or concurrent processing

## Error Responses

- Use a consistent error format across all endpoints (RFC 9457 or org-specific standard)
- Include error codes for machine consumption alongside human-readable messages
- Include trace IDs in error responses for debugging
- Return field-level details for validation errors
- Never expose stack traces, internal service names, or database errors

## Response Design

- Return nested objects with base data (id, name, email) instead of bare ID fields
- Audit fields (if included) should use a consistent format across all endpoints
- Support W3C Trace Context (`traceparent`/`tracestate`) for distributed tracing

## Event-Driven APIs

- Include `id` (aggregate ID), `messageId` (for idempotency), and `updatedTime` on all events
- Use Event-Carried State Transfer: events contain complete aggregate state
- Name events with specific business actions (`OrderCompleted`, `InvoiceGenerated`) not generic CRUD labels
- Use one topic per domain aggregate to maintain ordering
- Design idempotent consumers (handle duplicate delivery)
- Use dead letter queues for poison messages after retry exhaustion

## Security

- All endpoints require valid authentication (except health checks)
- Implement authorisation checks at the service layer (RBAC or FGA)
- Validate all input parameters server-side
- Never expose sensitive data (passwords, tokens, PII) in responses or logs

## Reference

- Engineering Codex: [API Design facet](https://github.com/pax8/engineering-codex/tree/main/facets/api-design)
- Engineering Codex: [Error Handling facet](https://github.com/pax8/engineering-codex/tree/main/facets/error-handling)
- Engineering Codex: [Event-Driven Architecture facet](https://github.com/pax8/engineering-codex/tree/main/facets/event-driven-architecture)
- Golden Path: [Kotlin Spring Boot](../golden-paths/kotlin-spring-boot.md)
