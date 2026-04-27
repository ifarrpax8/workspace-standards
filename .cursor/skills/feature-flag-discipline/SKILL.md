---
name: feature-flag-discipline
description: LaunchDarkly feature flag patterns — useFlag composable, flag naming, evaluation in composables vs templates, and flag removal checklist
---

# Feature Flag Discipline

Per ADR 00035, feature flags (not site settings or permissions) control feature releases. The shell exposes `useFlag()` for consuming flags in MFEs.

## Importing useFlag

```typescript
import { useFlag } from '@pax8/p8p-mfe-shell';
```

Do not import LaunchDarkly's SDK directly — always go through the shell's composable.

## Evaluating Flags

### In a Composable

```typescript
export function useNewBillingFlow() {
  const isNewBillingEnabled = useFlag('finance.billing.new-flow', false);

  // isNewBillingEnabled is a Ref<boolean>
  return { isNewBillingEnabled };
}
```

### In a Template (simple show/hide)

```vue
<script setup lang="ts">
const isNewBillingEnabled = useFlag('finance.billing.new-flow', false);
</script>

<template>
  <NewBillingFlow v-if="isNewBillingEnabled" />
  <LegacyBillingFlow v-else />
</template>
```

### In Sidebar / Menu (platform-mfe pattern)

Use `visible.flags` on `createMenuItem` — do not splice items conditionally outside the menu config (see `sidebar-visibility.md` in platform-mfe rules):

```typescript
createMenuItem({
  label: 'New Billing',
  to: '/billing/new',
  visible: { flags: ['finance.billing.new-flow'] },
})
```

## Flag Naming Convention

Format: `{domain}.{feature}.{description}`

```
finance.billing.new-flow
finance.reports.scheduled-exports
orders.subscriptions.bulk-cancel
```

- Use kebab-case within each segment
- Domain matches the MFE or bounded context (`finance`, `orders`, `platform`)
- Keep names intent-revealing — `finance.billing.new-flow` not `finance.flag1`

## Default Values

Always provide a meaningful default — the second argument to `useFlag()`:

```typescript
// BAD — defaults to undefined, may cause type errors
const isEnabled = useFlag('finance.billing.new-flow');

// GOOD
const isEnabled = useFlag('finance.billing.new-flow', false);
```

Default to the **safe/off** state — the flag being unavailable should not enable unreleased features.

## Avoiding Conditional Splicing

```typescript
// BAD — flag hidden from menu config, harder to trace
const flagOn = useFlag('finance.reports.exports', false);
const menuItems = [...(flagOn.value ? [createMenuItem({ label: 'Exports' })] : [])];

// GOOD — flag expressed directly on the item
const menuItems = [
  createMenuItem({ label: 'Exports', visible: { flags: ['finance.reports.exports'] } }),
];
```

## Flag Removal Checklist

When a flag is fully rolled out (100% of users, no rollback risk):

- [ ] Confirm rollout is permanent with product
- [ ] Remove the `useFlag()` call and any `v-if`/`v-else` branching
- [ ] Remove the `visible.flags` entry from menu configs
- [ ] Delete the old/legacy code path that was behind the flag
- [ ] Remove the flag from LaunchDarkly
- [ ] Remove any flag-specific test scaffolding

Flags that are never cleaned up accumulate as dead code and make the codebase harder to reason about. Treat flag removal as part of the same ticket as the full rollout.

## Do Not Use Site Settings or Permissions

ADR 00035 is explicit: site settings and the older permission system must not be used to toggle feature visibility. If you find code doing this, raise it — it's tech debt.
