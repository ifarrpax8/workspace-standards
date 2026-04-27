---
name: loading-state-patterns
description: Consistent loading state naming, skeleton vs spinner decision, and error state display patterns for Vue composables
---

# Loading State Patterns

## Standard Naming

Use these names consistently across all composables and components:

| Ref | Use for |
|---|---|
| `isLoading` | Initial or background data fetch — page or section not yet populated |
| `isSubmitting` | Form or action submission in progress — user triggered |
| `isPending` | Any other in-flight async operation |
| `isRefreshing` | Background refresh of already-loaded data |

**Avoid:** `loading`, `paymentsLoading`, `balanceIsLoading`, `fetchingData` — these diverge from the standard and make composable APIs inconsistent.

## Composable Shape

```typescript
export function useInvoices() {
  const invoices = ref<Invoice[]>([]);
  const isLoading = ref(false);
  const error = ref<string | null>(null);

  async function fetch() {
    isLoading.value = true;
    error.value = null;
    try {
      invoices.value = await invoiceService.getAll();
    } catch (err) {
      error.value = t('errors.unexpected');
    } finally {
      isLoading.value = false;
    }
  }

  return { invoices, isLoading, error, fetch };
}
```

Always expose `isLoading` and `error` — never hide async state inside the composable.

## Skeleton vs Spinner

| Situation | Use |
|---|---|
| First load of a page or section (no data yet) | **Skeleton** — preserves layout, reduces perceived load time |
| Refresh of already-visible data | **Spinner overlay** on the existing content |
| Button action (submit, delete) | **Inline spinner** in/on the button; disable the button |
| Background sync (polling, websocket) | No indicator unless it affects visible data |

```vue
<!-- First load -->
<template v-if="isLoading">
  <TableFullRowSkeleton v-for="n in 5" :key="n" />
</template>
<template v-else>
  <DataTable :rows="invoices" />
</template>

<!-- Button action -->
<p-button :loading="isSubmitting" :disabled="isSubmitting" @click="submit">
  {{ t('actions.save') }}
</p-button>
```

## Error State Display

Every async operation must have a visible error state — never fail silently.

| Error type | Display pattern |
|---|---|
| Page/section load failure | Inline error message with retry option |
| Form field validation (API) | Field-level error (see `error-response-parsing` skill) |
| Action failure (submit, delete) | Toast for transient feedback + inline message for persistence |
| Background sync failure | Non-blocking indicator; don't interrupt the user |

```vue
<div v-if="error" role="alert">
  <p>{{ error }}</p>
  <p-button variant="text" @click="fetch">{{ t('actions.retry') }}</p-button>
</div>
```

## State Machine

Think of async state as a simple machine — avoid impossible combinations:

```
idle → loading → success
               ↘ error → idle (on retry)
```

Never show both `isLoading` and `error` at the same time. Reset `error` to `null` when starting a new fetch.

## Multiple Concurrent Operations

When a component has multiple independent async operations, give each its own `isLoading` and `error`:

```typescript
// GOOD — independent states
const { isLoading: isLoadingInvoices, error: invoiceError } = useInvoices();
const { isLoading: isLoadingPartners, error: partnerError } = usePartners();

// BAD — single loading ref obscures which operation is in progress
const isLoading = ref(false);
```
