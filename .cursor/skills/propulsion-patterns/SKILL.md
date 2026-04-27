---
name: propulsion-patterns
description: Propulsion component testing patterns — PTable, PDrawer, PCheckbox, PDropdown, PModal, PSearchInput quirks and workarounds for Playwright tests
---

# Propulsion Component Patterns

Reference for testing `@pax8/propulsion` components in Playwright. These patterns were discovered through integration testing; the component library does not expose straightforward test hooks for all cases.

## When to Use

- Writing or debugging Playwright tests that interact with Propulsion components
- PTable select-all or pagination behaving unexpectedly
- PDrawer close button not responding to standard selectors
- Checkbox or dropdown selectors matching the wrong element

## When NOT to Use

- Generic Playwright patterns (page objects, fixtures, waiting) — see `playwright-standards` rule
- Vue component unit tests — see `vue-test-standards` rule

---

## PTable

- The `<table>` element is **always in the DOM**, even when empty. Empty state renders inside the table via a `#empty-state` slot (`PEmptyState`).
- **Do not** assert `toBeVisible()` on the table to prove data loaded — it will always pass.
- **Do** count data rows: `table.locator('tbody tr')` and assert `count > 0`.
- Column headers include a `Header - ` prefix in their `aria-label`. Strip this when comparing names.
- Sort buttons use `aria-sort` (`none`, `ascending`, `descending`). Assert attribute transitions rather than comparing cell text.
- Grouped tables replace the standard column set with group name + count columns. Compare `getColumnHeaders()` before and after grouping to assert structure changed.

### Pagination and Scoping

- Scope table locators to their parent view container when multiple tables are on a page:
  ```typescript
  this.savedReportsTable = this.reportCenterView.getByRole('table');
  ```
- Paginated tables default to 10 rows. Tests that create data and look for it must sort by a relevant column (e.g. "Modified" descending) to ensure the new item appears on page 1:
  ```typescript
  async sortByModifiedDescending() {
    const sortButton = this.table.getByRole('button', { name: 'Sort by Modified' });
    await sortButton.click();
    if (await sortButton.getAttribute('aria-sort') !== 'descending') {
      await sortButton.click();
    }
  }
  ```

### Select-All and `disabled` Rows

- Per-row checkboxes honour `item.disabled`. Header "select all" **does not** — it sets `isSelected` on every row including disabled ones.
- Filter `update:selectedRows` before acting: `rows.filter(r => !r.disabled)`.
- Header checkbox desync: after replacing `items`, remount `PTable` with a changing `:key` to reset internal header state.
- **Long-term fix belongs in `@pax8/propulsion`** — until then, assume this behaviour wherever `disabled` rows coexist with bulk selection.

### `itemsPerPage`

- Bind as `:items-per-page`, not `:page-size`. The latter is ignored at runtime.
- Always bind `:items-per-page` to the same page size your API and `p-pagination` use.

---

## PDrawer

- The close button has **no accessible name and no `data-testid`**. Do not use `getByLabel`, `getByRole('button', { name })`, or `[data-testid="p-drawer-close"]`.
- **Reliable close pattern:**
  ```typescript
  const drawer = page.getByRole('dialog');
  const headerSection = drawer.locator('div')
    .filter({ has: page.getByRole('heading', { name: 'Drawer Title' }) })
    .first();
  await headerSection.getByRole('button').click();
  ```
- `Escape` does **not** close `PDrawer` when `presentation="modal"`.
- The drawer uses `v-if` — it is removed from the DOM when closed. Assert `not.toBeVisible()` on a unique element inside (e.g. a search input) to confirm closure.

---

## PCheckbox

- Renders `<input type="checkbox" id="{columnKey}">` where `id` is the programmatic key (`productSku`), not the display label (`SKU`).
- `getByLabel('SKU')` matches multiple elements. **Prefer** `page.locator('#productSku')` or scope within a container: `page.getByRole('dialog').getByRole('checkbox', { name: 'SKU' })`.

---

## PDropdown / Facet Selects

- Triggers: `data-testid="{field}-select-trigger"`. Options: `data-testid="{field}-select-option"`.
- Dropdowns render as `listbox` role. After selecting, close explicitly:
  ```typescript
  await page.keyboard.press('Escape');
  await page.getByRole('listbox').waitFor({ state: 'hidden', timeout: 5000 }).catch(() => {});
  ```
- Facet badges may include counts (`Partner 5`). Do not assert on badge counts — they may be removed.

---

## PModal / PDialog

- Locate with `page.getByRole('dialog')`.
- Radio groups inside modals: use `modal.getByRole('radio', { name: 'Option' })` not `page.getByText('Option')`.
- Modals with a default selection will not trigger validation on save. Verify default state with `toBeChecked()` first.
- Cancel reliably closes modals. Assert `not.toBeVisible()` on the dialog after clicking Cancel.

---

## PSearchInput

- Renders a `searchbox` role element.
- In `ManageColumnsDrawer`, the search only filters **Available columns**. Selected columns remain regardless of the search term.
- When counting filtered results, count unchecked checkboxes (`getByRole('checkbox', { checked: false })`).
- The filter removes non-matching items from the DOM (`v-for` over computed list). Allow a brief wait (`waitForTimeout(500–1000)`) for Vue reactivity before counting.

---

## PEmptyState

- Renders a heading and subtitle inside the table's `#empty-state` slot. Visible even though the table is always in the DOM.
- To verify no-results: search for gibberish text, assert the empty state heading and subtitle are visible.
- Empty state text varies by user role — assert absence of role-inappropriate text with `not.toBeVisible()`.

---

## Assertion Strength Guide

| Strength | Pattern | Notes |
|---|---|---|
| **Weak** | `expect(table).toBeVisible()` | Table is always visible — proves nothing |
| **Adequate** | `expect(appliedFilterBadges.first()).toBeVisible()` | Proves filter applied |
| **Strong** | Row count before/after, assert count changed and > 0 | For data operations |
| Filtering | `rowsAfter <= rowsBefore` | Filter narrows results |
| Sorting | `aria-sort` attribute changed on sort button | Don't compare cell text |
| Column management | Headers array changed after toggling | |
| Accessibility | `toHaveAttribute('aria-label', /.+/)` | |
| Formatted output | `/[€$£¥₹]/` for currency, `/\d{2}\/\d{2}\/\d{4}/` for dates | |

---

## Page Load Strategy

- **Do not** use `waitForLoadState('networkidle')` — MFE shell keeps persistent connections.
- **Do** use `domcontentloaded` + explicit element wait:
  ```typescript
  await page.goto('/path');
  await page.waitForLoadState('domcontentloaded');
  await page.getByRole('heading', { name: 'Page Title' }).waitFor({ state: 'visible', timeout: 30000 });
  ```

---

## Staging Data Accumulation

- Tests that create persistent data (saved reports, schedules) accumulate over time. Do not assume an empty state.
- Assert presence of a specific named item, not total count or "No saved reports" text.
