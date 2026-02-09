# Scoring Criteria: Consistency (15 points)

Evaluates pattern uniformity and consistency within the repository.

## Scoring Rubric

### Naming Consistency (5 points)

| Score | Criteria |
|-------|----------|
| 5 | All files, classes, functions follow same conventions |
| 4 | Minor inconsistencies |
| 3 | Some inconsistent patterns |
| 2 | Multiple naming conventions mixed |
| 1 | No clear naming convention |
| 0 | Chaotic naming |

**Detection:**
```bash
# Kotlin - Check class naming consistency
find src/main/kotlin -name "*.kt" | xargs grep -l "^class " | while read f; do
  # Extract class names and check PascalCase
  grep "^class " "$f" | sed 's/class \([A-Za-z0-9_]*\).*/\1/'
done

# Kotlin - Check for consistent suffixes
find src/main/kotlin -name "*Service.kt" | wc -l
find src/main/kotlin -name "*Repository.kt" | wc -l
find src/main/kotlin -name "*Controller.kt" | wc -l

# Vue - Check component naming
find src/components -name "*.vue" | xargs -I {} basename {} .vue | sort | uniq -c
```

### Structural Consistency (5 points)

| Score | Criteria |
|-------|----------|
| 5 | All similar components follow same structure |
| 4 | Minor structural variations |
| 3 | Some components deviate from pattern |
| 2 | Inconsistent structure across components |
| 1 | No structural pattern |
| 0 | Every component is different |

**Detection:**
```bash
# Kotlin - Check all services have same package structure
find src/main/kotlin -type d -name "service" | wc -l  # Should be 1

# Kotlin - Check for consistent test structure
find src/test/kotlin -name "*Test.kt" | wc -l
find src/test/kotlin -name "*IntegrationTest.kt" | wc -l

# Vue - Check all feature folders have index.ts
find src/components -mindepth 1 -maxdepth 1 -type d | while read dir; do
  test -f "$dir/index.ts" && echo "OK: $dir" || echo "MISSING: $dir/index.ts"
done
```

### Pattern Consistency (5 points)

| Score | Criteria |
|-------|----------|
| 5 | Consistent use of patterns throughout (DI, error handling, etc.) |
| 4 | Minor pattern variations |
| 3 | Some inconsistent pattern usage |
| 2 | Multiple competing patterns |
| 1 | Pattern usage varies widely |
| 0 | No consistent patterns |

**Detection:**
```bash
# Kotlin - Check for consistent dependency injection
grep -r "@Autowired" src/main/kotlin/ | wc -l  # Should be 0 or minimal (prefer constructor)
grep -r "private val\|private lateinit var" src/main/kotlin/ | head -20

# Kotlin - Check for consistent exception handling
grep -r "@ExceptionHandler\|@RestControllerAdvice" src/main/kotlin/ | wc -l

# Vue - Check for consistent composable usage
grep -r "use[A-Z]" src/components/ --include="*.vue" | wc -l
grep -r "use[A-Z]" src/composables/ --include="*.ts" | wc -l
```

## Automated Checks

```bash
#!/bin/bash
# Consistency analysis script

echo "=== Naming Consistency ==="

# Check file naming patterns
echo "Service files:"
find src -name "*Service*" | head -10

echo "Controller/Endpoint files:"
find src -name "*Controller*" -o -name "*Endpoint*" | head -10

echo "=== Structural Consistency ==="

# Check for index files in feature folders
echo "Feature folders with index.ts:"
for dir in src/components/*/; do
  if [ -d "$dir" ]; then
    test -f "${dir}index.ts" && echo "  ✓ $dir" || echo "  ✗ $dir (missing index.ts)"
  fi
done

echo "=== Import Consistency ==="

# Check for consistent import styles
echo "Relative imports:"
grep -r "from '\.\." src/ --include="*.ts" | wc -l

echo "Alias imports (@/):"
grep -r "from '@/" src/ --include="*.ts" | wc -l
```

## Consistency Checklist by Project Type

### Kotlin Projects
- [ ] All services use constructor injection
- [ ] All controllers follow same error handling pattern
- [ ] All tests use same testing framework and patterns
- [ ] All entities have consistent annotation usage
- [ ] Package structure is uniform

### Axon Projects (Additional)
- [ ] All aggregates follow same handler patterns
- [ ] Events and commands use consistent naming
- [ ] Sagas follow same lifecycle patterns
- [ ] Projections are structured consistently

### Vue Projects
- [ ] All components use `<script setup>`
- [ ] All feature folders have barrel exports (index.ts)
- [ ] Composables follow same return patterns
- [ ] Services use consistent API patterns
- [ ] State management is uniform (Pinia or props)

## Common Inconsistency Patterns

### Code Smell: Mixed Patterns
```kotlin
// BAD: Some services use constructor injection, some use @Autowired
@Service
class ServiceA(private val repo: Repository) { }  // Good

@Service
class ServiceB {
    @Autowired
    private lateinit var repo: Repository  // Inconsistent
}
```

### Code Smell: Mixed Component Styles
```vue
<!-- BAD: Some components use Options API, some use Composition API -->
<script>  <!-- Options API -->
export default {
  data() { return { count: 0 } }
}
</script>

<script setup>  <!-- Composition API -->
const count = ref(0)
</script>
```

## Manual Review Points

- [ ] New code follows established patterns
- [ ] No legacy patterns introduced in new code
- [ ] Error handling is uniform
- [ ] Logging patterns are consistent
- [ ] Test structure matches source structure
