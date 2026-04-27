---
description: Jira ticket standards for the HRZN project — description templates, panel format, and ADF tool usage
alwaysApply: false
type: "manual"
---
# Jira Ticket Standards

## Description Templates

HRZN uses structured panel templates in the native `description` field.

### Story

```
{panel:bgColor=#deebff}
*Overview*

[Brief description of what the ticket is about]
{panel}

{panel:bgColor=#eae6ff}
*Refinement Notes*

[Technical details, implementation notes, questions]
{panel}

{panel:bgColor=#e3fcef}
*Success Criteria*

[Acceptance criteria in Given/When/Then format]
{panel}
```

| Panel | Hex | Purpose |
|-------|-----|---------|
| Overview | `#deebff` (blue) | High-level description |
| Refinement Notes | `#eae6ff` (purple) | Technical details |
| Success Criteria | `#e3fcef` (green) | Acceptance criteria |

### Spike

```
*Questions:*
# First question to investigate

*Hypothesis:*
[What we expect to find or confirm]

*Research:*
[Detailed findings, tables, code examples, etc.]

*Summary:*
[Brief summary of key findings]

*Recommendation:*
[Suggested next steps or approach]
```

### Epic

Structure: Problem / Goal / PRD Link / Requirements.

---

## ADF — Atlassian Document Format

Jira Cloud's REST API requires the `description` field as **ADF JSON** — wiki markup (`{panel:...}`) and plain markdown are rejected with `Operation value must be an Atlassian Document`.

### Via Atlassian MCP tools

```
Read:  getJiraIssue     → responseContentFormat: adf
Write: editJiraIssue    → contentFormat: adf, fields.description: <ADF doc>
```

Always fetch before editing — the ADF response preserves existing panel structure, media attachment IDs, and inline content that would be lost if you write from scratch.

### Via Jira REST API v3 (no MCP)

```
PUT https://{site}.atlassian.net/rest/api/3/issue/{key}
Authorization: Basic <base64(email:api-token)>
Content-Type: application/json

{ "fields": { "description": <ADF doc> } }
```

HTTP 204 (empty body) is the success response. HTTP 400 with `Operation value must be an Atlassian Document` means the payload was not valid ADF.
