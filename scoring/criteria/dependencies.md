# Scoring Criteria: Dependencies (15 points)

Evaluates dependency management, version currency, and vulnerability status.

## Scoring Rubric

### Version Currency (5 points)

| Score | Criteria |
|-------|----------|
| 5 | All dependencies on latest stable versions |
| 4 | Within 1 minor version of latest |
| 3 | Within 1 major version of latest |
| 2 | Multiple outdated dependencies |
| 1 | Significantly outdated |
| 0 | Extremely outdated or abandoned dependencies |

**Detection:**
```bash
# Kotlin/Gradle
./gradlew dependencyUpdates 2>/dev/null || echo "Plugin not installed"

# Vue/npm
npm outdated 2>/dev/null || echo "No package.json"

# Check for Dependabot
test -f ".github/dependabot.yml" && echo "Dependabot configured" || echo "No Dependabot"
```

### Security Vulnerabilities (5 points)

| Score | Criteria |
|-------|----------|
| 5 | No known vulnerabilities |
| 4 | Low severity vulnerabilities only |
| 3 | Medium severity vulnerabilities |
| 2 | High severity vulnerabilities |
| 1 | Critical vulnerabilities |
| 0 | Multiple critical vulnerabilities |

**Detection:**
```bash
# npm audit
npm audit 2>/dev/null | grep -E "found [0-9]+ vulnerabilities"

# Gradle - Check for OWASP dependency check plugin
grep -r "owasp\|dependencyCheck" build.gradle.kts
```

### Lock File & Reproducibility (5 points)

| Score | Criteria |
|-------|----------|
| 5 | Lock file present, committed, and up-to-date |
| 4 | Lock file present and committed |
| 3 | Lock file present but may be stale |
| 2 | Lock file exists but not committed |
| 1 | Inconsistent lock file usage |
| 0 | No lock file |

**Detection:**
```bash
# Check for lock files
test -f "gradle.lockfile" && echo "Gradle lock: ✓" || echo "Gradle lock: ✗"
test -f "package-lock.json" && echo "npm lock: ✓" || echo "npm lock: ✗"
test -f "pnpm-lock.yaml" && echo "pnpm lock: ✓" || echo "pnpm lock: ✗"
test -f "yarn.lock" && echo "yarn lock: ✓" || echo "yarn lock: ✗"

# Check if lock file is in .gitignore (bad)
grep -q "package-lock.json\|yarn.lock\|pnpm-lock.yaml" .gitignore && echo "WARNING: Lock file may be ignored"
```

## Automated Checks

```bash
#!/bin/bash
# Dependency health check

echo "=== Dependency Currency ==="

if test -f "package.json"; then
  echo "npm outdated:"
  npm outdated 2>/dev/null | head -20
fi

if test -f "build.gradle.kts"; then
  echo "Gradle dependencies:"
  grep -E "implementation|api|testImplementation" build.gradle.kts | head -20
fi

echo ""
echo "=== Vulnerability Check ==="

if test -f "package.json"; then
  npm audit --json 2>/dev/null | jq '.metadata.vulnerabilities' 2>/dev/null || npm audit 2>/dev/null
fi

echo ""
echo "=== Lock File Status ==="

for lockfile in "package-lock.json" "yarn.lock" "pnpm-lock.yaml" "gradle.lockfile"; do
  if test -f "$lockfile"; then
    echo "✓ $lockfile exists"
    # Check if tracked by git
    git ls-files --error-unmatch "$lockfile" 2>/dev/null && echo "  ✓ Tracked by git" || echo "  ✗ Not tracked by git"
  fi
done

echo ""
echo "=== Dependabot Status ==="
test -f ".github/dependabot.yml" && cat .github/dependabot.yml || echo "Dependabot not configured"
```

## Dependency Best Practices

### Version Pinning
```kotlin
// build.gradle.kts - Use version catalogs or explicit versions
dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web:3.2.0")  // Pinned
    implementation(libs.spring.boot.starter.web)  // Or version catalog
}
```

```json
// package.json - Pin major versions at minimum
{
  "dependencies": {
    "vue": "^3.4.0",     // Good: locked to 3.x
    "axios": "1.6.2"     // Better: exact version
  }
}
```

### Dependabot Configuration
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    
  - package-ecosystem: "gradle"
    directory: "/"
    schedule:
      interval: "weekly"
```

## Common Issues

### Outdated Patterns
- Using deprecated packages
- Mixing package managers (npm + yarn)
- Not updating major versions in reasonable time

### Security Issues
- Dependencies with known CVEs
- Abandoned/unmaintained packages
- Overly permissive version ranges

## Shared Dependencies Alignment

Cross-repo alignment check (reference pattern-inventory.md):

| Package | finance-mfe | order-management-mfe | Aligned? |
|---------|-------------|---------------------|----------|
| Vue | 3.5.x | 3.5.x | ✓ |
| Vitest | 3.2.x | 1.1.x | ✗ |
| @pax8/propulsion | 1.64.x | 1.52.x | ✗ |

## Manual Review Points

- [ ] No deprecated packages
- [ ] Security advisories addressed
- [ ] Lock file committed and current
- [ ] Dependabot or similar configured
- [ ] Version alignment across related projects
- [ ] No unnecessary dependencies

## Golden Path References

To improve your score in this category, reference these golden paths:

| Project Type | Golden Path | Relevant Sections |
|-------------|-------------|-------------------|
| Kotlin (Spring Boot) | [Kotlin Spring Boot](../../golden-paths/kotlin-spring-boot.md) | Configuration Files (application.yml) |
| Kotlin (Axon) | [Kotlin Axon CQRS](../../golden-paths/kotlin-axon-cqrs.md) | Configuration (application.yml) |
| Vue MFE | [Vue MFE](../../golden-paths/vue-mfe.md) | Services (import.meta.env), Checklist (no hardcoded API URLs) |
| Terraform | [Terraform IaC](../../golden-paths/terraform-iac.md) | Root Module (required_version, required_providers), Child Module Layout (versions.tf) |
