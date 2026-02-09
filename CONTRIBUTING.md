# Contributing to Workspace Standards

Guidelines for adding and maintaining rules, skills, golden paths, and scoring criteria.

## Directory Conventions

| Content Type | Location | Format |
|-------------|----------|--------|
| Cursor Skills | `skills/{skill-name}/SKILL.md` | Markdown with structured phases |
| Auto-apply Rules | `rules/auto-apply/{name}-standards.md` | YAML frontmatter + concise directives |
| Manual Rules | `rules/{name}.md` | Markdown with checklists |
| Golden Paths | `golden-paths/{stack-name}.md` | Markdown with code examples |
| Scoring Criteria | `scoring/criteria/{category}.md` | Markdown with rubric tables |
| Patterns | `patterns/{name}.md` | Markdown with analysis tables |

## Adding a Skill

Skills are interactive Cursor workflows invoked with `@workspace-standards/skills/{name}/SKILL.md`.

### Required Structure

Every skill must include these sections in order:

1. **Title** — `# {Skill Name} Skill`
2. **Description** — One-sentence summary
3. **Prerequisites** — MCP server table with Required? column, graceful degradation
4. **When to Use** — Bullet list of use cases
5. **Invocation** — Code blocks showing example invocations
6. **Workflow** — Numbered phases with clear inputs, actions, and outputs
7. **Output Format** — Template for the skill's deliverable
8. **Error Handling** — How to degrade when tools are unavailable
9. **Related Resources** — Links to related skills, rules, and golden paths

### Conventions

- Use `AskQuestion` for structured user input at decision points
- Include graceful degradation for every MCP dependency
- Reference golden paths and auto-apply rules where relevant
- If the Engineering Codex may be available, include codex integration with fallback
- Include a checkpoint between major phases where the user can pause or redirect

## Adding an Auto-Apply Rule

Auto-apply rules are copied to individual repositories' `.cursor/rules/` directories.

### Required Format

```yaml
---
description: Brief description of what this rule covers
globs: ["*.ext", "pattern/**/*.ext"]
alwaysApply: false
---
```

### Conventions

- Keep rules concise and directive — short bullets, not long explanations
- Group rules by concern (structure, naming, security, testing, etc.)
- Reference the relevant golden path at the bottom
- Use `alwaysApply: false` unless the rule applies to every file type
- Match the `globs` pattern to the specific file types the rule governs

## Adding a Golden Path

Golden paths are reference architectures that define the expected structure and patterns for a project type.

### Required Structure

1. **Title** — `# Golden Path: {Stack/Pattern Name}`
2. **Description** — One line
3. **Use when** / **Reference implementations** — When to apply, which repos follow it
4. **Package Structure** — Directory tree with annotations
5. **Layer Responsibilities** — Each layer with code examples and rules
6. **Configuration** — Key config files and patterns
7. **Testing Strategy** — Test types with code examples
8. **Common Patterns** — Frequently used patterns with code examples
9. **Checklist** — Pre-completion verification

### Conventions

- Include real code examples (not pseudocode) in the project's language
- Do not add code comments
- Reference specific files from existing repositories where possible
- End with a checklist of items to verify before completing work

## Adding Scoring Criteria

Scoring criteria define how `score.sh` evaluates repositories.

### Conventions

- Each criterion file explains what is checked and how it's scored
- Include the point breakdown (what earns full marks vs partial)
- Reference the golden path that addresses each check
- If adding a new category, update `score.sh` weights and the README scoring table

## General Conventions

- **No code comments** — Keep examples clean
- **Concise language** — Directive tone, not academic
- **Cross-reference** — Link to related content within the repo
- **Test your changes** — Run `score.sh` if you modified scoring, invoke skills if you modified skills
- **Update the CHANGELOG** — Add an entry for any structural change, new content, or fix
- **Update the README** — If adding new skills, rules, golden paths, or scoring categories
