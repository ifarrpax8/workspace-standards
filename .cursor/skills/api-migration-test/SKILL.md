---
name: api-migration-test
description: Generate a three-phase test script for comparing a legacy API endpoint against its replacement during migration.
---

# API Migration Test

Generate a consolidated Node.js test script that validates input, diagnoses filters incrementally, and A/B compares a legacy endpoint against its new replacement.

## When to Use

- Migrating a legacy API endpoint to a new implementation (e.g., SQL to OpenSearch)
- Replacing an endpoint while maintaining backward-compatible response shape
- Need repeatable manual verification that legacy and new endpoints return equivalent results
- Want to isolate which query parameter or filter is causing result discrepancies

## When NOT to Use

- **Automated regression testing** — use unit/integration tests instead
- **Load or performance testing** — use dedicated load testing tools
- **Schema-only comparison** — use contract testing or OpenAPI diff
- **Single endpoint validation** — just use curl or Postman

## Invocation

```
Generate an API migration test script comparing legacy GET /v1/widgets
against the new GET /v2/widgets/search endpoint
```

```
Create an A/B test script for the invoice line items endpoint migration
```

## Workflow

### Phase 1: Gather Context

1. Identify the **legacy endpoint** (URL, method, required/optional params, defaults, response shape)
2. Identify the **new endpoint** (URL, method, required/optional params, defaults, response shape)
3. Determine the **shared unique identifier** in both responses for matching (e.g., `guid`, `id`)
4. Note **parameter differences** between the two endpoints:
   - Different parameter names for the same concept (e.g., `invoicePeriod` vs `invoiceDate`)
   - Different formats (e.g., `yyyy-MM-dd` vs `yyyy-MM`)
   - Different defaults (e.g., legacy defaults `customerInvoices=false`, new has no default)
   - Different pagination models (e.g., `page`/`size` vs `max`/`offset`)

### Phase 2: Generate the Test Script

Generate a single Node.js script with three sections:

#### Section 1: Input Validation

Test that required parameters are enforced and invalid inputs are rejected:

- Missing required parameter → expect error (e.g., 400)
- Empty string for required parameter → expect error
- Whitespace-only value → expect error
- Invalid format (e.g., wrong date format) → expect error
- Injection attempt (e.g., SQL injection in date param) → expect error
- Valid values → expect 200

```javascript
async function runValidation() {
  await testEndpoint('Missing requiredParam (expect 400)', {});
  await testEndpoint('Empty requiredParam (expect 400)', { requiredParam: '' });
  await testEndpoint('Invalid format (expect 400)', { requiredParam: 'garbage' });
  await testEndpoint('Valid input (expect 200)', { requiredParam: 'valid-value' });
}
```

#### Section 2: Incremental Filter Diagnosis

Add filters one at a time to isolate which combination causes zero results. Always include required parameters. Group tests logically:

```javascript
async function runDiagnosis() {
  // Required params only
  await testEndpoint('Required params only', { requiredParam: VALUE });

  // Add each optional filter individually
  await testEndpoint('+ filterA', { requiredParam: VALUE, filterA: 'x' });
  await testEndpoint('+ filterB', { requiredParam: VALUE, filterB: 'y' });

  // Combine filters
  await testEndpoint('+ filterA + filterB', { requiredParam: VALUE, filterA: 'x', filterB: 'y' });
}
```

Key principles:
- Start broad (fewer filters = more results) and narrow down
- Log the total result count and a sample record for each test
- Use `[OK]`, `[ZERO]`, or `[ERR status]` prefixes for scannable output

#### Section 3: Legacy vs New Comparison

Fetch records from both endpoints with equivalent filters, then match by unique identifier and compare field-by-field:

```javascript
async function runComparison() {
  const [legacy, search] = await Promise.all([fetchLegacy(), fetchNew()]);

  // Build lookup by shared unique ID
  const newByGuid = new Map();
  for (const rec of newRecords) {
    newByGuid.set(String(rec.id), rec);
  }

  // Find overlapping records and compare first match
  for (const legacyRec of legacyRecords) {
    if (newByGuid.has(String(legacyRec.id))) {
      compareFieldByField(legacyRec, newByGuid.get(String(legacyRec.id)));
      break;
    }
  }
}
```

The field-by-field comparison should categorize each field as:
- **Matching** — same key and value in both
- **Value difference** — same key, different value (show both)
- **Legacy only** — field exists only in legacy response
- **New only** — field exists only in new response

Fetch more records from the new endpoint than the legacy (e.g., 500 vs 50) to increase the chance of GUID overlap when pagination differs.

### Phase 3: Script Structure

The generated script should follow this structure:

```javascript
// Configuration at the top - easy to change per environment
const BASE_URL = 'https://env.example.com/api';
const AUTH_TOKEN = process.env.AUTH_TOKEN;
const SHARED_PARAMS = { /* common test values */ };

// Reusable test helper with consistent output formatting
async function testEndpoint(label, params) { /* ... */ }

// Three test sections
async function runValidation() { /* ... */ }
async function runDiagnosis() { /* ... */ }
async function runComparison() { /* ... */ }

// Main runner
async function main() {
  await runValidation();
  await runDiagnosis();
  await runComparison();
}
```

Key requirements:
- `AUTH_TOKEN` read from environment variable with clear usage instructions on failure
- All URLs and test values as constants at the top
- Consistent output formatting with section headers and tags
- Graceful error handling (catch and display, don't crash)
- axios as the only dependency (already available in most projects)

## Verification

- **Phase 1**: Confirm both endpoints are documented with their full parameter contracts
- **Phase 2**: Run the script and verify:
  - Validation section shows expected error codes for invalid inputs
  - Diagnosis section shows `[OK]` for at least one filter combination
  - Comparison section finds overlapping records (if both endpoints have data)
- **Phase 3**: Confirm the script runs end-to-end without crashing even when endpoints return errors

## Worked Example

**Input:** `Generate an API migration test for legacy GET /v3/invoices/line-items vs new GET /v3/invoices/line-items/search`

**Key steps:**
1. Identified parameter differences: legacy requires `invoiceDate` in `yyyy-MM-dd`, new accepts `yyyy-MM`; legacy defaults `customerInvoices=false`, new has no default; legacy paginates with `page`/`size`, new uses `max`/`offset`
2. Generated script with 5 validation tests, 7 diagnosis tests, and GUID-based comparison
3. Running the script revealed that `invoiceDate` filter produced zero results — diagnosed as epoch millis vs Date object mismatch in the OpenSearch range query
4. After fix and re-deploy, comparison found overlapping records and identified field naming differences (e.g., `invoiceId` was numeric Long vs UUID)

**Output excerpt:**
```
========================================
 1. INPUT VALIDATION
========================================

  [ERR 400] No invoiceDate (expect 400): invoiceDate parameter is required
  [ERR 400] Invalid format (expect 400): invoiceDate must be in yyyy-MM or yyyy-MM-dd format

========================================
 2. FILTER DIAGNOSIS
========================================

  [OK] invoiceDate=2025-08: 14782 results
        sample: Azure Plan | invoiceDate=2025-08-01 | isCustomerInvoice=true
  [OK] partnerId + invoiceDate=2025-08: 716 results
  [OK] partnerId + customerInvoices=false + invoiceDate=2025-08: 42 results

========================================
 3. LEGACY vs SEARCH COMPARISON
========================================

  Legacy: 50 records
  Search: 42 records (totalFound=42)

  Overlapping GUIDs: 42 / 50 legacy records

  Matching fields (28):
    chargeType: "per"
    clientName: "Test Client"
    ...
  Value differences (2):
    invoiceId:
      Legacy: "abc-123-uuid"
      Search: 12345
```

## Error Handling

### No overlapping records found

The endpoints may be returning different record sets due to:
- Different default filter values (e.g., legacy defaults `customerInvoices=false`)
- Pagination mismatch (legacy returns page 1, new returns different sort order)
- Index not yet rebuilt after schema changes

**Resolution:** Increase the fetch size on the new endpoint, ensure shared filters are aligned, check that the index is fully populated.

### One endpoint returns zero results

Run the diagnosis section to isolate which filter causes the drop. Common causes:
- Date format mismatch (epoch millis vs date string in the query)
- Field name mismatch in the query (e.g., `partnerId` vs `partnerId.keyword`)
- Data not yet indexed or index schema mismatch

### Authentication errors

Ensure `AUTH_TOKEN` includes the scheme prefix (e.g., `Bearer ...`) and is not expired. The script reads it from the environment variable for security.

## Related Resources

- [Testing Facet](../../../engineering-codex/facets/testing/README.md) — Testing strategies and best practices
- [API Design Facet](../../../engineering-codex/facets/api-design/README.md) — API contract design principles
- [Groovy Monolith Golden Path](../../golden-paths/groovy-monolith.md) — Patterns for the legacy monolith
