---
name: error-response-parsing
description: Parse ADR 00081 API error responses on the frontend — TypeScript types, field-level errors, i18n key derivation, traceId logging
---

# Error Response Parsing

ADR 00081 standardised the API error response format. This skill covers how to consume it correctly on the frontend.

## The Format

```json
{
  "type": "INVALID_REQUEST",
  "status": 400,
  "traceId": "0af7651916cd43dd8448eb211c80319c",
  "details": [
    {
      "code": "FIELD_REQUIRED",
      "message": "The 'email' field is required",
      "field": "email"
    }
  ]
}
```

## TypeScript Types

```typescript
interface ApiErrorDetail {
  code: string;
  message: string;
  field?: string;
}

interface ApiErrorResponse {
  type: string;
  status: number;
  traceId?: string;
  details: ApiErrorDetail[];
}

// Type guard for axios errors
function isApiError(error: unknown): error is { response: { data: ApiErrorResponse } } {
  return (
    typeof error === 'object' &&
    error !== null &&
    'response' in error &&
    typeof (error as any).response?.data?.type === 'string' &&
    Array.isArray((error as any).response?.data?.details)
  );
}
```

## Composable Pattern

```typescript
export function useApiError() {
  const fieldErrors = ref<Record<string, string>>({});
  const globalError = ref<string | null>(null);

  function handleError(error: unknown, t: (key: string) => string) {
    fieldErrors.value = {};
    globalError.value = null;

    if (!isApiError(error)) {
      globalError.value = t('errors.unexpected');
      console.error('[API] Unknown error', error);
      return;
    }

    const { type, traceId, details } = error.response.data;
    console.error('[API] Error', { type, traceId });

    for (const detail of details) {
      const i18nKey = `errors.${detail.code}`;
      const message = t(i18nKey) !== i18nKey ? t(i18nKey) : detail.message;

      if (detail.field) {
        fieldErrors.value[detail.field] = message;
      } else {
        globalError.value = message;
      }
    }

    // Fall back to type-level message if no detail produced a global error
    if (!globalError.value && !Object.keys(fieldErrors.value).length) {
      globalError.value = t(`errors.${type}`) ?? t('errors.unexpected');
    }
  }

  function clear() {
    fieldErrors.value = {};
    globalError.value = null;
  }

  return { fieldErrors, globalError, handleError, clear };
}
```

## i18n Key Convention

Derive keys from `detail.code` first, fall back to `type`:

```
errors.FIELD_REQUIRED       → "This field is required"
errors.INVALID_FORMAT       → "Please enter a valid format"
errors.INVALID_REQUEST      → "Your request could not be processed"
errors.NOT_FOUND            → "The requested resource was not found"
errors.unexpected           → "An unexpected error occurred"
```

Keep translations in `lang/en_US/errors.json`. If a key is missing, the raw `detail.message` from the API is used as fallback — acceptable for now, but add the i18n key before shipping.

## Displaying Field Errors

Link field errors to their inputs using `aria-describedby` (see `accessibility-standards.md`):

```vue
<p-input
  v-model="form.email"
  :label="t('fields.email')"
  :error="fieldErrors.email"
/>
<p v-if="fieldErrors.email" role="alert">{{ fieldErrors.email }}</p>
```

## Logging TraceId

Always log `traceId` when available — it is the link between a frontend error and the backend trace in Honeycomb:

```typescript
console.error('[Payment] Submit failed', { traceId, type });
```

Include `traceId` in any support-facing error messages or toast descriptions where appropriate.

## Rules

- Never display raw API `message` strings directly without checking for an i18n key first
- Always log `traceId` — never discard it
- Field-level errors must be displayed next to the relevant input, not only in a toast
- Global errors (no `field`) may use a toast, but also set `globalError` so the component can react
- Call `clear()` before each new submission to remove stale errors
