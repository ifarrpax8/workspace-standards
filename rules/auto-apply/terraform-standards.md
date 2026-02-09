---
description: Standards for Terraform Infrastructure as Code
globs: ["*.tf", "*.tfvars", "*.hcl"]
alwaysApply: false
---

# Terraform Standards

Follow these standards when writing Terraform Infrastructure as Code.

## File Naming

- `main.tf` — primary resources
- `variables.tf` — input variables
- `outputs.tf` — output values
- `providers.tf` — provider configuration
- `backend.tf` — remote backend configuration

## Variables

- All variables must have `description` and `type`
- Use `validation` blocks for constraints (allowed values, length, regex)
- No hardcoded values in resources — use variables or locals

## Outputs

- All outputs must have `description`
- Mark sensitive outputs with `sensitive = true`

## Resource Naming

- Use `{environment}-{project}-{resource}` pattern
- Example: `prod-finance-s3-bucket`

## Loops and Iteration

- Prefer `for_each` over `count` for named resources
- Use `for_each` with maps for dynamic resource sets

## State

- Remote backend required (S3, GCS, or Azure)
- Never commit `.tfstate` files

## Module Structure

```
modules/
  {module-name}/
    main.tf
    variables.tf
    outputs.tf
environments/
  {env}/
    main.tf
    terraform.tfvars
```

## Lifecycle

- Use `prevent_destroy = true` on critical resources
- Consider `create_before_destroy` for zero-downtime updates

## Golden Path

Reference: `@workspace-standards/golden-paths/terraform-iac.md`
