#!/bin/bash

# Codebase Scoring Script
# Evaluates a repository against 7 categories, outputs score out of 100
#
# Usage: ./score.sh <path-to-repo>
# Example: ./score.sh ../currency-manager

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Score weights (total = 100)
ARCH_WEIGHT=13
TEST_WEIGHT=13
SECURITY_WEIGHT=14
QUALITY_WEIGHT=13
DOCS_WEIGHT=10
CONSISTENCY_WEIGHT=13
DEPS_WEIGHT=14
OBSERVABILITY_WEIGHT=10

# Check arguments
if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-repo>"
    echo "Example: $0 ../currency-manager"
    exit 1
fi

REPO_PATH="$1"
if [ ! -d "$REPO_PATH" ]; then
    echo "Error: Directory '$REPO_PATH' not found"
    exit 1
fi

cd "$REPO_PATH"
REPO_NAME=$(basename "$(pwd)")

# Detect project type
detect_project_type() {
    if [ -f "build.gradle.kts" ] || [ -f "build.gradle" ]; then
        if grep -q "axon" build.gradle.kts 2>/dev/null || grep -q "axon" build.gradle 2>/dev/null; then
            echo "kotlin-axon"
        else
            echo "kotlin"
        fi
    elif [ -f "package.json" ]; then
        if grep -q "vue" package.json; then
            echo "vue"
        else
            echo "node"
        fi
    elif [ -f "main.tf" ] || [ -d "terraform" ]; then
        echo "terraform"
    else
        echo "unknown"
    fi
}

PROJECT_TYPE=$(detect_project_type)

# Progress bar function
progress_bar() {
    local score=$1
    local max=$2
    local width=16
    local filled=$((score * width / max))
    local empty=$((width - filled))
    
    printf "["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "]"
}

# ============================================================================
# ARCHITECTURE SCORING (15 points)
# ============================================================================
score_architecture() {
    local score=0
    
    case "$PROJECT_TYPE" in
        kotlin|kotlin-axon)
            # Check package structure (5 points)
            local structure_score=0
            [ -d "src/main/kotlin" ] && structure_score=$((structure_score + 1))
            find src/main/kotlin -type d -name "endpoint" 2>/dev/null | grep -q . && structure_score=$((structure_score + 1))
            find src/main/kotlin -type d -name "service" 2>/dev/null | grep -q . && structure_score=$((structure_score + 2))
            find src/main/kotlin -type d -name "repository" 2>/dev/null | grep -q . && structure_score=$((structure_score + 1))
            score=$((score + structure_score))
            
            # Check separation (5 points)
            local separation_score=5
            # Penalty for repository in endpoint
            if grep -rq "Repository" src/main/kotlin/**/endpoint/ 2>/dev/null; then
                separation_score=$((separation_score - 2))
            fi
            score=$((score + separation_score))
            
            # Pattern adherence (5 points)
            if [ "$PROJECT_TYPE" = "kotlin-axon" ]; then
                local axon_score=0
                grep -rq "@Aggregate" src/main/kotlin/ 2>/dev/null && axon_score=$((axon_score + 2))
                grep -rq "@CommandHandler" src/main/kotlin/ 2>/dev/null && axon_score=$((axon_score + 2))
                grep -rq "@EventSourcingHandler" src/main/kotlin/ 2>/dev/null && axon_score=$((axon_score + 1))
                score=$((score + axon_score))
            else
                # Standard layered - check for service pattern
                local service_count=$(find src/main/kotlin -name "*Service.kt" 2>/dev/null | wc -l)
                [ "$service_count" -gt 0 ] && score=$((score + 5))
            fi
            ;;
        vue)
            # Check Vue structure (5 points)
            local vue_structure=0
            [ -d "src/components" ] && vue_structure=$((vue_structure + 2))
            [ -d "src/composables" ] && vue_structure=$((vue_structure + 1))
            [ -d "src/services" ] && vue_structure=$((vue_structure + 1))
            [ -d "src/views" ] && vue_structure=$((vue_structure + 1))
            score=$((score + vue_structure))
            
            # Check for feature folders (5 points)
            local feature_folders=$(find src/components -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
            [ "$feature_folders" -gt 3 ] && score=$((score + 5)) || score=$((score + feature_folders))
            
            # Check for composable pattern (5 points)
            local composables=$(find src/composables -name "use*.ts" 2>/dev/null | wc -l)
            [ "$composables" -gt 3 ] && score=$((score + 5)) || score=$((score + composables))
            ;;
        *)
            score=5  # Default baseline
            ;;
    esac
    
    # Cap at max
    [ "$score" -gt "$ARCH_WEIGHT" ] && score=$ARCH_WEIGHT
    echo "$score"
}

# ============================================================================
# TESTING SCORING
# ============================================================================
score_testing() {
    local score=0
    
    case "$PROJECT_TYPE" in
        kotlin|kotlin-axon)
            # Test existence (5 points)
            if [ -d "src/test/kotlin" ]; then
                local test_files=$(find src/test/kotlin -name "*.kt" 2>/dev/null | wc -l)
                [ "$test_files" -gt 10 ] && score=$((score + 5))
                [ "$test_files" -gt 5 ] && [ "$test_files" -le 10 ] && score=$((score + 4))
                [ "$test_files" -gt 0 ] && [ "$test_files" -le 5 ] && score=$((score + 2))
            fi
            
            # Integration tests (5 points)
            local integration=$(grep -rl "@SpringBootTest" src/test/ 2>/dev/null | wc -l)
            [ "$integration" -gt 0 ] && score=$((score + 3))
            
            # Contract tests (2 points)
            grep -rq "@PactVerify\|@PactTest\|ContractTest" src/test/ 2>/dev/null && score=$((score + 2))
            
            # Axon test fixtures (5 points for axon projects)
            if [ "$PROJECT_TYPE" = "kotlin-axon" ]; then
                grep -rq "AggregateTestFixture" src/test/ 2>/dev/null && score=$((score + 3))
                grep -rq "SagaTestFixture" src/test/ 2>/dev/null && score=$((score + 2))
            else
                # Non-axon: general test quality
                local source_count=$(find src/main -name "*.kt" 2>/dev/null | wc -l)
                local test_ratio=$((test_files * 100 / (source_count + 1)))
                [ "$test_ratio" -gt 50 ] && score=$((score + 5))
                [ "$test_ratio" -gt 25 ] && [ "$test_ratio" -le 50 ] && score=$((score + 3))
            fi
            ;;
        vue)
            # Test file existence (5 points)
            local test_files=$(find src -name "*.test.ts" -o -name "*.test.js" -o -name "*.spec.ts" 2>/dev/null | wc -l)
            [ "$test_files" -gt 20 ] && score=$((score + 5))
            [ "$test_files" -gt 10 ] && [ "$test_files" -le 20 ] && score=$((score + 4))
            [ "$test_files" -gt 0 ] && [ "$test_files" -le 10 ] && score=$((score + 2))
            
            # Testing library usage (5 points)
            grep -q "@testing-library" package.json 2>/dev/null && score=$((score + 3))
            grep -q "vitest" package.json 2>/dev/null && score=$((score + 2))
            
            # Snapshot tests (5 points)
            local snapshots=$(find src -name "*.snap" 2>/dev/null | wc -l)
            [ "$snapshots" -gt 0 ] && score=$((score + 3))
            
            # Test coverage config (2 points)
            grep -q "coverage" vitest.config.* 2>/dev/null && score=$((score + 2))
            ;;
        *)
            # Check for any test directory
            [ -d "tests" ] || [ -d "test" ] && score=5
            ;;
    esac
    
    [ "$score" -gt "$TEST_WEIGHT" ] && score=$TEST_WEIGHT
    echo "$score"
}

# ============================================================================
# SECURITY SCORING (15 points)
# ============================================================================
score_security() {
    local score=10  # Start with baseline
    
    # Secret detection - PENALTIES
    if grep -rqE "(password|secret|api_key).*=.*['\"][^'\"]+['\"]" src/ 2>/dev/null; then
        score=$((score - 3))
    fi
    
    # .gitignore check (2 points)
    if [ -f ".gitignore" ]; then
        grep -qE "\.env|credentials|secrets" .gitignore && score=$((score + 2))
    fi
    
    case "$PROJECT_TYPE" in
        kotlin|kotlin-axon)
            # Validation annotations (3 points)
            grep -rq "@Valid\|@NotNull\|@NotBlank" src/main/kotlin/ 2>/dev/null && score=$((score + 2))
            
            # Controller advice (2 points)
            grep -rq "@RestControllerAdvice" src/main/kotlin/ 2>/dev/null && score=$((score + 1))
            
            # Security config
            grep -rq "spring-boot-starter-security\|spring-security" build.gradle.kts 2>/dev/null && score=$((score + 2))
            ;;
        vue)
            # XSS protection (3 points)
            grep -q "dompurify\|xss" package.json 2>/dev/null && score=$((score + 3))
            
            # No dangerous patterns (penalty)
            if grep -rq "v-html=" src/ 2>/dev/null; then
                # Check if sanitized
                grep -rq "DOMPurify\|sanitize" src/ 2>/dev/null || score=$((score - 2))
            fi
            ;;
    esac
    
    # Bonus for pre-commit security hooks
    grep -q "detect-secrets\|gitleaks" .pre-commit-config.yaml 2>/dev/null && score=$((score + 1))
    
    [ "$score" -lt 0 ] && score=0
    [ "$score" -gt "$SECURITY_WEIGHT" ] && score=$SECURITY_WEIGHT
    echo "$score"
}

# ============================================================================
# CODE QUALITY SCORING (15 points)
# ============================================================================
score_quality() {
    local score=5  # Baseline
    
    # Linter configuration (5 points)
    case "$PROJECT_TYPE" in
        kotlin|kotlin-axon)
            [ -f "detekt.yml" ] && score=$((score + 3))
            grep -q "spotless" build.gradle.kts 2>/dev/null && score=$((score + 2))
            ;;
        vue)
            [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] && score=$((score + 3))
            [ -f ".prettierrc" ] || [ -f ".prettierrc.cjs" ] && score=$((score + 2))
            ;;
    esac
    
    # Pre-commit hooks (3 points)
    [ -d ".husky" ] && score=$((score + 2))
    [ -f ".pre-commit-config.yaml" ] && score=$((score + 2))
    
    # Check for long files (penalty)
    local long_files=$(find src -name "*.kt" -o -name "*.ts" -o -name "*.vue" 2>/dev/null | xargs wc -l 2>/dev/null | awk '$1 > 500 {count++} END {print count+0}')
    [ "$long_files" -gt 5 ] && score=$((score - 2))
    
    # TypeScript strict mode (Vue projects)
    if [ "$PROJECT_TYPE" = "vue" ]; then
        grep -q '"strict": true' tsconfig.json 2>/dev/null && score=$((score + 2))
    fi
    
    [ "$score" -lt 0 ] && score=0
    [ "$score" -gt "$QUALITY_WEIGHT" ] && score=$QUALITY_WEIGHT
    echo "$score"
}

# ============================================================================
# DOCUMENTATION SCORING (10 points)
# ============================================================================
score_documentation() {
    local score=0
    
    # README (4 points)
    if [ -f "README.md" ]; then
        score=$((score + 1))
        grep -qE "^#{1,2} (Getting Started|Setup|Installation)" README.md && score=$((score + 1))
        grep -qE "^#{1,2} (Usage|Running)" README.md && score=$((score + 1))
        grep -qE "^#{1,2} (Architecture|Design)" README.md && score=$((score + 1))
    fi
    
    # ADRs (3 points)
    if [ -d "docs/adr" ]; then
        local adr_count=$(find docs/adr -name "*.md" 2>/dev/null | wc -l)
        [ "$adr_count" -gt 5 ] && score=$((score + 3))
        [ "$adr_count" -gt 0 ] && [ "$adr_count" -le 5 ] && score=$((score + 2))
    fi
    
    # API docs (3 points)
    if find . -maxdepth 1 -name "*openapi*" 2>/dev/null | grep -q .; then
        score=$((score + 2))
    fi
    
    case "$PROJECT_TYPE" in
        kotlin|kotlin-axon)
            grep -rq "springdoc\|OpenApiConfiguration" src/main/kotlin/ 2>/dev/null && score=$((score + 1))
            ;;
    esac
    
    [ "$score" -gt "$DOCS_WEIGHT" ] && score=$DOCS_WEIGHT
    echo "$score"
}

# ============================================================================
# CONSISTENCY SCORING (15 points)
# ============================================================================
score_consistency() {
    local score=10  # Start with good baseline
    
    case "$PROJECT_TYPE" in
        kotlin|kotlin-axon)
            # Check for consistent injection pattern (penalty for @Autowired)
            local autowired=$(grep -rc "@Autowired" src/main/kotlin/ 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
            [ "$autowired" -gt 5 ] && score=$((score - 2))
            
            # Check for consistent naming
            local services=$(find src/main/kotlin -name "*Service.kt" 2>/dev/null | wc -l)
            local service_impls=$(find src/main/kotlin -name "*ServiceImpl.kt" 2>/dev/null | wc -l)
            # If mixing Service and ServiceImpl, penalty
            [ "$services" -gt 0 ] && [ "$service_impls" -gt 0 ] && score=$((score - 1))
            
            # Bonus for consistent test structure
            [ -d "src/test/kotlin" ] && score=$((score + 3))
            ;;
        vue)
            # Check for script setup consistency
            local script_setup=$(grep -rl "<script setup" src/components/ 2>/dev/null | wc -l)
            local script_options=$(grep -rl "<script>" src/components/ 2>/dev/null | grep -v "setup" | wc -l)
            
            # Penalty for mixing styles
            [ "$script_setup" -gt 0 ] && [ "$script_options" -gt 0 ] && score=$((score - 3))
            
            # Check for barrel exports
            local feature_dirs=$(find src/components -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
            local index_files=$(find src/components -mindepth 2 -maxdepth 2 -name "index.ts" 2>/dev/null | wc -l)
            [ "$index_files" -ge "$((feature_dirs / 2))" ] && score=$((score + 3))
            
            # TypeScript usage
            grep -rq ": any" src/ 2>/dev/null && score=$((score - 2))
            ;;
    esac
    
    # Bonus for Cursor rules
    [ -d ".cursor/rules" ] && score=$((score + 2))
    
    [ "$score" -lt 0 ] && score=0
    [ "$score" -gt "$CONSISTENCY_WEIGHT" ] && score=$CONSISTENCY_WEIGHT
    echo "$score"
}

# ============================================================================
# DEPENDENCIES SCORING (15 points)
# ============================================================================
score_dependencies() {
    local score=8  # Baseline
    
    # Lock file check (5 points)
    if [ -f "package-lock.json" ]; then
        score=$((score + 3))
        git ls-files --error-unmatch "package-lock.json" >/dev/null 2>&1 && score=$((score + 2))
    elif [ -f "yarn.lock" ]; then
        score=$((score + 3))
        git ls-files --error-unmatch "yarn.lock" >/dev/null 2>&1 && score=$((score + 2))
    elif [ -f "pnpm-lock.yaml" ]; then
        score=$((score + 3))
        git ls-files --error-unmatch "pnpm-lock.yaml" >/dev/null 2>&1 && score=$((score + 2))
    elif [ -f "gradle.lockfile" ]; then
        score=$((score + 5))
    fi
    
    # Dependabot (3 points)
    [ -f ".github/dependabot.yml" ] && score=$((score + 3))
    
    # Check for outdated indicators (Vue)
    if [ "$PROJECT_TYPE" = "vue" ]; then
        # Check for very old versions (rough heuristic)
        grep -q '"vue": "\^2\.' package.json 2>/dev/null && score=$((score - 3))  # Vue 2 penalty
    fi
    
    [ "$score" -lt 0 ] && score=0
    [ "$score" -gt "$DEPS_WEIGHT" ] && score=$DEPS_WEIGHT
    echo "$score"
}

# ============================================================================
# OBSERVABILITY SCORING (10 points)
# ============================================================================
score_observability() {
    local score=0
    
    case "$PROJECT_TYPE" in
        kotlin|kotlin-axon)
            # Logging setup (4 points)
            if [ -f "src/main/resources/logback-spring.xml" ]; then
                score=$((score + 1))
                # JSON encoder
                grep -q "LogstashEncoder\|JsonEncoder" src/main/resources/logback-spring.xml 2>/dev/null && score=$((score + 2))
                # OpenTelemetry appender
                grep -q "OpenTelemetryAppender" src/main/resources/logback-spring.xml 2>/dev/null && score=$((score + 1))
            fi
            
            # Metrics setup (3 points)
            if grep -q "micrometer" build.gradle.kts 2>/dev/null; then
                score=$((score + 2))
                grep -q "prometheus" src/main/resources/application.yml 2>/dev/null && score=$((score + 1))
            fi
            
            # Tracing setup (3 points)
            if grep -q "opentelemetry" build.gradle.kts 2>/dev/null; then
                score=$((score + 2))
                grep -q "opentelemetry-instrumentation" build.gradle.kts 2>/dev/null && score=$((score + 1))
            fi
            ;;
        vue)
            # Frontend observability (10 points max)
            # Check for observability package (5 points)
            grep -q "@pax8/observability" package.json 2>/dev/null && score=$((score + 5))
            
            # Check for no-console ESLint rule (5 points)
            grep -rq "no-console" .eslintrc* 2>/dev/null && score=$((score + 5))
            ;;
        *)
            # Default: check for basic logging
            find . -name "logback*.xml" -o -name "log4j*.xml" 2>/dev/null | grep -q . && score=5
            ;;
    esac
    
    [ "$score" -gt "$OBSERVABILITY_WEIGHT" ] && score=$OBSERVABILITY_WEIGHT
    echo "$score"
}

# ============================================================================
# MAIN SCORING
# ============================================================================

echo ""
echo -e "${BLUE}══════════════════════════════════════════${NC}"
echo -e "${BLUE}  CODEBASE SCORE: ${YELLOW}$REPO_NAME${NC}"
echo -e "${BLUE}  Project Type: ${NC}$PROJECT_TYPE"
echo -e "${BLUE}══════════════════════════════════════════${NC}"
echo ""

# Calculate scores
ARCH_SCORE=$(score_architecture)
TEST_SCORE=$(score_testing)
SEC_SCORE=$(score_security)
QUAL_SCORE=$(score_quality)
DOCS_SCORE=$(score_documentation)
CONS_SCORE=$(score_consistency)
DEPS_SCORE=$(score_dependencies)
OBS_SCORE=$(score_observability)

# Display results
printf "  Architecture:    %2d/%-2d  " "$ARCH_SCORE" "$ARCH_WEIGHT"
progress_bar "$ARCH_SCORE" "$ARCH_WEIGHT"
echo ""

printf "  Testing:         %2d/%-2d  " "$TEST_SCORE" "$TEST_WEIGHT"
progress_bar "$TEST_SCORE" "$TEST_WEIGHT"
echo ""

printf "  Security:        %2d/%-2d  " "$SEC_SCORE" "$SECURITY_WEIGHT"
progress_bar "$SEC_SCORE" "$SECURITY_WEIGHT"
echo ""

printf "  Code Quality:    %2d/%-2d  " "$QUAL_SCORE" "$QUALITY_WEIGHT"
progress_bar "$QUAL_SCORE" "$QUALITY_WEIGHT"
echo ""

printf "  Documentation:   %2d/%-2d  " "$DOCS_SCORE" "$DOCS_WEIGHT"
progress_bar "$DOCS_SCORE" "$DOCS_WEIGHT"
echo ""

printf "  Consistency:     %2d/%-2d  " "$CONS_SCORE" "$CONSISTENCY_WEIGHT"
progress_bar "$CONS_SCORE" "$CONSISTENCY_WEIGHT"
echo ""

printf "  Dependencies:    %2d/%-2d  " "$DEPS_SCORE" "$DEPS_WEIGHT"
progress_bar "$DEPS_SCORE" "$DEPS_WEIGHT"
echo ""

printf "  Observability:   %2d/%-2d  " "$OBS_SCORE" "$OBSERVABILITY_WEIGHT"
progress_bar "$OBS_SCORE" "$OBSERVABILITY_WEIGHT"
echo ""

# Calculate total
TOTAL=$((ARCH_SCORE + TEST_SCORE + SEC_SCORE + QUAL_SCORE + DOCS_SCORE + CONS_SCORE + DEPS_SCORE + OBS_SCORE))

echo ""
echo -e "${BLUE}══════════════════════════════════════════${NC}"

# Color code the total
if [ "$TOTAL" -ge 80 ]; then
    COLOR=$GREEN
elif [ "$TOTAL" -ge 60 ]; then
    COLOR=$YELLOW
else
    COLOR=$RED
fi

printf "  ${COLOR}TOTAL:           %3d/100${NC}\n" "$TOTAL"
echo -e "${BLUE}══════════════════════════════════════════${NC}"
echo ""

# Generate report file
REPORT_DIR="$(dirname "$0")/reports"
mkdir -p "$REPORT_DIR"
REPORT_FILE="$REPORT_DIR/${REPO_NAME}-$(date +%Y%m%d).md"

# Helper function for status indicator
get_status() {
    local score=$1
    local max=$2
    local pct=$((score * 100 / max))
    if [ "$pct" -ge 87 ]; then
        echo "Excellent"
    elif [ "$pct" -ge 67 ]; then
        echo "Good"
    elif [ "$pct" -ge 50 ]; then
        echo "Needs Work"
    else
        echo "Critical"
    fi
}

get_priority() {
    local score=$1
    local max=$2
    local pct=$((score * 100 / max))
    if [ "$pct" -ge 87 ]; then
        echo "-"
    elif [ "$pct" -ge 67 ]; then
        echo "Low"
    elif [ "$pct" -ge 50 ]; then
        echo "Medium"
    else
        echo "High"
    fi
}

# Find previous report for comparison
PREV_REPORT=$(ls -t "$REPORT_DIR/${REPO_NAME}"-*.md 2>/dev/null | grep -v "$(date +%Y%m%d)" | head -1)
PREV_SCORE=""
PREV_DATE=""
if [ -n "$PREV_REPORT" ] && [ -f "$PREV_REPORT" ]; then
    PREV_SCORE=$(grep "Total Score:" "$PREV_REPORT" | grep -oE '[0-9]+/100' | cut -d'/' -f1)
    PREV_DATE=$(grep "Date:" "$PREV_REPORT" | head -1 | sed 's/.*Date:[[:space:]]*//' | tr -d '*')
fi

# Calculate change
CHANGE_TEXT="baseline"
if [ -n "$PREV_SCORE" ]; then
    DIFF=$((TOTAL - PREV_SCORE))
    if [ "$DIFF" -gt 0 ]; then
        CHANGE_TEXT="+$DIFF"
    elif [ "$DIFF" -lt 0 ]; then
        CHANGE_TEXT="$DIFF"
    else
        CHANGE_TEXT="no change"
    fi
fi

# Build visual score bar
FILLED=$((TOTAL / 10))
EMPTY=$((10 - FILLED))
SCORE_BAR=$(printf "%${FILLED}s" | tr ' ' '█')$(printf "%${EMPTY}s" | tr ' ' '░')

# Categorize scores
EXCELLENT=""
GOOD=""
NEEDS_WORK=""
CRITICAL=""

[ "$(get_status $ARCH_SCORE $ARCH_WEIGHT)" = "Excellent" ] && EXCELLENT="$EXCELLENT Architecture,"
[ "$(get_status $ARCH_SCORE $ARCH_WEIGHT)" = "Good" ] && GOOD="$GOOD Architecture,"
[ "$(get_status $ARCH_SCORE $ARCH_WEIGHT)" = "Needs Work" ] && NEEDS_WORK="$NEEDS_WORK Architecture,"
[ "$(get_status $ARCH_SCORE $ARCH_WEIGHT)" = "Critical" ] && CRITICAL="$CRITICAL Architecture,"

[ "$(get_status $TEST_SCORE $TEST_WEIGHT)" = "Excellent" ] && EXCELLENT="$EXCELLENT Testing,"
[ "$(get_status $TEST_SCORE $TEST_WEIGHT)" = "Good" ] && GOOD="$GOOD Testing,"
[ "$(get_status $TEST_SCORE $TEST_WEIGHT)" = "Needs Work" ] && NEEDS_WORK="$NEEDS_WORK Testing,"
[ "$(get_status $TEST_SCORE $TEST_WEIGHT)" = "Critical" ] && CRITICAL="$CRITICAL Testing,"

[ "$(get_status $SEC_SCORE $SECURITY_WEIGHT)" = "Excellent" ] && EXCELLENT="$EXCELLENT Security,"
[ "$(get_status $SEC_SCORE $SECURITY_WEIGHT)" = "Good" ] && GOOD="$GOOD Security,"
[ "$(get_status $SEC_SCORE $SECURITY_WEIGHT)" = "Needs Work" ] && NEEDS_WORK="$NEEDS_WORK Security,"
[ "$(get_status $SEC_SCORE $SECURITY_WEIGHT)" = "Critical" ] && CRITICAL="$CRITICAL Security,"

[ "$(get_status $QUAL_SCORE $QUALITY_WEIGHT)" = "Excellent" ] && EXCELLENT="$EXCELLENT Code Quality,"
[ "$(get_status $QUAL_SCORE $QUALITY_WEIGHT)" = "Good" ] && GOOD="$GOOD Code Quality,"
[ "$(get_status $QUAL_SCORE $QUALITY_WEIGHT)" = "Needs Work" ] && NEEDS_WORK="$NEEDS_WORK Code Quality,"
[ "$(get_status $QUAL_SCORE $QUALITY_WEIGHT)" = "Critical" ] && CRITICAL="$CRITICAL Code Quality,"

[ "$(get_status $DOCS_SCORE $DOCS_WEIGHT)" = "Excellent" ] && EXCELLENT="$EXCELLENT Documentation,"
[ "$(get_status $DOCS_SCORE $DOCS_WEIGHT)" = "Good" ] && GOOD="$GOOD Documentation,"
[ "$(get_status $DOCS_SCORE $DOCS_WEIGHT)" = "Needs Work" ] && NEEDS_WORK="$NEEDS_WORK Documentation,"
[ "$(get_status $DOCS_SCORE $DOCS_WEIGHT)" = "Critical" ] && CRITICAL="$CRITICAL Documentation,"

[ "$(get_status $CONS_SCORE $CONSISTENCY_WEIGHT)" = "Excellent" ] && EXCELLENT="$EXCELLENT Consistency,"
[ "$(get_status $CONS_SCORE $CONSISTENCY_WEIGHT)" = "Good" ] && GOOD="$GOOD Consistency,"
[ "$(get_status $CONS_SCORE $CONSISTENCY_WEIGHT)" = "Needs Work" ] && NEEDS_WORK="$NEEDS_WORK Consistency,"
[ "$(get_status $CONS_SCORE $CONSISTENCY_WEIGHT)" = "Critical" ] && CRITICAL="$CRITICAL Consistency,"

[ "$(get_status $DEPS_SCORE $DEPS_WEIGHT)" = "Excellent" ] && EXCELLENT="$EXCELLENT Dependencies,"
[ "$(get_status $DEPS_SCORE $DEPS_WEIGHT)" = "Good" ] && GOOD="$GOOD Dependencies,"
[ "$(get_status $DEPS_SCORE $DEPS_WEIGHT)" = "Needs Work" ] && NEEDS_WORK="$NEEDS_WORK Dependencies,"
[ "$(get_status $DEPS_SCORE $DEPS_WEIGHT)" = "Critical" ] && CRITICAL="$CRITICAL Dependencies,"

[ "$(get_status $OBS_SCORE $OBSERVABILITY_WEIGHT)" = "Excellent" ] && EXCELLENT="$EXCELLENT Observability,"
[ "$(get_status $OBS_SCORE $OBSERVABILITY_WEIGHT)" = "Good" ] && GOOD="$GOOD Observability,"
[ "$(get_status $OBS_SCORE $OBSERVABILITY_WEIGHT)" = "Needs Work" ] && NEEDS_WORK="$NEEDS_WORK Observability,"
[ "$(get_status $OBS_SCORE $OBSERVABILITY_WEIGHT)" = "Critical" ] && CRITICAL="$CRITICAL Observability,"

# Trim trailing commas
EXCELLENT=$(echo "$EXCELLENT" | sed 's/,$//')
GOOD=$(echo "$GOOD" | sed 's/,$//')
NEEDS_WORK=$(echo "$NEEDS_WORK" | sed 's/,$//')
CRITICAL=$(echo "$CRITICAL" | sed 's/,$//')

cat > "$REPORT_FILE" << EOF
# Score Report: $REPO_NAME

**Date:** $(date +%Y-%m-%d)
**Project Type:** $PROJECT_TYPE
**Total Score:** $TOTAL/100  $SCORE_BAR

## Score Summary

$([ -n "$EXCELLENT" ] && echo "**Excellent (87-100%):** $EXCELLENT")
$([ -n "$GOOD" ] && echo "**Good (67-86%):** $GOOD")
$([ -n "$NEEDS_WORK" ] && echo "**Needs Work (50-66%):** $NEEDS_WORK")
$([ -n "$CRITICAL" ] && echo "**Critical (<50%):** $CRITICAL")

## Category Breakdown

| Category | Score | Status | Priority |
|----------|-------|--------|----------|
| Architecture | $ARCH_SCORE/$ARCH_WEIGHT | $(get_status $ARCH_SCORE $ARCH_WEIGHT) | $(get_priority $ARCH_SCORE $ARCH_WEIGHT) |
| Testing | $TEST_SCORE/$TEST_WEIGHT | $(get_status $TEST_SCORE $TEST_WEIGHT) | $(get_priority $TEST_SCORE $TEST_WEIGHT) |
| Security | $SEC_SCORE/$SECURITY_WEIGHT | $(get_status $SEC_SCORE $SECURITY_WEIGHT) | $(get_priority $SEC_SCORE $SECURITY_WEIGHT) |
| Code Quality | $QUAL_SCORE/$QUALITY_WEIGHT | $(get_status $QUAL_SCORE $QUALITY_WEIGHT) | $(get_priority $QUAL_SCORE $QUALITY_WEIGHT) |
| Documentation | $DOCS_SCORE/$DOCS_WEIGHT | $(get_status $DOCS_SCORE $DOCS_WEIGHT) | $(get_priority $DOCS_SCORE $DOCS_WEIGHT) |
| Consistency | $CONS_SCORE/$CONSISTENCY_WEIGHT | $(get_status $CONS_SCORE $CONSISTENCY_WEIGHT) | $(get_priority $CONS_SCORE $CONSISTENCY_WEIGHT) |
| Dependencies | $DEPS_SCORE/$DEPS_WEIGHT | $(get_status $DEPS_SCORE $DEPS_WEIGHT) | $(get_priority $DEPS_SCORE $DEPS_WEIGHT) |
| Observability | $OBS_SCORE/$OBSERVABILITY_WEIGHT | $(get_status $OBS_SCORE $OBSERVABILITY_WEIGHT) | $(get_priority $OBS_SCORE $OBSERVABILITY_WEIGHT) |

## Comparison to Previous Score

| Metric | Previous | Current | Change |
|--------|----------|---------|--------|
| Total | ${PREV_SCORE:-N/A} | $TOTAL | $CHANGE_TEXT |
| Date | ${PREV_DATE:-N/A} | $(date +%Y-%m-%d) | - |

## Top Recommendations

$([ "$(get_priority $DOCS_SCORE $DOCS_WEIGHT)" = "High" ] && echo "1. **[HIGH] Documentation:** Add comprehensive README with setup instructions and architecture overview. Consider adding ADRs for key decisions.")
$([ "$(get_priority $DOCS_SCORE $DOCS_WEIGHT)" = "Medium" ] && echo "1. **[MEDIUM] Documentation:** Improve README sections and consider adding ADRs.")
$([ "$(get_priority $ARCH_SCORE $ARCH_WEIGHT)" = "High" ] && echo "2. **[HIGH] Architecture:** Review package structure and ensure proper separation of concerns. Reference the golden path documentation.")
$([ "$(get_priority $ARCH_SCORE $ARCH_WEIGHT)" = "Medium" ] && echo "2. **[MEDIUM] Architecture:** Minor structural improvements recommended.")
$([ "$(get_priority $TEST_SCORE $TEST_WEIGHT)" = "High" ] && echo "3. **[HIGH] Testing:** Significantly increase test coverage. Add integration tests for critical paths.")
$([ "$(get_priority $TEST_SCORE $TEST_WEIGHT)" = "Medium" ] && echo "3. **[MEDIUM] Testing:** Add more tests for edge cases and error scenarios.")
$([ "$(get_priority $SEC_SCORE $SECURITY_WEIGHT)" = "High" ] && echo "4. **[HIGH] Security:** Review for hardcoded secrets and ensure input validation on all endpoints.")
$([ "$(get_priority $SEC_SCORE $SECURITY_WEIGHT)" = "Medium" ] && echo "4. **[MEDIUM] Security:** Review input validation coverage.")
$([ "$(get_priority $QUAL_SCORE $QUALITY_WEIGHT)" = "High" ] && echo "5. **[HIGH] Code Quality:** Configure and enforce linting. Address complexity issues.")
$([ "$(get_priority $QUAL_SCORE $QUALITY_WEIGHT)" = "Medium" ] && echo "5. **[MEDIUM] Code Quality:** Review long files and consider refactoring.")
$([ "$(get_priority $CONS_SCORE $CONSISTENCY_WEIGHT)" = "High" ] && echo "6. **[HIGH] Consistency:** Standardize patterns across the codebase. Reference golden path for guidance.")
$([ "$(get_priority $CONS_SCORE $CONSISTENCY_WEIGHT)" = "Medium" ] && echo "6. **[MEDIUM] Consistency:** Minor pattern inconsistencies to address.")
$([ "$(get_priority $DEPS_SCORE $DEPS_WEIGHT)" = "High" ] && echo "7. **[HIGH] Dependencies:** Configure Dependabot and address outdated/vulnerable dependencies.")
$([ "$(get_priority $DEPS_SCORE $DEPS_WEIGHT)" = "Medium" ] && echo "7. **[MEDIUM] Dependencies:** Review and update outdated packages.")
$([ "$(get_priority $OBS_SCORE $OBSERVABILITY_WEIGHT)" = "High" ] && echo "8. **[HIGH] Observability:** Add structured logging, metrics, and tracing. See observability criteria for setup guide.")
$([ "$(get_priority $OBS_SCORE $OBSERVABILITY_WEIGHT)" = "Medium" ] && echo "8. **[MEDIUM] Observability:** Review logging coverage and add OpenTelemetry integration.")

## Scoring Criteria Reference

For detailed scoring rubrics, see:
- [Architecture Criteria](../criteria/architecture.md)
- [Testing Criteria](../criteria/testing.md)
- [Security Criteria](../criteria/security.md)
- [Code Quality Criteria](../criteria/code-quality.md)
- [Documentation Criteria](../criteria/documentation.md)
- [Consistency Criteria](../criteria/consistency.md)
- [Dependencies Criteria](../criteria/dependencies.md)
- [Observability Criteria](../criteria/observability.md)
EOF

echo -e "Report saved to: ${BLUE}$REPORT_FILE${NC}"
echo ""
