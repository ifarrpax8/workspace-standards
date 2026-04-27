---
description: Vue MFE error handling standards — app-level error handler, component error boundaries, unhandled rejections
globs: ["**/*.vue", "**/*.ts", "**/*.tsx"]
alwaysApply: false
type: "auto"
---

# Global Error Handling

Per ADR 00027, frontend observability uses OpenTelemetry + Honeycomb. The shell package provides Vue error handler integration — MFEs must not suppress or swallow errors that should reach it.

## App-Level Error Handler

The shell initialises a global Vue error handler that sends errors to Honeycomb. Do not override `app.config.errorHandler` in MFE code — doing so bypasses observability.

If you need MFE-specific handling, use `onErrorCaptured` in a parent component instead.

## Component Error Boundaries

Use `onErrorCaptured` in layout or page-level components to catch errors from a subtree without crashing the whole MFE:

```typescript
onErrorCaptured((error, instance, info) => {
  // log context for debugging — include traceId if available
  console.error('[ErrorBoundary]', { error, info });
  showErrorState.value = true;
  return false; // prevent propagation to app-level handler if handled here
});
```

Return `false` only if you have displayed a meaningful error UI. Returning `false` and silently hiding the error is not acceptable.

## Unhandled Promise Rejections

Async functions called outside Vue's rendering cycle (e.g. in `setTimeout`, event listeners, or top-level `await`) are not caught by Vue's error handler. Guard these explicitly:

```typescript
// BAD — rejection silently lost
someAsyncFn();

// GOOD
someAsyncFn().catch(error => {
  console.error('Unhandled rejection', error);
});
```

## Error Handling in Composables

- Always `catch` in composables that call APIs — propagate or surface, never swallow
- Expose an `error` ref so the calling component can react
- Log `traceId` from the API error response (see ADR 00081) to aid support

```typescript
const error = ref<string | null>(null);

async function fetchData() {
  try {
    data.value = await api.getData();
  } catch (err) {
    const apiError = err as ApiError;
    error.value = t('errors.generic');
    console.error('[fetchData]', { traceId: apiError?.traceId, err });
  }
}
```

## Rules

- Never catch an error and return nothing — always log, surface, or rethrow
- Never override `app.config.errorHandler` in MFE code
- Always include `traceId` in error logs when available from the API response
- Use `onErrorCaptured` for component subtree boundaries, not try/catch around render logic
- Async functions outside Vue's lifecycle must handle their own rejections explicitly
