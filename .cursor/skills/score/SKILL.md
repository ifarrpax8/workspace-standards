---
name: score
description: Score a repository against team standards with interpretation and actionable fix recommendations.
---
# Score Skill

Interactive scoring skill that wraps the codebase scoring script with intelligent interpretation and actionable recommendations. No MCP servers required — uses Shell, Read, and Grep.

## Prerequisites

### Required MCP Servers

None. This skill uses built-in tools only:
- **Shell** — Execute `scoring/score.sh` and capture output
- **Read** — Load reports, criteria files, golden paths, Engineering Codex facets
- **Grep** — Search for patterns in codebase when generating recommendations

### Workspace Context

- **workspace-standards** — Must be in workspace (contains `scoring/`, `golden-paths/`, `scoring/criteria/`)
- **@engineering-codex** — Optional; when present, cross-reference low-scoring categories against relevant facet `best-practices.md`

## When to Use

Use this skill when:
- Evaluating a repository against team standards
- Identifying improvement areas with specific, actionable fixes
- Tracking score trends over time
- Comparing scores across repositories

## When NOT to Use

- **Only assessing tests** — use [Assess Tests](../assess-tests/SKILL.md) for persona-level test completeness analysis
- **Reviewing a specific PR or diff** — use [Code Review](../code-review/SKILL.md)
- **Running a specific checklist** (security, accessibility) — use [Checklist Runner](../checklist-runner/SKILL.md) in engineering-codex
- **Simple one-off question** about repo quality — just investigate directly

## Invocation

```
Score the currency-manager repository
```

```
How does finance-mfe score against our standards?
```

```
Run the scoring script on einvoice-connector
```

## Workflow

### Phase 1: Identify Target

1. **Determine repository to score**
   - If user specifies a repo name (e.g., `currency-manager`, `finance-mfe`): Resolve to full path
   - If user does not specify: Infer from current workspace context (e.g., `workspacePaths` or open file path)
   - If ambiguous: Ask user which repository to score

2. **Resolve repository path**
   - Common patterns: `../currency-manager`, `../../currency-manager`, or sibling of workspace-standards
   - User workspace paths often include repos at `/Users/{user}/Development/{repo-name}`

3. **Verify repository exists**
   - List directory at resolved path
   - If not found: List available repositories (sibling dirs of workspace-standards or from workspace paths) and ask user to choose

4. **Detect project type early**
   - The script detects this, but knowing early helps load the right golden path and criteria context
   - Kotlin: `build.gradle.kts` or `build.gradle` present
   - Kotlin Axon: Kotlin + `axon` in build file
   - Vue: `package.json` with `vue` dependency
   - Terraform: `main.tf` or `terraform/` directory

### Phase 2: Run Score

1. **Execute scoring script**
   ```
   From workspace-standards directory:
   ./scoring/score.sh [absolute-path-to-repo]
   ```

2. **Capture output**
   - Script prints category scores and total to stdout
   - On success, it writes a report to `scoring/reports/{repo-name}-{YYYYMMDD}.md`

3. **Read the generated report**
   - Path: `scoring/reports/{repo-name}-{YYYYMMDD}.md`
   - If script fails: Proceed to Error Handling

### Phase 3: Interpret Results

For each category, interpret the score using the rubric:

| Score Range | Interpretation |
|-------------|----------------|
| 87-100% | Excellent — no action needed |
| 67-86% | Good — minor improvements possible |
| 50-66% | Needs Work — specific actions recommended |
| <50% | Critical — should be prioritised |

Map category names to criteria files:

| Category | Criteria File |
|----------|---------------|
| Architecture | `scoring/criteria/architecture.md` |
| Testing | `scoring/criteria/testing.md` |
| Security | `scoring/criteria/security.md` |
| Code Quality | `scoring/criteria/code-quality.md` |
| Documentation | `scoring/criteria/documentation.md` |
| Consistency | `scoring/criteria/consistency.md` |
| Dependencies | `scoring/criteria/dependencies.md` |
| Observability | `scoring/criteria/observability.md` |

### Phase 4: Generate Actionable Recommendations

For each category scoring below "Good" (67%):

1. **Read the relevant scoring criteria file**
   - Path: `scoring/criteria/{category}.md` (e.g., `architecture.md`)

2. **Read the relevant golden path based on project type**

   | Project Type | Golden Path |
   |--------------|-------------|
   | kotlin | [kotlin-spring-boot.md](../../../golden-paths/kotlin-spring-boot.md) |
   | kotlin-axon | [kotlin-axon-cqrs.md](../../../golden-paths/kotlin-axon-cqrs.md) |
   | vue | [vue-mfe.md](../../../golden-paths/vue-mfe.md) |
   | terraform | [terraform-iac.md](../../../golden-paths/terraform-iac.md) |

3. **If `@engineering-codex` is in the workspace**
   - Map category to a relevant facet (e.g., Architecture → architecture facet, Testing → testing facet)
   - Read `engineering-codex/facets/{facet}/best-practices.md` when a facet aligns with the category
   - **For the Testing category specifically**: Also read `engineering-codex/facets/testing/test-personas.md` and check which persona perspectives are missing from the existing test suite. This surfaces blind spots beyond simple coverage metrics (e.g., "tests exist but no Saboteur or Boundary Walker scenarios").

4. **Produce specific, file-level recommendations**

   Format:

   ```markdown
   ### Architecture (7/13 — Needs Work)

   **What's missing:**
   - No dedicated `validation/` package (expected by golden path)
   - Service layer has 3 files over 500 lines

   **Specific fixes:**
   1. Create `src/main/kotlin/.../validation/` and extract validation logic from services
   2. Refactor `OrderService.kt` (680 lines) — extract `OrderCalculationHelper.kt`
   3. Reference: [Kotlin Spring Boot Golden Path](../../../golden-paths/kotlin-spring-boot.md#layer-responsibilities)
   ```

   Use Grep and Read on the target repository to identify specific files (e.g., long files, missing packages, violations) when generating recommendations.

### Phase 5: Compare to Previous Score

1. **Check for previous reports**
   - List `scoring/reports/` for files matching `{repo-name}-*.md`
   - Sort by date; exclude today's report

2. **If previous report exists**
   - Extract previous total score and date from the report
   - Show trend: improving (+N), declining (-N), stable (no change)
   - Highlight categories that changed significantly (e.g., Architecture 10→13, Documentation 3→2)

3. **If no previous report**
   - Note: "This is the baseline score — no previous report to compare."

### Phase 6: Offer Actions

After presenting the full analysis:

```
What would you like to do?
1. Fix a specific category now — I'll guide you through the changes
2. Run assess-tests for a detailed testing breakdown (if Testing scored below Good)
3. Create tickets for the recommendations
4. Run the score on another repository
5. Save this analysis as a report
```

If the user chooses option 2, hand off to `@workspace-standards/.cursor/skills/assess-tests/SKILL.md` scoped to the scored repository. The assess-tests results provide persona-level detail that complements the score's category-level view.

## Output Format

```markdown
## Score Analysis: [repo-name]

**Date:** [YYYY-MM-DD]
**Project Type:** [kotlin|vue|terraform|...]
**Total Score:** [XX]/100 [visual bar]

### Summary

[Excellent/Good/Needs Work/Critical breakdown by category]

### Trend

[Comparison to previous score, or "Baseline — no previous report"]

### Detailed Recommendations

[For each category below Good: full recommendation block with What's missing, Specific fixes, References]

### Category Breakdown

| Category | Score | Status | Priority |
|----------|-------|--------|----------|
| ... | ... | ... | ... |

---

What would you like to do?
1. Fix a specific category now
2. Run assess-tests for a detailed testing breakdown
3. Create tickets for the recommendations
4. Run the score on another repository
5. Save this analysis as a report
```

## Verification

- **Phase 1 (Target)**: Confirm the repository path exists by listing its contents. If not found, present available repos before proceeding.
- **Phase 2 (Run)**: Check the script's exit code. If non-zero, display stderr and proceed to error handling — do not attempt to interpret partial output.
- **Phase 2 (Report)**: Confirm the report file was written to `scoring/reports/` by checking for its existence before reading.
- **Phase 6 (Jira)**: If creating tickets via Jira MCP, verify each ticket was created by checking the response for an issue key.

## Worked Example

**Input:** `Score the currency-manager repository`

**Key steps:**
1. Resolved path to `/Users/ifarr/Development/currency-manager`. Detected Kotlin Spring Boot project.
2. Ran `./scoring/score.sh /Users/ifarr/Development/currency-manager` — exit code 0
3. Read report: 78/100 total. Architecture 12/13, Testing 8/13 (Needs Work), Security 11/13
4. For Testing: read `scoring/criteria/testing.md` + `engineering-codex/facets/testing/test-personas.md` — found no Saboteur tests for external API calls
5. Previous report (2026-01-15): 72/100 — trending up (+6)

**Output excerpt:**
```markdown
## Score Analysis: currency-manager

**Date:** 2026-02-14
**Project Type:** Kotlin Spring Boot
**Total Score:** 78/100 ████████░░

### Category Breakdown
| Category | Score | Status | Priority |
|----------|-------|--------|----------|
| Architecture | 12/13 | Excellent | — |
| Testing | 8/13 | Needs Work | HIGH |
| Security | 11/13 | Good | — |

### Trend
Previous: 72/100 (2026-01-15) → Current: 78/100 (+6, improving)
```

## Error Handling

### Repository Not Found

- List available repositories (sibling dirs of workspace-standards, or from workspace paths)
- Ask user to specify which repository to score

### score.sh Fails

- Show the error output from the script
- Common fixes:
  - Path does not exist: Verify path; use absolute path
  - Permission denied: Ensure script is executable (`chmod +x scoring/score.sh`)
  - Wrong working directory: Run from workspace-standards root

### No Previous Reports

- Skip comparison phase
- Note: "This is the baseline score."

### Criteria or Golden Path File Missing

- Skip that reference; note in output which resources were unavailable
- Proceed with recommendations from criteria that are available

## Related Resources

- [Scoring Script](../../../scoring/score.sh)
- [Scoring Criteria](../../../scoring/criteria/)
- [Golden Paths](../../../golden-paths/)
- [Assess Tests Skill](../assess-tests/SKILL.md) - Detailed test completeness audit when Testing scores low
