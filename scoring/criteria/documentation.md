# Scoring Criteria: Documentation (10 points)

Evaluates project documentation, ADRs, and code-level documentation.

## Scoring Rubric

### README Quality (4 points)

| Score | Criteria |
|-------|----------|
| 4 | Comprehensive README with setup, usage, architecture |
| 3 | Good README with setup and basic usage |
| 2 | Basic README with minimal information |
| 1 | README exists but unhelpful |
| 0 | No README |

**Detection:**
```bash
# Check README exists
test -f "README.md" && echo "1" || echo "0"

# Check README sections (look for common headers)
grep -E "^#{1,2} (Getting Started|Setup|Installation|Usage|Architecture|Contributing)" README.md | wc -l
```

### Architecture Decision Records (3 points)

| Score | Criteria |
|-------|----------|
| 3 | ADRs exist for major decisions, kept current |
| 2 | Some ADRs exist |
| 1 | ADRs exist but outdated |
| 0 | No ADRs |

**Detection:**
```bash
# Check for ADR directory
test -d "docs/adr" && echo "1" || echo "0"

# Count ADRs
find docs/adr -name "*.md" 2>/dev/null | wc -l

# Check for recent ADRs (modified in last 6 months)
find docs/adr -name "*.md" -mtime -180 2>/dev/null | wc -l
```

### API Documentation (3 points)

| Score | Criteria |
|-------|----------|
| 3 | OpenAPI spec, KDoc/JSDoc for public APIs |
| 2 | Some API documentation |
| 1 | Minimal documentation |
| 0 | No API documentation |

**Detection:**
```bash
# Check for OpenAPI spec
test -f "openapi.yaml" -o -f "openapi.json" -o -f "*-openapi.yaml" && echo "1" || echo "0"
find . -name "*openapi*.yaml" -o -name "*openapi*.json" | wc -l

# Kotlin - Check for KDoc
grep -r "/\*\*" src/main/kotlin/ | wc -l

# Kotlin - Check for Springdoc/OpenAPI config
grep -r "springdoc\|OpenApiConfiguration" src/main/kotlin/ | wc -l

# TypeScript - Check for JSDoc
grep -r "/\*\*" src/ --include="*.ts" | wc -l
```

## Automated Checks

```bash
# README completeness score
README_SCORE=0
if test -f "README.md"; then
  README_SCORE=$((README_SCORE + 1))
  
  # Check for key sections
  grep -q "## Getting Started\|## Setup\|## Installation" README.md && README_SCORE=$((README_SCORE + 1))
  grep -q "## Usage\|## Running" README.md && README_SCORE=$((README_SCORE + 1))
  grep -q "## Architecture\|## Design\|## Structure" README.md && README_SCORE=$((README_SCORE + 1))
fi
echo "README Score: $README_SCORE/4"

# ADR score
ADR_SCORE=0
if test -d "docs/adr"; then
  ADR_COUNT=$(find docs/adr -name "*.md" | wc -l)
  if [ "$ADR_COUNT" -gt 0 ]; then
    ADR_SCORE=2
    RECENT_ADR=$(find docs/adr -name "*.md" -mtime -180 | wc -l)
    if [ "$RECENT_ADR" -gt 0 ]; then
      ADR_SCORE=3
    fi
  fi
fi
echo "ADR Score: $ADR_SCORE/3"
```

## Documentation Requirements by Project Type

### Kotlin Backend
- README with build and run instructions
- OpenAPI specification
- ADRs for architectural decisions
- KDoc for public service interfaces

### Vue MFE
- README with development setup
- Component documentation (Storybook optional)
- JSDoc for composables and services
- Type definitions well-documented

### Axon Projects (Additional)
- Event catalog documentation
- Aggregate documentation
- Saga flow documentation

## Good README Template

```markdown
# Project Name

Brief description of what this service does.

## Getting Started

### Prerequisites
- Java 17+
- Docker (for local dependencies)

### Setup
1. Clone the repository
2. Run `docker-compose up -d`
3. Run `./gradlew bootRun`

## Usage

### API Endpoints
- `GET /api/v1/resource` - Description
- `POST /api/v1/resource` - Description

## Architecture

Brief description of architecture pattern used.
Link to ADRs for major decisions.

## Testing

How to run tests.

## Deployment

How the service is deployed.
```

## Manual Review Points

- [ ] README is accurate and up-to-date
- [ ] ADRs capture significant decisions
- [ ] API documentation matches implementation
- [ ] Complex code has explanatory comments
- [ ] No outdated documentation
