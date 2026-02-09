# Golden Path: Vue 3 MFE (Feature-Based Architecture)

Standard architecture for Vue 3 Micro-Frontend applications using Composition API, TypeScript, and Module Federation.

**Use when:** Building frontend features for the Pax8 MFE platform.

**Reference implementations:** finance-mfe, order-management-mfe

---

## Package Structure

```
src/
├── assets/                    # Static assets (images, global CSS)
├── bootstrap.ts               # MFE bootstrap configuration
├── components/                # UI components (feature-grouped)
│   ├── {feature}/             # Feature-specific components
│   │   ├── {Component}.vue
│   │   ├── {Component}.test.ts
│   │   └── index.ts           # Barrel export
│   ├── common/                # Shared components
│   ├── forms/                 # Form components
│   └── modals/                # Modal components
├── composables/               # Vue Composition API hooks
│   ├── {feature}/
│   │   └── use{Feature}.ts
│   └── use{Utility}.ts        # Standalone composables
├── directives/                # Custom Vue directives
├── expose/                    # Components exposed to other MFEs
│   └── {ExposedComponent}/
│       ├── index.ts
│       └── {Component}.vue
├── helpers/                   # Pure utility functions
├── interfaces/                # TypeScript types (domain-grouped)
│   └── {domain}/
│       └── {Type}.ts
├── lang/                      # i18n translations
│   └── en_US/
│       ├── index.js
│       └── {feature}.json
├── plugins/                   # Vue plugins
├── router/                    # Vue Router configuration
│   ├── index.ts
│   └── routes/
├── services/                  # API service layer
│   └── {Feature}Service/
│       ├── {Feature}Service.ts
│       ├── types.ts
│       └── index.ts
├── store/                     # Pinia stores
│   └── {feature}Store.ts
├── views/                     # Page-level components
│   └── {Feature}Page.vue
└── main.ts                    # Application entry point
```

---

## Component Patterns

### Feature Component

```vue
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useFXRateService } from '@/services/FXRateService'
import { useI18n } from 'vue-i18n'
import type { FXRate } from '@/interfaces/fxrate/FXTypes'

const props = defineProps<{
  baseCurrency: string
  quoteCurrency: string
}>()

const emit = defineEmits<{
  (e: 'rate-selected', rate: FXRate): void
}>()

const { t } = useI18n()
const fxRateService = useFXRateService()

const loading = ref(false)
const rates = ref<FXRate[]>([])
const error = ref<string | null>(null)

const filteredRates = computed(() =>
  rates.value.filter(r => r.baseCurrency === props.baseCurrency)
)

async function loadRates() {
  loading.value = true
  error.value = null
  try {
    rates.value = await fxRateService.getRates(props.baseCurrency, props.quoteCurrency)
  } catch (e) {
    error.value = t('errors.loadFailed')
  } finally {
    loading.value = false
  }
}

function selectRate(rate: FXRate) {
  emit('rate-selected', rate)
}

onMounted(loadRates)
</script>

<template>
  <div class="fx-rate-selector">
    <div v-if="loading" class="loading">{{ t('common.loading') }}</div>
    <div v-else-if="error" class="error">{{ error }}</div>
    <ul v-else>
      <li
        v-for="rate in filteredRates"
        :key="rate.id"
        @click="selectRate(rate)"
      >
        {{ rate.baseCurrency }}/{{ rate.quoteCurrency }}: {{ rate.rate }}
      </li>
    </ul>
  </div>
</template>

<style scoped>
.fx-rate-selector {
  @apply p-4 border rounded;
}
</style>
```

**Rules:**
- Use `<script setup>` with TypeScript
- Define props and emits with type annotations
- Use composables for reusable logic
- Keep components focused (single responsibility)
- Use i18n for all user-facing text

### Barrel Exports (index.ts)

```typescript
export { default as FXRateSelector } from './FXRateSelector.vue'
export { useFXRateSelector } from './useFXRateSelector'
export type { FXRateSelectorProps } from './types'
```

---

## Composables

### Feature Composable

```typescript
import { ref, computed, type Ref } from 'vue'
import type { FXRate } from '@/interfaces/fxrate/FXTypes'

export function useFXRates(baseCurrency: Ref<string>) {
  const rates = ref<FXRate[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  const sortedRates = computed(() =>
    [...rates.value].sort((a, b) => a.rate - b.rate)
  )

  async function fetchRates() {
    loading.value = true
    error.value = null
    try {
      const response = await fetch(`/api/rates/${baseCurrency.value}`)
      rates.value = await response.json()
    } catch (e) {
      error.value = 'Failed to fetch rates'
    } finally {
      loading.value = false
    }
  }

  function clearRates() {
    rates.value = []
  }

  return {
    rates,
    sortedRates,
    loading,
    error,
    fetchRates,
    clearRates
  }
}
```

**Naming:** `use{Feature}` (e.g., useFXRates, useInvoiceTable, usePermissions)

**Rules:**
- Return reactive refs and computed properties
- Include loading and error states
- Expose actions as functions
- Accept reactive inputs (Ref) for reactivity

### Utility Composable

```typescript
import { ref, onMounted, onUnmounted } from 'vue'

export function useViewportHeight() {
  const height = ref(window.innerHeight)

  function updateHeight() {
    height.value = window.innerHeight
  }

  onMounted(() => window.addEventListener('resize', updateHeight))
  onUnmounted(() => window.removeEventListener('resize', updateHeight))

  return { height }
}
```

---

## Services

### Service Pattern

```typescript
import axios, { type AxiosInstance } from 'axios'
import type { FXRate, CreateRateRequest } from './types'

export class FXRateService {
  private client: AxiosInstance

  constructor(baseURL: string) {
    this.client = axios.create({ baseURL })
  }

  async getRates(baseCurrency: string, quoteCurrency: string): Promise<FXRate[]> {
    const response = await this.client.get<FXRate[]>('/rates', {
      params: { baseCurrency, quoteCurrency }
    })
    return response.data
  }

  async createRate(request: CreateRateRequest): Promise<FXRate> {
    const response = await this.client.post<FXRate>('/rates', request)
    return response.data
  }
}

let instance: FXRateService | null = null

export function useFXRateService(): FXRateService {
  if (!instance) {
    instance = new FXRateService(import.meta.env.VITE_API_URL)
  }
  return instance
}
```

### Service Types (types.ts)

```typescript
export interface FXRate {
  id: string
  baseCurrency: string
  quoteCurrency: string
  rate: number
  effectiveDate: string
}

export interface CreateRateRequest {
  baseCurrency: string
  quoteCurrency: string
  rate: number
}
```

**Rules:**
- Class-based services for complex logic
- Export a `use{Service}` function for dependency injection
- Keep types in a separate `types.ts` file
- Use axios or fetch consistently

---

## Pinia Stores

```typescript
import { defineStore } from 'pinia'
import { useFXRateService } from '@/services/FXRateService'
import type { FXRate } from '@/interfaces/fxrate/FXTypes'

export const useFXRateStore = defineStore('fxRate', {
  state: () => ({
    rates: [] as FXRate[],
    selectedRate: null as FXRate | null,
    loading: false,
    error: null as string | null
  }),

  getters: {
    ratesByBase: (state) => (baseCurrency: string) =>
      state.rates.filter(r => r.baseCurrency === baseCurrency),

    hasRates: (state) => state.rates.length > 0
  },

  actions: {
    async fetchRates(baseCurrency: string) {
      this.loading = true
      this.error = null
      try {
        const service = useFXRateService()
        this.rates = await service.getRates(baseCurrency, '')
      } catch (e) {
        this.error = 'Failed to fetch rates'
      } finally {
        this.loading = false
      }
    },

    selectRate(rate: FXRate) {
      this.selectedRate = rate
    },

    clearSelection() {
      this.selectedRate = null
    }
  }
})
```

**Naming:** `use{Feature}Store` (e.g., useFXRateStore, useInvoiceStore)

**When to use stores:**
- Shared state across multiple components
- State that persists across route navigation
- Complex state with many actions

**When to use composables instead:**
- Component-local state
- Simple reactive state
- No need for persistence

---

## TypeScript Interfaces

### Domain Types

```typescript
export interface Invoice {
  id: string
  partnerId: string
  companyId: string
  status: InvoiceStatus
  lineItems: LineItem[]
  total: Money
  dueDate: string
  createdAt: string
}

export type InvoiceStatus = 'DRAFT' | 'SENT' | 'PAID' | 'CANCELLED'

export interface LineItem {
  description: string
  quantity: number
  unitPrice: Money
}

export interface Money {
  amount: number
  currency: string
}
```

**Rules:**
- Group by domain in `interfaces/{domain}/`
- Use type aliases for unions
- Export from index.ts for barrel exports

---

## Testing

### Component Test (Vitest + Testing Library)

```typescript
import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/vue'
import FXRateSelector from './FXRateSelector.vue'
import { useFXRateService } from '@/services/FXRateService'

vi.mock('@/services/FXRateService')

describe('FXRateSelector', () => {
  it('renders rates when loaded', async () => {
    const mockRates = [
      { id: '1', baseCurrency: 'USD', quoteCurrency: 'EUR', rate: 0.85 }
    ]
    vi.mocked(useFXRateService).mockReturnValue({
      getRates: vi.fn().mockResolvedValue(mockRates)
    } as any)

    render(FXRateSelector, {
      props: { baseCurrency: 'USD', quoteCurrency: 'EUR' }
    })

    expect(await screen.findByText('USD/EUR: 0.85')).toBeInTheDocument()
  })

  it('emits rate-selected on click', async () => {
    const mockRates = [
      { id: '1', baseCurrency: 'USD', quoteCurrency: 'EUR', rate: 0.85 }
    ]
    vi.mocked(useFXRateService).mockReturnValue({
      getRates: vi.fn().mockResolvedValue(mockRates)
    } as any)

    const { emitted } = render(FXRateSelector, {
      props: { baseCurrency: 'USD', quoteCurrency: 'EUR' }
    })

    const rateItem = await screen.findByText('USD/EUR: 0.85')
    await fireEvent.click(rateItem)

    expect(emitted('rate-selected')).toBeTruthy()
    expect(emitted('rate-selected')[0]).toEqual([mockRates[0]])
  })
})
```

### Composable Test

```typescript
import { describe, it, expect, vi } from 'vitest'
import { ref } from 'vue'
import { useFXRates } from './useFXRates'

describe('useFXRates', () => {
  it('fetches rates for base currency', async () => {
    global.fetch = vi.fn().mockResolvedValue({
      json: () => Promise.resolve([{ rate: 0.85 }])
    })

    const baseCurrency = ref('USD')
    const { rates, fetchRates } = useFXRates(baseCurrency)

    await fetchRates()

    expect(rates.value).toHaveLength(1)
    expect(rates.value[0].rate).toBe(0.85)
  })
})
```

---

## i18n

### Translation File (lang/en_US/fxrate.json)

```json
{
  "title": "Exchange Rates",
  "selectRate": "Select Rate",
  "noRatesFound": "No rates found for {baseCurrency}/{quoteCurrency}",
  "errors": {
    "loadFailed": "Failed to load exchange rates"
  }
}
```

### Usage

```typescript
import { useI18n } from 'vue-i18n'

const { t } = useI18n()

const message = t('fxrate.noRatesFound', { 
  baseCurrency: 'USD', 
  quoteCurrency: 'EUR' 
})
```

---

## Checklist

Before completing a feature, verify:

- [ ] Components use `<script setup>` with TypeScript
- [ ] Props and emits are typed
- [ ] All user-facing text uses i18n
- [ ] Services are injected via `use{Service}` functions
- [ ] Tests exist for components and composables
- [ ] Barrel exports (index.ts) for feature folders
- [ ] No hardcoded API URLs (use environment variables)
- [ ] Loading and error states handled
- [ ] Tailwind CSS used (no custom CSS unless necessary)
