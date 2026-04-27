# Skill Template

Use this template when creating a new skill. Copy it to `.cursor/skills/<name>/SKILL.md` and fill in each section.

## Cross-Tooling Discovery

Skills placed in `.cursor/skills/<name>/SKILL.md` are the canonical source. The following symlinks make them available to each tool:

| Tool | Discovery path | How to add |
|------|---------------|------------|
| **Cursor** | `.cursor/skills/<name>/` (native) | No action needed |
| **Claude Code** | `.claude/skills/<name>/` → `../.cursor/skills/<name>` | Run `sync-skills.sh` at workspace root |
| **Augment** | `.agents/skills/<name>/` → `../.cursor/skills/<name>` | Symlink in repo; run `sync-skills.sh` for workspace-level |

Skills are **on-demand** in all three tools — they are not loaded into context automatically. Invoke them explicitly (e.g. `/skill-name` in Cursor, the `Skill` tool in Claude Code, `@skill-name` in Augment).

For rules (always-on or auto-applied context), see the rule template in `CONTRIBUTING.md`.

---

```markdown
---
name: skill-name
description: 15-20 word description used by Cursor for routing. Be specific about when to invoke.
---
# Skill Name

One-sentence summary of what this skill does.

## Prerequisites

### Required MCP Servers

| MCP Server | Tools Used | Purpose | Required? |
|------------|------------|---------|-----------|
| **user-mcp-atlassian** | `jira_get_issue` | [Purpose] | Optional |

### Graceful Degradation

- **No [MCP]**: [What happens, how the skill adapts]

## When to Use

- [Scenario 1]
- [Scenario 2]

## When NOT to Use

- **[Alternative scenario]** — use [Other Skill](../other-skill/SKILL.md) instead
- **[Another scenario]** — just do it directly without a structured workflow

## Invocation

\`\`\`
Example invocation 1
\`\`\`

\`\`\`
Example invocation 2
\`\`\`

## Workflow

### Phase 1: [Name]

[Steps for this phase]

### Phase 2: [Name]

[Steps for this phase]

## Verification

After each critical operation, verify success:

- **Phase 1**: [What to verify and how]
- **Phase 2**: [What to verify and how]

## Worked Example

**Input:** `[Realistic example invocation]`

**Key steps:**
1. [What happened]
2. [What happened]
3. [What happened]

**Output excerpt:**
\`\`\`markdown
[Condensed version of the real output format]
\`\`\`

## Error Handling

### [Error Scenario]

[How to handle it]

## Related Resources

- [Related Skill](../related-skill/SKILL.md) — [Why it's related]
```

## Required Sections

Every skill MUST include:

1. **Frontmatter** — `name` and `description` (15-20 words)
2. **When to Use** — Clear scenarios for invocation
3. **When NOT to Use** — Disambiguation from overlapping skills
4. **Workflow** — Phased steps with clear instructions
5. **Verification** — Checkpoints after operations that can fail silently
6. **Worked Example** — One condensed input-to-output example
7. **Error Handling** — Graceful handling of missing dependencies or failures
