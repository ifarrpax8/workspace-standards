---
description: Standards for Playwright integration testing
globs: ["**/tests/**/*.ts", "**/pages/**/*.ts", "**/fixtures/**/*.ts", "playwright.config.*"]
alwaysApply: false
---

# Playwright Standards

Follow these standards when writing Playwright integration tests.

## Page Object Model

- All page interactions encapsulated in page classes
- Define locators as `readonly` properties in page objects
- Keep assertions in tests, not in page objects

## Selectors

- Prefer `data-test-id` selectors over CSS/XPath
- Use getByRole, getByLabelText for accessibility when data-test-id isn't available

## Fixtures

- Use Playwright fixtures for setup/teardown
- Use storage state for authentication (don't log in per test)
- Create page fixtures for browser interactions
- Implement service fixtures for API operations

## Waiting

- No hardcoded timeouts (`page.waitForTimeout`)
- Use `waitForResponse`, `waitForURL`, or locator auto-waiting
- Avoid hardcoded waits — prefer built-in waiting strategies

## Test Independence

- Each test must be runnable in isolation
- No shared mutable state between tests

## Naming

- Test files: `{feature}.spec.ts`
- Page objects: `{Page}Page.ts`

## Test Structure

- Arrange-Act-Assert pattern in tests
- Given-When-Then structure for readability

## Propulsion Component Patterns

Propulsion (`@pax8/propulsion`) is the shared component library across all MFEs. These patterns were discovered through integration testing and apply wherever Propulsion components are used.

### PTable

- The `<table>` element is **always in the DOM**, even when empty. Empty state renders inside the table via a `#empty-state` slot (`PEmptyState`).
- **Do not** assert `toBeVisible()` on the table to prove data loaded -- it will always pass.
- **Do** count data rows with `table.locator('tbody tr')` and assert `count > 0`.
- Column headers include a `Header - ` prefix in their `aria-label` (e.g. `aria-label="Header - Client"`). Strip this when comparing header names.
- Sort buttons use `aria-sort` attribute with values `none`, `ascending`, `descending`. Assert attribute transitions rather than comparing cell text, which is unreliable with complex cell rendering.
- Grouped tables replace the standard column set with group name + count columns. Compare `getColumnHeaders()` before and after grouping to assert the structure changed.

### PDrawer

- The close button rendered by `PDrawer` has **no accessible name and no `data-testid`**. Do not use `getByLabel`, `getByRole('button', { name })`, or `[data-testid="p-drawer-close"]`.
- **Reliable close pattern:** Locate the dialog, find the header section containing the heading, then click the sibling button:
  ```typescript
  const drawer = page.getByRole('dialog');
  const headerSection = drawer.locator('div')
    .filter({ has: page.getByRole('heading', { name: 'Drawer Title' }) })
    .first();
  await headerSection.getByRole('button').click();
  ```
- `Escape` key does **not** close `PDrawer` when `presentation="modal"`.
- The drawer uses `v-if`, so it is fully removed from the DOM when closed. Assert `not.toBeVisible()` on a unique element inside the drawer (e.g. a search input) to confirm closure.

### PCheckbox

- `PCheckbox` renders `<input type="checkbox" id="{columnKey}">` where `id` is the programmatic key (e.g. `productSku`), not the display label (e.g. `SKU`).
- `getByLabel('SKU')` will match **multiple elements** (search inputs, column headers, sort buttons) because the label text appears in many places.
- **Prefer** `page.locator('#productSku')` or scope the checkbox within its container (e.g. `page.getByRole('dialog').getByRole('checkbox', { name: 'SKU' })`).

### PDropdown / Facet Selects

- Facet select triggers use `data-testid="{field}-select-trigger"` and options use `data-testid="{field}-select-option"`.
- Dropdowns render as `listbox` role elements. After selecting an option, close the dropdown explicitly:
  ```typescript
  await page.keyboard.press('Escape');
  await page.getByRole('listbox').waitFor({ state: 'hidden', timeout: 5000 }).catch(() => {});
  ```
- Facet badges may include counts (e.g. `Partner 5`). Do not rely on badge counts for assertions as they may be removed.

### PModal / PDialog

- Propulsion modals render as `dialog` role elements. Use `page.getByRole('dialog')` to locate them.
- Radio groups inside modals use standard `radio` role. Use `modal.getByRole('radio', { name: 'Option' })` rather than `page.getByText('Option')`, which may match labels outside the modal.
- Modals with a default selection (e.g. "None" checked) will not trigger validation when saved. Verify the default state with `toBeChecked()` before testing interactions.
- Cancel buttons reliably close modals. Assert `not.toBeVisible()` on the dialog after clicking Cancel.

### PSearchInput

- `PSearchInput` renders a `searchbox` role element with a clear button.
- The search input inside `ManageColumnsDrawer` only filters the **Available columns** section. Selected columns remain visible regardless of the search term.
- When counting filtered results, count unchecked checkboxes (`getByRole('checkbox', { checked: false })`) before and after typing. Counting all checkboxes will include the unaffected selected columns.
- The filter removes non-matching items from the DOM entirely (`v-for` over a computed list), not via CSS. Allow a brief wait (`waitForTimeout(500-1000)`) for Vue reactivity before counting.

### PTable -- Pagination and Scoping

- When a page contains multiple tables (e.g. a saved reports table and a debug panel), scope the table locator to its parent view container to avoid strict mode violations:
  ```typescript
  this.savedReportsTable = this.reportCenterView.getByRole('table');
  ```
- Paginated tables default to 10 rows per page. Tests that create data and then look for it must sort by a relevant column (e.g. "Modified" descending) to ensure the new item appears on page 1:
  ```typescript
  async sortByModifiedDescending() {
    const sortButton = this.table.getByRole('button', { name: 'Sort by Modified' });
    await sortButton.click();
    const ariaSort = await sortButton.getAttribute('aria-sort');
    if (ariaSort !== 'descending') {
      await sortButton.click();
    }
  }
  ```

### PEmptyState

- `PEmptyState` renders a heading and subtitle inside the table's `#empty-state` slot. It is visible even though the table itself is always in the DOM.
- To verify a no-results state, search for gibberish text and assert the empty state heading (e.g. `'No invoice data'`) and subtitle are visible.
- Empty state text varies by user role. Admin users see "Select a partner to view invoice data"; partner users do not. Assert the absence of role-inappropriate text with `not.toBeVisible()`.

### Assertion Strength

- **Weak:** `await expect(table).toBeVisible()` -- table is always visible.
- **Adequate:** `await expect(appliedFilterBadges.first()).toBeVisible()` -- proves filter applied.
- **Strong:** Capture row count before and after an action, assert the count changed and is > 0.
- For filtering: assert `rowsAfter <= rowsBefore` (filter narrows results).
- For sorting: assert `aria-sort` attribute changed on the sort button.
- For column management: assert column headers array changed after toggling.
- For accessibility: assert `aria-label` attributes exist on interactive elements with `toHaveAttribute('aria-label', /.+/)`.
- For formatted output: use regex patterns to verify currency symbols (`/[€$£¥₹]/`) and date formats (`/\d{2}\/\d{2}\/\d{4}/`).

### Page Load Strategy

- **Do not** use `waitForLoadState('networkidle')` -- MFE shell keeps persistent connections that prevent idle.
- **Do** use `waitForLoadState('domcontentloaded')` combined with an explicit element wait:
  ```typescript
  await page.goto('/path');
  await page.waitForLoadState('domcontentloaded');
  await page.getByRole('heading', { name: 'Page Title' }).waitFor({ state: 'visible', timeout: 30000 });
  ```

### Staging Data Accumulation

- Tests that create persistent data (saved reports, schedules) accumulate over time in staging. Do not write tests that assume an empty state unless the test creates and controls the entire lifecycle.
- Prefer asserting the presence of a specific item (by unique name) rather than asserting an empty table or a specific count.
- When testing empty states, verify the section heading and table structure exist rather than asserting "No saved reports" text, which depends on no prior test data.

## Golden Path

Reference: `@workspace-standards/golden-paths/integration-testing.md`
