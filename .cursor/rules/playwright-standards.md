---
description: Standards for Playwright integration testing — page objects, selectors, fixtures, waiting, naming
globs: ["**/tests/**/*.ts", "**/pages/**/*.ts", "**/fixtures/**/*.ts", "playwright.config.*"]
alwaysApply: false
type: "auto"
---

# Playwright Standards

Follow these standards when writing Playwright integration tests.

## Page Object Model

- All page interactions encapsulated in page classes
- Define locators as `readonly` properties in page objects
- Keep assertions in tests, not in page objects

## Selectors

Priority order:
1. `data-test-id` — `page.locator('[data-test-id="submit-order"]')`
2. IDs — `page.locator('#username')`
3. Accessibility roles — `page.getByRole('button', { name: 'Login' })`
4. Labels — `page.getByLabel('Username')`
5. Text — `page.getByText('Welcome back')`
6. CSS selectors — last resort only

## Fixtures

- Use Playwright fixtures for setup/teardown
- Use storage state for authentication (don't log in per test)
- Create page fixtures for browser interactions; service fixtures for API operations
- **Access page objects via the `pages` fixture, never instantiate directly in tests.** The `Pages` class aggregates all page objects; destructure what you need:
  ```typescript
  test('example', async ({ pages }) => {
    const { page, invoiceReportPage, reportCenterPage } = pages;
  ```
  Do not `import` page object classes into spec files or call `new SomePage(page)` in tests. Register new page objects in `Pages` and access via the fixture.

## Waiting

- No hardcoded timeouts (`page.waitForTimeout`)
- Use `waitForResponse`, `waitForURL`, or locator auto-waiting
- Page load: use `domcontentloaded` + explicit element wait (not `networkidle` — MFE shell keeps persistent connections)

## Test Independence

- Each test must be runnable in isolation
- No shared mutable state between tests

## Naming

- Test files: `{feature}.spec.ts`
- Page objects: `{Page}Page.ts`

## Test Structure

- Arrange-Act-Assert pattern in tests
- Given-When-Then structure for readability

## Propulsion Components

For `@pax8/propulsion`-specific test patterns (PTable, PDrawer, PCheckbox, PDropdown, PModal, PSearchInput), use the **`/propulsion-patterns`** skill — these components have non-obvious quirks that aren't covered by standard Playwright guidance.

## Golden Path

Reference: `@workspace-standards/golden-paths/integration-testing.md`
