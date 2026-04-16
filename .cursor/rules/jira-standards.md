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

### Jira Cloud API: Atlassian Document Format (ADF)

Jira Cloud’s REST API does **not** accept Jira wiki markup (e.g. `{panel:bgColor=...}`) or plain markdown for every description field. In particular, **`customfield_12636` (Story “Description”) must be sent as an [Atlassian Document Format](https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/) JSON object** — a string or wiki body will return an error such as: `Operation value must be an Atlassian Document`.

**Implications for agents and MCP:**

- Use **`editJiraIssue`** with **`contentFormat`: `adf`** and pass **`fields.description`** and **`fields.customfield_12636`** as the same ADF `doc` object so both stay in sync.
- If a first attempt fails on `customfield_12636`, retry with ADF even when `description` accepted markdown.
- **Fetch before edit:** use **`getJiraIssue`** with **`responseContentFormat`: `adf`** (and the needed `fields`) to read the current `description`, preserve panels, media attachment `id`s, and structure, then merge changes.
- **Coloured panels** in HRZN Story descriptions are ADF **`panel`** nodes (`panelType`: `info` | `note` | `success` for Overview / Refinement Notes / Success Criteria), not wiki `{panel}` macros in the API payload.

**Success Criteria (Gherkin) spacing in ADF**

Sequential **`paragraph`** nodes alone often render as one dense block in the Success Criteria panel. To separate scenarios:

- Insert an ADF **`heading`** with **`level`: 4** before each scenario (e.g. “Scenario 1”, “Scenario 2”), then Given / When / Then as separate paragraphs; or
- Insert **`horizontalRule`** blocks between scenarios if your renderer allows them inside panels.

The Cursor **Atlassian** integration typically exposes **`getJiraIssue`**, **`editJiraIssue`**, **`addCommentToJiraIssue`**, and **`getConfluencePage`** (with `cloudId` from **`getAccessibleAtlassianResources`**). Tool names in skills may differ from older `jira_*` aliases — use the descriptors in the MCP tools folder.

### Canonical payload file (preferred for large Story descriptions)

For **large ADF** bodies, treat a **repo JSON file** as the source of truth, then apply it to Jira:

1. Store `{ "fields": { "description": <ADF doc>, "customfield_12636": <same doc> } }` in a file next to the ticket or ADR (e.g. `HRZN-908-jira-fields.payload.json`).
2. Edit the file in git; review diffs like normal code.
3. Apply with **`curl`** `PUT` and `--data-binary @file.json` (see below), or with **`editJiraIssue`** using the `fields` object from that file. If the combined payload hits **MCP message size limits**, split into two updates: `fields.description` only, then `fields.customfield_12636` only (same `doc` in both).

**Why this pattern:** avoids pasting multi–kilobyte ADF into chat, survives **MCP argument size** constraints, matches the exact **REST** body you would use without an agent, and keeps ticket text **reviewable in PRs**.

**Token / cost:** Jira still receives the same payload bytes on each update. Savings are mainly in the **assistant context**: the large ADF is not re-included in every turn unless you open or paste it. The API itself is not “cheaper” per call.

### REST API direct update (when MCP is unavailable)

Some agent sessions do not expose Atlassian MCP tools. You can still update Story descriptions using **Jira Cloud REST API v3** with the same ADF payload you would send through **`editJiraIssue`**.

| Item | Detail |
|------|--------|
| Endpoint | `PUT https://{site}.atlassian.net/rest/api/3/issue/{issueKey}` |
| Body | `{ "fields": { "description": <ADF doc>, "customfield_12636": <same ADF doc> } }` |
| Auth | **HTTP Basic**: username = Atlassian account **email**, password = **API token** (create at [id.atlassian.com](https://id.atlassian.com/manage-profile/security/api-tokens)) |
| Success | **HTTP 204** with an empty body is normal for this endpoint |
| Errors | **400** with JSON details — e.g. `Operation value must be an Atlassian Document` if `customfield_12636` is a string instead of an ADF object |

**Example (curl):** store the `fields` object in a file (e.g. `issue-fields.payload.json` containing only `{ "fields": { ... } }`), then:

```bash
curl -sS -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
  -X PUT \
  -H "Content-Type: application/json" \
  "https://${JIRA_HOST}/rest/api/3/issue/HRZN-123" \
  --data-binary @issue-fields.payload.json
```

**Security:** Do not commit API tokens. Prefer environment variables or your secret manager. If credentials live in local MCP config (e.g. `~/.cursor/mcp.json`), treat that file as sensitive and rotate tokens if it may have been exposed.

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
