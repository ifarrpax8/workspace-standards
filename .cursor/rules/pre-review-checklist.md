---
description: Cross-cutting quality checks to run before opening a pull request
globs: ["**/*"]
alwaysApply: false
---

# Pre-Review Checklist

Cross-cutting quality checks that apply regardless of language or framework. Run these before opening a PR.

## Separation of Concerns

- [ ] Cross-cutting logic (file downloads, CSV generation, date formatting) lives in shared utilities — not inside service classes or components
- [ ] No duplicated logic to support a new code path — extend the existing method with optional parameters instead
- [ ] Configuration (URLs, magic strings, feature-specific constants) is externalised — not hardcoded in components or services
- [ ] Shared constants (debounce timings, page sizes, sort defaults) are defined once and imported

## Error Handling in Service Calls

- [ ] Every service/API call has a catch block or is wrapped in try/catch — failures must not propagate silently
- [ ] Error handling follows the established pattern in the repo — check for an existing example before writing a new one
- [ ] No raw status code comparisons (`!= 200`) — use the HTTP client's built-in error handling

## UX Robustness

- [ ] Conditional UI elements (filters, cards) use fixed widths so layout does not shift when elements hide/show
- [ ] Async actions triggered by buttons show a loading state (`:loading` prop or equivalent)
- [ ] "No value" is distinguished from "zero" — `v-if="count"` hides zero; use `v-if="count != null"` when zero is a valid display value
- [ ] User input that triggers API calls (search, filters) is debounced — use a shared constant for the interval

## Dead Code / YAGNI

- [ ] No code shipped for future tickets — if it is not used in this PR, do not include it
- [ ] Stale constants, unused imports, and irrelevant comments are removed
- [ ] No documentation that merely restates what the code already says
