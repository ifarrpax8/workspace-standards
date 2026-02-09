# Scoring Criteria: Code Quality (15 points)

Evaluates code readability, maintainability, and adherence to coding standards.

## Scoring Rubric

### Linter Configuration (5 points)

| Score | Criteria |
|-------|----------|
| 5 | Linter configured, no warnings, pre-commit hooks |
| 4 | Linter configured, minor warnings |
| 3 | Linter configured, some warnings ignored |
| 2 | Linter exists but not enforced |
| 1 | Minimal linting |
| 0 | No linter |

**Detection:**
```bash
# Kotlin - Check for Detekt
test -f "detekt.yml" && echo "1" || echo "0"
grep -r "detekt" build.gradle.kts | wc -l

# Kotlin - Check for Spotless
grep -r "spotless" build.gradle.kts | wc -l

# Vue - Check for ESLint
test -f ".eslintrc.js" -o -f ".eslintrc.json" && echo "1" || echo "0"

# Check for pre-commit hooks
test -d ".husky" -o -f ".pre-commit-config.yaml" && echo "1" || echo "0"
```

### Naming Conventions (5 points)

| Score | Criteria |
|-------|----------|
| 5 | Consistent, clear naming throughout |
| 4 | Minor inconsistencies |
| 3 | Some unclear or abbreviated names |
| 2 | Inconsistent naming patterns |
| 1 | Poor naming choices |
| 0 | Incomprehensible naming |

**Detection:**
```bash
# Check for common bad patterns
grep -rE "^(val|var|const|let)\s+[a-z]{1,2}\s*=" src/  # Single letter variables
grep -rE "data|temp|tmp|foo|bar|test[0-9]" src/       # Generic names
grep -rE "Impl$" src/                                   # Unnecessary Impl suffix (sometimes)
```

### Complexity (5 points)

| Score | Criteria |
|-------|----------|
| 5 | Low complexity, small focused functions |
| 4 | Mostly low complexity, few larger functions |
| 3 | Some complex functions that could be split |
| 2 | Multiple complex functions |
| 1 | High complexity throughout |
| 0 | Unmaintainable complexity |

**Detection:**
```bash
# Check for long files (>500 lines)
find src -name "*.kt" -o -name "*.ts" -o -name "*.vue" | xargs wc -l | awk '$1 > 500 {print}'

# Check for long functions (rough heuristic - count lines between fun/function)
# This is approximate; real cyclomatic complexity needs dedicated tools
```

## Automated Checks

```bash
# File length check
find src/main -name "*.kt" | while read f; do
  lines=$(wc -l < "$f")
  if [ "$lines" -gt 500 ]; then
    echo "WARNING: $f has $lines lines"
  fi
done

# Check for TODO/FIXME comments (not necessarily bad, but track them)
grep -rn "TODO\|FIXME\|HACK\|XXX" src/ | wc -l

# Check for commented-out code (often a smell)
grep -rn "^[[:space:]]*//.*{$\|^[[:space:]]*//.*}$" src/main/ | wc -l

# Kotlin - Run Detekt (if available)
./gradlew detekt 2>/dev/null && echo "Detekt passed" || echo "Detekt issues found"

# Vue - Run ESLint (if available)
npm run lint 2>/dev/null && echo "ESLint passed" || echo "ESLint issues found"
```

## Code Quality Indicators

### Positive Indicators
- Consistent formatting (Spotless/Prettier)
- Small, focused classes and functions
- Clear variable and function names
- Appropriate use of language features
- Minimal code duplication

### Negative Indicators
- Long parameter lists (>5 parameters)
- Deep nesting (>3 levels)
- Large classes (>300 lines)
- Magic numbers/strings
- Excessive comments (code should be self-documenting)
- Commented-out code blocks

## Language-Specific Checks

### Kotlin
```bash
# Check for idiomatic Kotlin
grep -r "Optional<" src/main/kotlin/   # Should use nullable types instead
grep -r "\.get()\|\.orElse(" src/main/kotlin/  # Optional usage (prefer Kotlin null safety)
grep -r "!!" src/main/kotlin/ | wc -l  # Non-null assertions (minimize these)
```

### TypeScript/Vue
```bash
# Check for type safety
grep -r ": any" src/ | wc -l           # Avoid any type
grep -r "as any" src/ | wc -l          # Type assertions to any
grep -r "@ts-ignore\|@ts-nocheck" src/ | wc -l  # TypeScript ignores
```

## Manual Review Points

- [ ] Functions do one thing
- [ ] No duplicate code
- [ ] Error handling is consistent
- [ ] No magic numbers (use constants)
- [ ] Code is self-documenting
- [ ] Complex logic has explanatory comments
