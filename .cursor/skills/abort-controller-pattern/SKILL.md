---
name: abort-controller-pattern
description: Apply AbortController to async API calls that can be re-invoked before the previous call completes. Use when adding fetch/axios calls, writing composables that call APIs, creating watchers that trigger searches, or fixing race conditions where stale responses overwrite newer state.
---

# Abort Controller Pattern for API Calls

## When to Apply

Any async function that calls an API **and** can be invoked again before the previous call settles must use an
`AbortController`. Common scenarios:

- Search functions triggered by reactive watchers
- Facet/filter loaders triggered by user interaction
- Paginated data fetches where params can change mid-flight
- Any function called from a watcher on reactive query params

## Pattern

```typescript
let abortController: AbortController | undefined;

const fetchData = async () => {
  abortController?.abort();
  abortController = new AbortController();
  const signal = abortController.signal;

  loading.value = true;
  try {
    const response = await apiCall(params, signal);
    if (signal.aborted) return;
    data.value = response;
  } catch (error) {
    if (signal.aborted) return;
    handleError(error);
  } finally {
    if (!signal.aborted) {
      loading.value = false;
    }
  }
};
```

## Rules

1. **Abort before creating** — always call `abortController?.abort()` before `new AbortController()`.
2. **Capture the signal** — store `abortController.signal` in a local const (`signal` or `currentSignal`) at the start.
   Never read `abortController.signal` after the `await`; the outer variable may have been reassigned by a newer call.
3. **Pass signal to the API** — pass the signal to `axios`, `fetch`, or any service that accepts `AbortSignal`.
4. **Guard state writes** — after the `await`, check `if (signal.aborted) return` before writing to reactive state. This
   prevents stale responses from overwriting cleared or newer state.
5. **Catch** — aborted requests throw check `if (signal.aborted) return`. Return silently; do not show error toasts for
   cancellations.
6. **Guard `finally`** — only reset loading state when `!signal.aborted`. If aborted, the newer call owns the loading
   state.
7. **Abort on invalidation** — when a watcher or cleanup path clears data (e.g. search criteria become invalid), abort
   the controller _before_ clearing state to prevent the in-flight response from overwriting the cleared values.

```typescript
// Example: watcher that clears state when criteria become invalid
watch(params, () => {
  if (!isValid.value) {
    abortController?.abort();
    data.value = undefined;
    loading.value = false;
    return;
  }
  fetchData();
});
```

## Checklist

Before considering an API-calling function complete, verify:

- [ ] `AbortController` declared in the enclosing scope (not inside the function)
- [ ] Previous controller aborted at function entry
- [ ] Signal passed to the API call
- [ ] Post-await guard: `if (signal.aborted) return`
- [ ] Throws catch checks `if (signal.aborted) return` and silenced
- [ ] `finally` block guarded with `!signal.aborted`
- [ ] Any watcher/cleanup that invalidates state also calls `abort()`
