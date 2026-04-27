---
name: async-component-error-handling
description: defineAsyncComponent error handling for cross-MFE exposed components — fallback UI, retry, timeout, and error logging per ADR 00054
---

# Async Component Error Handling

Per ADR 00054, cross-MFE components are consumed via `defineAsyncComponent`. The ADR specifies the pattern but doesn't prescribe error handling quality. A bare `h("div", "Error loading component")` is not acceptable in production.

## Minimum Required Pattern

```typescript
import { defineAsyncComponent, h } from 'vue';

const RemoteInvoiceWidget = defineAsyncComponent({
  loader: () => import('finance-mfe/components/InvoiceWidget'),

  loadingComponent: InlineSpinner,     // shown while the remote chunk loads

  errorComponent: AsyncErrorFallback,  // shown if the load fails

  delay: 200,        // ms before showing loadingComponent (avoids flash)
  timeout: 10_000,   // ms before treating as failure and showing errorComponent
});
```

## Error Fallback Component

Create a reusable fallback — not an inline `h()` call:

```vue
<!-- AsyncErrorFallback.vue -->
<script setup lang="ts">
defineProps<{ error?: Error }>();
</script>

<template>
  <div role="alert" class="async-error">
    <p>{{ t('errors.component_load_failed') }}</p>
  </div>
</template>
```

The `error` prop is passed automatically by Vue when the loader rejects.

## Retry Logic

Vue's `defineAsyncComponent` does not retry automatically. Wrap the loader to add retry:

```typescript
function withRetry(loader: () => Promise<unknown>, attempts = 3) {
  return () =>
    loader().catch(async err => {
      if (attempts <= 1) throw err;
      await new Promise(r => setTimeout(r, 1000));
      return withRetry(loader, attempts - 1)();
    });
}

const RemoteWidget = defineAsyncComponent({
  loader: withRetry(() => import('finance-mfe/components/Widget')),
  errorComponent: AsyncErrorFallback,
  timeout: 15_000,
});
```

Use retry for network-sensitive environments; don't retry for code errors (they won't recover).

## Logging Load Failures

The error fallback component receives the `error` prop — log it with context:

```vue
<script setup lang="ts">
const props = defineProps<{ error?: Error }>();

onMounted(() => {
  if (props.error) {
    console.error('[AsyncComponent] Load failed', {
      component: 'finance-mfe/InvoiceWidget',
      error: props.error.message,
    });
  }
});
</script>
```

## i18n in Exposed Components

Per ADR 00054, exposed components cannot rely on the consuming app's i18n instance. The exposing MFE must pass a translation hook or the exposed component must import its own i18n:

```typescript
// In the exposed component
import { useI18n } from '../i18n/setup'; // exposing MFE's own i18n
const { t } = useI18n();
```

Do not call `useI18n()` from `vue-i18n` directly — it will try to use the consuming app's instance, which may not have the exposing MFE's translations.

## Checklist

- [ ] `loadingComponent` provided — no content flash during load
- [ ] `errorComponent` is a real component, not an inline `h()` call
- [ ] `timeout` set (10–15 seconds is reasonable)
- [ ] Load failures are logged with component identity
- [ ] Retry attempted for network-sensitive loaders
- [ ] i18n sourced from exposing MFE, not consuming app
