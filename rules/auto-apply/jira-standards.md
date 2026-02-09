# Jira Ticket Standards

## Custom Description Fields

When interacting with Jira tickets in the HRZN project (Finance Enablement), use the **custom description fields** instead of the standard description field. Different issue types use different custom fields.

### Field Details by Issue Type

| Issue Type | Field ID | Field Name | Template |
|------------|----------|------------|----------|
| **Story** | `customfield_12636` | "Description" | Overview / Refinement Notes / Success Criteria |
| **Spike** | `customfield_14303` | "Spike Description" | Questions / Hypothesis / Research / Summary / Recommendation |
| **Epic** | `customfield_12637` | "Epic Description" | Problem / Goal / PRD Link / Requirements |

### Why Two Description Fields?

Pax8 Jira has two "Description" fields:
1. **Standard `description`** - Built-in Jira field
2. **Custom field** - Issue-type-specific custom field (see table above) - **USED by business**

The business uses the custom field because it integrates with their ticket templates and workflows. However, the MCP tool writes to both fields when using `additional_fields`, so **both fields should be kept in sync** with the same content.

### How to Update

When using the `jira_update_issue` MCP tool, pass the content via **both** `fields` and `additional_fields` to keep them in sync:

```json
{
  "issue_key": "HRZN-123",
  "fields": {
    "description": "{panel:bgColor=#deebff}\n*Overview*\n\n...\n{panel}\n\n{panel:bgColor=#eae6ff}\n*Refinement Notes*\n\n...\n{panel}\n\n{panel:bgColor=#e3fcef}\n*Success Criteria*\n\n...\n{panel}"
  },
  "additional_fields": {
    "customfield_12636": "{panel:bgColor=#deebff}\n*Overview*\n\n...\n{panel}\n\n{panel:bgColor=#eae6ff}\n*Refinement Notes*\n\n...\n{panel}\n\n{panel:bgColor=#e3fcef}\n*Success Criteria*\n\n...\n{panel}"
  }
}
```

> **Note:** The MCP tool may automatically sync both fields. Verify after updates that both `description` and the custom field contain matching content.

### Template Format

The business uses a structured template with colored panels:

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

### Panel Colors (Stories)

| Panel | Color | Hex | Purpose |
|-------|-------|-----|---------|
| Overview | Blue | `#deebff` | High-level description |
| Refinement Notes | Purple | `#eae6ff` | Technical details |
| Success Criteria | Green | `#e3fcef` | Acceptance criteria |

---

## Spike Template (`customfield_14303`)

Spikes use a different custom field with a different structure:

### How to Update Spikes

```json
{
  "issue_key": "HRZN-123",
  "fields": {
    "description": "*Questions:*\n# Question 1\n..."
  },
  "additional_fields": {
    "customfield_14303": "*Questions:*\n# Question 1\n..."
  }
}
```

> **Note:** Pass the same content to both `fields.description` and `additional_fields.customfield_14303` to keep them in sync.

### Spike Template Format

```
*Questions:*
# First question to investigate
# Second question to investigate

*Hypothesis:*
[What we expect to find or confirm]

*Research:*
[Detailed findings, tables, code examples, etc.]

*Summary:*
[Brief summary of key findings]

*Recommendation:*
[Suggested next steps or approach]
```

---

### Reading Tickets

When reading Jira tickets, fetch the custom field to see the business content:

```
fields: "customfield_12636,summary,status,..."
```

Or use `fields: "*all"` to get all fields including custom ones.

### Other Custom Fields of Interest

| Field ID | Name | Purpose |
|----------|------|---------|
| `customfield_12637` | Epic Description | Similar template for Epics |
| `customfield_10057` | (Legacy template) | Old format: Overview + Acceptance Criteria |
| `customfield_10055` | Bug template | Bug-specific format |
