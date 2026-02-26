# Agent Routing

On-demand lookup table mapping user tasks to the files an agent should read. Skills reference this file in their workflow steps -- it is not loaded automatically.

## Task Routing

| When the user... | Read these files | Complexity |
|------------------|-----------------|------------|
| Asks to refine a Jira ticket | `.cursor/skills/refine-ticket/SKILL.md`, `.cursor/rules/jira-standards.md` | low |
| Asks to implement a ticket | `.cursor/skills/implement-ticket/SKILL.md`, relevant golden path from `golden-paths/` | low |
| Asks to review a PR or local changes | `.cursor/skills/code-review/SKILL.md`, `.cursor/rules/code-review.md` | low |
| Asks to generate a PR description | `.cursor/skills/generate-pr-description/SKILL.md` | low |
| Asks to fix a bug | `.cursor/skills/fix-bug/SKILL.md` | low |
| Asks to run a spike | `.cursor/skills/spike/SKILL.md` | high |
| Asks to assess test coverage | `.cursor/skills/assess-tests/SKILL.md` | high |
| Asks to generate an ADR | `.cursor/skills/generate-adr/SKILL.md` | high |
| Asks to score a repository | `.cursor/skills/score/SKILL.md`, `scoring/criteria/` | low |
| Asks to do a technical deep dive | `.cursor/skills/technical-deep-dive/SKILL.md` | high |
| Asks to generate an Opportunity Brief | `.cursor/skills/generate-opportunity-brief/SKILL.md` | high |
| Asks to generate a PRD | `.cursor/skills/generate-prd/SKILL.md` | high |
| Asks to run the full idea-to-implementation pipeline | `.cursor/skills/idea-to-implementation/SKILL.md` | high |
| Asks to do a post-implementation review | `.cursor/skills/post-implementation-review/SKILL.md` | low |
| Asks to generate API migration tests | `.cursor/skills/api-migration-test/SKILL.md` | low |
| Asks about Kotlin/Spring Boot patterns | `golden-paths/kotlin-spring-boot.md`, `.cursor/rules/kotlin-standards.md` | low |
| Asks about Axon/CQRS patterns | `golden-paths/kotlin-axon-cqrs.md`, `.cursor/rules/kotlin-standards.md` | low |
| Asks about Vue/MFE patterns | `golden-paths/vue-mfe.md`, `.cursor/rules/vue-standards.md` | low |
| Asks about Groovy monolith patterns | `golden-paths/groovy-monolith.md`, `.cursor/rules/groovy-standards.md` | low |
| Asks about Terraform patterns | `golden-paths/terraform-iac.md`, `.cursor/rules/terraform-standards.md` | low |
| Asks about E2E/Playwright patterns | `golden-paths/integration-testing.md`, `.cursor/rules/playwright-standards.md` | low |
