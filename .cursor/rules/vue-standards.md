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

## Testing

Use Vitest with Testing Library:

```typescript
import { render, screen, fireEvent } from '@testing-library/vue'
import { describe, it, expect, vi } from 'vitest'
import MyComponent from './MyComponent.vue'

describe('MyComponent', () => {
  it('should render title', () => {
    render(MyComponent, { props: { title: 'Test' } })
    expect(screen.getByText('Test')).toBeInTheDocument()
  })

  it('should emit on click', async () => {
    const { emitted } = render(MyComponent)
    await fireEvent.click(screen.getByRole('button'))
    expect(emitted('submit')).toBeTruthy()
  })
})
```

## Avoid

- `any` type (use proper types or `unknown`)
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
