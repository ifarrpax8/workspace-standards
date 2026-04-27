---
description: Vue 3 coding standards for MFE projects
globs: ["**/*.vue", "**/*.ts"]
alwaysApply: true
type: "always"
---

# Vue MFE Standards

Follow these standards when writing Vue 3 code.

## Component Structure

Always use Composition API with `<script setup>`:

```vue
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'

const props = defineProps<{
  itemId: string
  initialValue?: number
}>()

const emit = defineEmits<{
  (e: 'update', value: number): void
  (e: 'delete'): void
}>()

const { t } = useI18n()
const loading = ref(false)
const data = ref<ItemType | null>(null)

const displayValue = computed(() => data.value?.name ?? t('common.unknown'))

async function handleSubmit() {
  // implementation
}

onMounted(() => {
  // initialization
})
</script>

<template>
  <!-- template -->
</template>

<style scoped>
/* styles */
</style>
```

## File Organization

Organise components by feature, not by type.

```
components/
  {Feature}/
    {Component}.vue
    {Component}.test.ts
    use{Feature}.ts       # Composable if needed
    types.ts              # Feature-specific types
    index.ts              # Barrel export
```

## Naming Conventions

- Files and folders: camelCase
- Routes: kebab-case
- Components: PascalCase (`FXRateSelector.vue`)
- Composables: `use{Feature}` (`useFXRates.ts`)
- Services: `{Feature}Service` (`FXRateService.ts`)
- Types: PascalCase (`FXRate`, `CreateRateRequest`)
- Test files: `{Component}.test.ts`
- Events in templates: kebab-case (`@update:model-value`, `@on-sort`)
- Events in JavaScript/TypeScript: camelCase (`emit('update:modelValue')`, `$emit('update:modelValue')`)

```vue
<!-- GOOD — kebab-case in templates -->
<p-drawer @update:model-value="onVisibilityChange" />
<p-checkbox @update:model-value="toggleColumn(key)" />
```

```typescript
// GOOD — camelCase in script and tests
const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
}>()

// In tests
await drawer.vm.$emit('update:modelValue', false)
```

## Props and Emits

Always type props and emits:

```typescript
const props = defineProps<{
  required: string
  optional?: number
  withDefault?: boolean
}>()

withDefaults(defineProps<Props>(), {
  withDefault: false
})

const emit = defineEmits<{
  (e: 'change', value: string): void
}>()
```

## Async and Promises

Prefer `async/await` over nested `.then()` chains. Use `Promise.all()` for independent parallel async operations.

Any async function that calls an API **and can be re-invoked before the previous call settles** (search inputs, reactive watchers, filter changes) must use `AbortController` to prevent race conditions and stale state writes. Use the **`/abort-controller-pattern`** skill for the full pattern and checklist.

## Composables

Return reactive state and actions:

```typescript
export function useFeature() {
  const data = ref<Data[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  const filtered = computed(() => /* ... */)

  async function fetch() {
    loading.value = true
    try {
      data.value = await api.get()
    } catch (e) {
      error.value = 'Failed to load'
    } finally {
      loading.value = false
    }
  }

  return { data, loading, error, filtered, fetch }
}
```

## Services

Use object destructuring when service calls need more than 3 parameters.

Class-based services with factory function:

```typescript
export class FeatureService {
  constructor(private baseUrl: string) {}

  async getItems(): Promise<Item[]> {
    const response = await axios.get(`${this.baseUrl}/items`)
    return response.data
  }
}

let instance: FeatureService | null = null

export function useFeatureService(): FeatureService {
  if (!instance) {
    instance = new FeatureService(import.meta.env.VITE_API_URL)
  }
  return instance
}
```

## i18n

Use i18n for all user-facing text:

```vue
<script setup lang="ts">
const { t } = useI18n()
</script>

<template>
  <button>{{ t('actions.save') }}</button>
  <p>{{ t('messages.welcome', { name: userName }) }}</p>
</template>
```

### i18n Discipline

- Check `common.json` (or the equivalent shared file) before creating new translation keys — duplicates have a real cost
- Use sentence case for labels unless design explicitly specifies otherwise
- Wrap i18n-dependent values in `computed()` so locale changes take effect without a page refresh:

```typescript
// BAD — static array won't react to locale change
const breadcrumbs: BreadcrumbItem[] = [
  { label: t('nav.home'), to: '/' },
]

// GOOD — recomputes when locale changes
const breadcrumbs = computed<BreadcrumbItem[]>(() => [
  { label: t('nav.home'), to: '/' },
])
```

- Error messages displayed to users must also go through i18n

## Propulsion and PTable

Pax8 MFEs use `@pax8/propulsion`. For **`PTable`** (and similar design-system data tables), **cells and headers often use flex layout**, not only normal flow with `text-align`.

- **`text-align: right` or `end` alone is often ineffective** for numeric or currency columns, because flex alignment along the main axis overrides the usual text-align behaviour.
- **Prefer** `justify-content: flex-end` on the cell content wrapper (or equivalent utility classes), **`align: 'end'`** (or the column API’s alignment option) when defining columns, and scoped `:deep` rules for header chrome (for example `.header__button`) where the component does not expose a header slot.
- **Refinement and implementation**: tickets that say “right-align columns” or “CSS alignment” should assume **possible flex behaviour**—confirm against the table component’s DOM structure instead of relying only on `text-align`.

### PTable: pagination size and header select-all

- **`PTable` exposes `itemsPerPage`**, bound in templates as **`:items-per-page`**. It does **not** use `:page-size` or `:page-size-options`; those attributes are **not** component props and are ignored at runtime.
- If **`itemsPerPage` is omitted**, the table keeps its **default (10)**. The **header checkbox** (select-all / clear visible) toggles selection **only for that many rows** in the table’s internal model, even when more rows are rendered (for example after server-side pagination loads 12 rows while the table still assumes 10).
- **Always bind** `:items-per-page` to the same page size your API and **`p-pagination`** use. Put **per-page dropdown options** on **`p-pagination`** (`per-page-options`), not on `p-table`.
- **Audit**: search the repo for `:page-size` on **`p-table`** — that pattern is a common source of “select all only selects the first 10” bugs.

### PTable: select-all and row `disabled`

- **Per-row** selection checkboxes **honour `item.disabled`** (users cannot tick ineligible rows).
- **Header “select all”** (and the visible-range select-all behaviour tied to that control) **sets `isSelected` on every row in scope**, including rows marked **`disabled: true`**. That is easy to miss because the row UI still looks like a disabled checkbox while internal selection state includes those items.
- **Mitigation for bulk actions**: treat `update:selectedRows` as untrusted for business rules. **Filter** the emitted array (for example `rows.filter((r) => !r.disabled)` or a domain-specific predicate) before calling an API or enabling a primary action.
- **Mitigation for UI sync**: if you correct selection in the parent, the table’s internal row objects can still carry stale `isSelected` until **`items` is replaced**. Derive each row’s **`isSelected`** from your canonical selected set when building **`items`**, or otherwise ensure the `items` reference updates so the table’s watcher reapplies row state.
- **Header checkbox desync**: the header control keeps its own checked / indeterminate state separately from the `items` you pass in. After you filter `update:selectedRows`, change page size, refetch data, or otherwise replace `items`, the **header “select all”** can stay checked or indeterminate even when no rows (or not all rows) are selected. **Remount `PTable` with a changing `:key`** after each successful data load and whenever you correct selection in a way the table did not emit (for example dropping `disabled` rows). That resets internal header state without asking users to click the header twice.
- **Long-term**: the proper fix belongs in **`@pax8/propulsion`** (header select-all should skip `disabled` rows, and header state should track derived selection); until then, assume this behaviour in every MFE that uses row-level `disabled` with bulk selection.

For **Playwright** selectors and assertions on `PTable`, see `playwright-standards.md` (Propulsion Component Patterns → PTable).

## Testing

Use Vitest with Testing Library. See `vue-test-standards.md` for detailed test authoring rules covering component tests, composable tests, utility tests, mocking guidance, and test data patterns.

## Template Consistency

- Use kebab-case for components in templates — match the codebase convention:

```vue
<!-- GOOD -->
<p-button icon="filter" @click="toggle" />
<partner-select v-model="filters.partner" />

<!-- BAD — inconsistent with kebab-case convention -->
<PButton icon="filter" @click="toggle" />
<PartnerSelect v-model="filters.partner" />
```

Some repos or Propulsion examples use **PascalCase** in templates; others standardise on **kebab-case**. Follow **ESLint** and the dominant pattern in the same feature folder. Do not block review on PascalCase vs kebab-case when the project is internally consistent and lint-clean.

## Related Rules and Skills

- **Error handling** — `global-error-handling.md` rule; never swallow errors, always log `traceId`
- **API error parsing** — `/error-response-parsing` skill (ADR 00081 format: `type`, `details[].code`, `traceId`)
- **Loading states** — `/loading-state-patterns` skill; use `isLoading` / `isSubmitting` / `isPending`
- **Feature flags** — `/feature-flag-discipline` skill (ADR 00035); use `useFlag()` from shell, never site settings
- **Cross-MFE components** — `/async-component-error-handling` skill (ADR 00054); always provide `errorComponent` and `timeout`
- **AbortController** — `/abort-controller-pattern` skill; required for any re-invocable async API call
- **Accessibility** — `accessibility-standards.md` rule; WCAG 2.1 AA target
- **Component size** — `component-decomposition.md` rule; 250-line limit
- **Session replay** — `session-replay-masking.md` rule; `data-session-replay-mask` on payment/PII fields (ADR 00085)

## Avoid

- `any` type (use proper types or `unknown`)
- `as` type assertions — use generics or dedicated types instead:

```typescript
// BAD
const items = ref([] as Item[])
const params = route.query as SearchParams

// GOOD
const items = ref<Item[]>([])
const params = computed<SearchParams>(() => ({ ... }))
```

- Reusing a type across unrelated APIs — define separate param types per endpoint
- `onMounted` + `watch` when `watchImmediate` achieves the same result:

```typescript
// BAD — duplicated trigger
onMounted(() => fetchData())
watch(source, () => fetchData())

// GOOD
watchImmediate(source, () => fetchData())
```

- `window.dispatchEvent` for intra-MFE communication — use Vue reactivity; window events are for cross-MFE only
- Nested `.then()` chains (use `async/await`)
- `console.log` statements (remove before committing)
- Importing entire utility libraries (import only needed functions; prefer native ES6 methods)
- Options API (use Composition API)
- `v-html` without DOMPurify sanitization
- Direct DOM manipulation
- Hardcoded API URLs (use env variables)
- State in component that should be in store

## Style

- Use Tailwind CSS classes
- Scoped styles for component-specific CSS
- No inline styles except for dynamic values

## Before Handing Back

Run these scripts in order before reporting work complete. All MFEs share these script names:

```bash
npm run lint:fix          # auto-fix ESLint/import-ordering issues
npm run vitest:ci         # full test suite
npm run check-for-errors  # lint + tsc + prettier + i18n in parallel (the gate)
npm run prettier:w        # auto-fix prettier issues if check-for-errors reports them, then re-run
```

ESLint (import ordering, no-explicit-any) and TSC are compile-time guardrails — the dev server surfaces these immediately as a broken page. Prettier failures also block CI. A clean `check-for-errors` run is the minimum bar for a shippable change.
