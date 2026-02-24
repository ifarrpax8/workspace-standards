---
description: Standards for Vue MFE unit and component tests
globs: ["**/*.test.ts", "**/*.test.js"]
alwaysApply: false
---

# Vue Test Standards

Follow these standards when writing Vitest tests in Vue MFE projects.

## Scope

ONLY test code within this repository. NEVER test third-party library behaviour (PrimeVue/Propulsion rendering, vue-router navigation, vue-i18n translation resolution, Pinia internals).

## Component Tests

### What to Test

- **Default render** -- MAXIMUM 1 "renders correctly with default props" test per file. It must assert meaningful content (visible text, key elements), not just `wrapper.exists()`.
- **Prop-driven behaviour** -- test that non-default props affecting behaviour produce the expected UI or state changes.
- **User interactions** -- test that user actions (click, input, select) result in correct state changes, UI updates, or emitted events.
- **Conditional rendering** -- test that subcomponents are shown, hidden, or disabled based on internal dependent state (without duplicating prop-level tests).
- **Error and loading states** -- test that loading indicators and error messages appear under the right conditions.

### What NOT to Test

- That a PrimeVue/Propulsion component renders its own internals correctly.
- That `vue-router` navigates when you call `router.push`.
- That `vue-i18n` resolves translation keys to strings.
- Internal component data or computed properties via `wrapper.vm` -- assert through rendered output or emitted events instead.

### Prefer Testing Library

Use `@testing-library/vue` with `screen` queries and `fireEvent` / `userEvent` for interaction tests. This encourages testing from the user's perspective:

```typescript
import { render, screen, fireEvent } from '@testing-library/vue'

it('should disable submit when form is invalid', async () => {
  render(OrderForm, { props: { orderId: '123' } })
  expect(screen.getByRole('button', { name: /submit/i })).toBeDisabled()
})
```

Fall back to `@vue/test-utils` `mount` / `shallowMount` only when Testing Library cannot express the assertion (e.g. emitted events, provide/inject).

## Composable Tests

- Test that returned refs and computed properties are reactive and respond to dependency changes.
- Test that actions (returned functions) update state correctly.
- Test error and loading state transitions.

### Composable Test Harness

Use `effectScope` to test composables outside a component:

```typescript
import { effectScope } from 'vue'

function renderComposable() {
  const scope = effectScope()
  let result!: ReturnType<typeof useFeature>
  scope.run(() => { result = useFeature() })
  return { result, scope }
}
```

Alternatively, use a minimal wrapper component when the composable depends on lifecycle hooks (`onMounted`, `onUnmounted`).

## Utility Tests

- Test that utility functions return the correct output for a given input.
- Test edge cases: `null`, `undefined`, `NaN`, empty strings, boundary values.
- Use parameterised tests (`it.each`) when testing multiple input/output pairs.

## Mocking

### Mock at Boundaries

Mock **external boundaries** -- services, shell libraries, router, i18n. Avoid mocking internal composables and helpers unless they have side effects or network calls.

```
✅ Mock: API services, @pax8/p8p-mfe-shell, vue-router, vue-i18n
❌ Avoid mocking: local composables, pure helpers, computed properties
```

### Service Mocking

Prefer `vi.mock` at the module level with `vi.hoisted` for shared mock references:

```typescript
const { mockGetRates } = vi.hoisted(() => ({
  mockGetRates: vi.fn().mockResolvedValue([]),
}))

vi.mock('@/services/FXRateService', () => ({
  getRates: mockGetRates,
}))
```

Use MSW (`msw/node`) for tests that exercise the full service layer (HTTP request through to response parsing). MSW is already configured in `vitest.setup` in finance-mfe.

### Pinia Stores

Use a real Pinia instance with mocked services -- do not mock the store itself:

```typescript
beforeEach(() => {
  setActivePinia(createPinia())
  vi.resetAllMocks()
})
```

### Router and i18n

Mock with a passthrough -- keep it minimal:

```typescript
vi.mock('vue-router', () => ({
  useRoute: () => ({ query: {}, params: {} }),
  useRouter: () => ({ push: vi.fn(), replace: vi.fn() }),
  RouterLink: { template: '<a><slot /></a>' },
}))

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: (key: string) => key }),
}))
```

If multiple test files need the same router/i18n mock, centralise it in a shared test utility or the vitest setup file rather than duplicating across files.

### Propulsion / PrimeVue

Use the `__mocks__/@pax8/propulsion.ts` auto-mock (already configured via `vi.mock` in vitest setup). Do not write tests that assert Propulsion component internals.

### Mock Hygiene

- Call `vi.resetAllMocks()` in `beforeEach` to prevent mock state leaking between tests.
- Never pass `vi.fn()` as the second argument to `vi.mock` -- it expects a factory function, not a mock.
- Keep mock setup proportional to test code. If a test file has more mock setup than assertions, consider whether the component is doing too much or whether you're mocking too deep.

## Test Data

Use domain-specific factory functions (e.g. `createMockLineItem`, `createMockInvoice`) from `src/test-utils/` instead of inline object literals. Factories provide sensible defaults so tests only specify fields relevant to the behaviour under test:

```typescript
const item = createMockLineItem({ quantity: 0 })
```

## Naming

- Test files: `{Component}.test.ts`, co-located with the source file.
- Describe blocks: component or composable name.
- Test names: `should [expected behaviour] when [condition]`.

## Structure

Follow Arrange-Act-Assert:

```typescript
it('should show error message when API call fails', async () => {
  // Arrange
  mockGetRates.mockRejectedValueOnce(new Error('Network error'))

  // Act
  render(RateSelector, { props: { currency: 'USD' } })
  await flushPromises()

  // Assert
  expect(screen.getByText('errors.loadFailed')).toBeInTheDocument()
})
```
