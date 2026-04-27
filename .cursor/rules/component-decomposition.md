---
description: Vue component size limits and decomposition patterns — when and how to split large components
globs: ["**/*.vue"]
alwaysApply: false
type: "auto"
---

# Component Decomposition

## Size Limit

**250 lines** per `.vue` file (script + template combined). Components beyond this threshold become harder to test, review, and reuse.

Exceptions: pure layout wrappers and router-level page shells that contain only slot or router-view structure.

## When to Extract

| Signals | Extract to |
|---|---|
| Modal or drawer content with its own state | `{Name}Modal.vue` / `{Name}Drawer.vue` |
| A form with more than 3 fields | `{Name}Form.vue` |
| A table with custom row/cell logic | `{Name}TableRow.vue` or `{Name}Cell.vue` |
| A section with its own loading/error state | dedicated feature component |
| Logic duplicated across siblings | composable `use{Feature}.ts` |

## Composables Own State, Components Own Template

Keep business logic and async state in composables. Components should primarily be wiring:

```typescript
// BAD — composable concerns in the component script
const loading = ref(false);
const results = ref([]);
async function search() {
  loading.value = true;
  results.value = await api.search(query.value);
  loading.value = false;
}

// GOOD — delegate to composable
const { results, isLoading, search } = useSearch();
```

## Modals and Drawers

Do not define modal content inline in the parent component. Each modal is its own component:

```
components/
  payments/
    PaymentsPay.vue            ← orchestrator, stays small
    AddCreditCardModal.vue     ← extracted modal
    ACHPaymentForm.vue         ← extracted form
```

## Splitting Props

When a component's props list exceeds ~6 items, consider whether the component is doing too much. Separate concerns into child components rather than adding more props.

## Checklist Before Committing a Component

- [ ] File is under 250 lines
- [ ] No inline modal/drawer content
- [ ] Async state (loading, error, data) lives in a composable
- [ ] Props list is ≤ 6 items (or the component has a single clear responsibility)
- [ ] The component can be tested without requiring its parent's context
