# Scoring Criteria: Testing (15 points)

Evaluates test coverage, test quality, and testing patterns.

## Scoring Rubric

### Test Coverage (5 points)

| Score | Criteria |
|-------|----------|
| 5 | 80%+ coverage |
| 4 | 60-79% coverage |
| 3 | 40-59% coverage |
| 2 | 20-39% coverage |
| 1 | 1-19% coverage |
| 0 | No tests or 0% coverage |

**Detection:**
- Kotlin: Check Jacoco report or `build/reports/jacoco/`
- Vue: Check Istanbul coverage output

### Test Existence (5 points)

| Score | Criteria |
|-------|----------|
| 5 | Tests exist for all public components/services |
| 4 | Tests for most components (>80%) |
| 3 | Tests for core components (>50%) |
| 2 | Sparse test coverage (<50%) |
| 1 | Minimal tests |
| 0 | No test files |

**Detection:**
```bash
# Kotlin - Count test files vs source files
SOURCE_COUNT=$(find src/main -name "*.kt" | wc -l)
TEST_COUNT=$(find src/test -name "*.kt" | wc -l)
RATIO=$((TEST_COUNT * 100 / SOURCE_COUNT))

# Vue - Count test files
find src -name "*.test.ts" -o -name "*.spec.ts" | wc -l
```

### Test Quality (5 points)

| Score | Criteria |
|-------|----------|
| 5 | Tests follow best practices, clear naming, proper assertions |
| 4 | Minor quality issues |
| 3 | Some tests lack clarity or proper structure |
| 2 | Many tests are shallow or poorly structured |
| 1 | Tests exist but provide little value |
| 0 | No meaningful tests |

**Detection:**
- Check for test naming convention (`should...`, `when...then...`)
- Check for proper assertions (not just `assertNotNull`)
- Check for test isolation (no shared mutable state)

## Automated Checks

```bash
# Kotlin - Check for test directory
test -d "src/test/kotlin" && echo "1" || echo "0"

# Kotlin - Check for integration tests
grep -r "@SpringBootTest" src/test/ | wc -l

# Kotlin - Check for Axon test fixtures
grep -r "AggregateTestFixture" src/test/ | wc -l
grep -r "SagaTestFixture" src/test/ | wc -l

# Vue - Check for test files
find src -name "*.test.ts" | wc -l
find src -name "*.test.js" | wc -l

# Vue - Check for Testing Library usage
grep -r "@testing-library" package.json | wc -l

# Check for skipped tests (penalty)
grep -r "@Disabled" src/test/ | wc -l           # Kotlin
grep -r "it.skip\|describe.skip" src/ | wc -l  # Vue
```

## Test Type Requirements by Project

### Kotlin Spring Boot
- Integration tests with @SpringBootTest
- MockMvc for controller tests
- Repository tests with embedded database

### Kotlin Axon
- AggregateTestFixture for aggregate tests
- SagaTestFixture for saga tests
- Integration tests for projections

### Vue MFE
- Vitest for unit tests
- Testing Library for component tests
- Snapshot tests for UI regression

## Manual Review Points

- [ ] Tests are readable and well-named
- [ ] No hardcoded test data that could break
- [ ] Mocking is appropriate (not over-mocked)
- [ ] Edge cases are covered
- [ ] Error scenarios are tested
- [ ] No flaky tests
