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

## Golden Path

Reference: `@workspace-standards/golden-paths/integration-testing.md`
