---
description: Vue 3 coding standards for MFE projects
globs: ["**/*.vue", "**/*.ts"]
alwaysApply: true
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

## Platform shell sidebar menus (platform-mfe)

Partner and persona menus in **platform-mfe** are built with `createMenuItem` from `@/composables/sidebar/useMenuHelpers` and filtered by `processMenuItems`, which evaluates each item’s `visible` rules via `useVisibility`.

### LaunchDarkly and `visible` rules

- Express feature flags on **`MenuItem.visible`** (`VisibilityRules`). Do **not** rely only on a top-level `useFlag(...).value` to conditionally splice items (e.g. avoid `...(flagOn ? [createMenuItem(...)] : [])`). That hides the flag from the menu config, is inconsistent with other rows, and is harder to assert in tests.
- **Default for “flag must be on”:** `visible: { flags: ['namespace.flag.key'] }`. Multiple entries in `flags` are all required. Evaluation uses `VisibilityContext.useFlag` inside `useVisibility` (same underlying feature-flag service as elsewhere).
- **Combine** `flags` with `features`, `userTypes`, `custom`, `or`, `and`, etc. on the **same** rule object when those conditions must all hold together, declared **inline on that `createMenuItem`** (duplicate the same `features`/`custom` block on another row if both need it—avoid extracting shared `VisibilityRules` into a `const` in the composable unless the team explicitly agrees).
- **When logic is inverted or non-trivial:** `visible.custom: (ctx) => !ctx.useFlag('namespace.other.flag', false)` (see the Subscriptions → Trials item in `usePartnerMenuNew`).

### Where to look

- `platform-mfe/src/composables/sidebar/types.ts` — `VisibilityRules`, `VisibilityContext`
- `platform-mfe/src/composables/sidebar/useVisibility.ts` — rule evaluation
- `platform-mfe/src/composables/sidebar/useMenuHelpers.ts` — `createMenuItem`, `processMenuItems`
- `platform-mfe/src/composables/sidebar/menus/usePartnerMenuNew.ts` — examples: Voyager and Integrations “Guides” (`visible.flags`), Data exports (shared billing visibility + `flags`), Trials (`visible.custom` + `ctx.useFlag`)

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
