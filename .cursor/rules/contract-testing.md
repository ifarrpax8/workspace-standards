---
description: Pact consumer-driven contract test conventions — PactDslJsonBody field inclusion and optional field handling
globs: ["**/*Contract*.kt", "**/*Pact*.kt", "**/*Test*.kt", "**/*Spec*.kt"]
alwaysApply: false
type: "auto"
---

# Contract Testing Standards

These standards apply to Pact consumer-driven contract tests.

## Optional Fields in PactDslJsonBody

**Do not include optional or nullable fields** in `PactDslJsonBody` definitions.

```kotlin
// BAD — includes nullable field, makes the contract brittle
PactDslJsonBody()
  .stringType("id", "abc-123")
  .stringType("name", "Example")
  .stringType("description", null)  // nullable — omit this

// GOOD — only required fields in the contract
PactDslJsonBody()
  .stringType("id", "abc-123")
  .stringType("name", "Example")
```

**Rationale:** Including optional fields means the provider must always return them, even when they have no value. This makes contracts unnecessarily rigid and causes failures when the provider legitimately omits fields that have no data.

The rule: if a field is `String?`, `List?`, or any nullable/optional type in the provider's response model, exclude it from the `PactDslJsonBody`. The contract should represent the minimum the consumer actually needs.

## Matching vs Exact Values

Prefer type matchers over exact values to keep contracts resilient:

```kotlin
// BAD — breaks if the ID format changes
.stringValue("id", "abc-123")

// GOOD — asserts the field exists and is a string
.stringType("id", "abc-123")

// GOOD — asserts format with regex
.stringMatcher("currency", "[A-Z]{3}", "USD")
```

Use exact values only for fields whose exact content the consumer genuinely depends on (e.g. enum values, status codes).

## Running Contract Tests

Contract tests require the Pact broker to be reachable or a local mock. Verify with:

```bash
./gradlew test -Dtest="*Contract*"
./gradlew pactVerify
```

Always run `pactVerify` before publishing a new consumer pact — it confirms the provider already satisfies the contract.
