# Golden Path: Terraform Infrastructure as Code

Standard architecture for Terraform-managed infrastructure with reusable modules, environment isolation, and CI/CD integration.

**Use when:** Provisioning cloud resources (AKS, EKS, storage, networking), identity roles, or platform-level configuration.

**Reference implementations:** role-management

---

## Package Structure

```
terraform/
├── modules/                    # Reusable child modules
│   ├── aks-cluster/            # Per-resource or capability
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   └── versions.tf
│   ├── network/
│   └── identity-permissions/
├── environments/               # Directory-per-environment
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   ├── backend.tf
│   │   └── providers.tf
│   ├── nonproduction/
│   ├── staging/
│   └── production/
├── .tflint.hcl
└── README.md
```

---

## Module Structure

### Root Module (Environment)

Each environment directory is a root module that composes child modules.

```hcl
terraform {
  required_version = "~> 1.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

module "aks_cluster" {
  source = "../../modules/aks-cluster"

  cluster_name   = var.cluster_name
  environment    = var.environment
  node_count     = var.node_count
  resource_group = data.azurerm_resource_group.main.name
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}
```

**Rules:**
- One root module per environment directory
- Backend config via `-backend-config` or separate `backend.tf`
- Use variables for all environment-specific values
- Compose modules; avoid inline resource definitions in root

### Child Module Layout

```hcl
# main.tf
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group
  dns_prefix          = "aks-${var.environment}-${var.cluster_name}"

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.node_vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [default_node_pool[0].node_count]
  }
}
```

```hcl
# variables.tf
variable "cluster_name" {
  type        = string
  description = "Name of the AKS cluster"
}

variable "environment" {
  type        = string
  description = "Environment identifier (dev, staging, prod)"
}

variable "resource_group" {
  type        = string
  description = "Resource group name"
}

variable "node_count" {
  type        = number
  default     = 2
  description = "Number of nodes in default node pool"
}

variable "node_vm_size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "VM size for node pool"
}

variable "location" {
  type        = string
  description = "Azure region"
}
```

```hcl
# outputs.tf
output "cluster_id" {
  value       = azurerm_kubernetes_cluster.main.id
  description = "AKS cluster resource ID"
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive = true
}

output "cluster_principal_id" {
  value       = azurerm_kubernetes_cluster.main.identity[0].principal_id
  description = "System-assigned identity principal ID"
}
```

**Rules:**
- `main.tf` for primary resources
- `variables.tf` for input variables with type and description
- `outputs.tf` for values consumed by other modules or root
- Mark sensitive outputs with `sensitive = true`
- Use `versions.tf` for provider requirements in modules

---

## State Management

### Remote Backend (Azure)

```hcl
# backend.tf - use -backend-config for key overrides per environment
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateshared"
    container_name       = "tfstate"
    key                  = "env/project-name.tfstate"
    use_msi              = true
  }
}
```

### Remote Backend (AWS)

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket               = "pax8-terraform-state"
    key                  = "aws/${var.environment}.${var.project_name}.tfstate"
    region               = "us-east-1"
    encrypt              = true
    dynamodb_table       = "terraform-state-lock"
    workspace_key_prefix  = "env"
  }
}
```

**Rules:**
- Always use remote state; never local state in shared environments
- Enable encryption for state at rest
- Use Dynamodb (AWS) or blob lease (Azure) for state locking
- One state file per environment per project
- Use `workspace_key_prefix` when using Terraform workspaces

### Workspace Separation

```hcl
locals {
  env = terraform.workspace == "default" ? "dev" : terraform.workspace
}
```

Prefer directory-per-environment over workspaces for clear separation and distinct backend keys.

---

## Environment Promotion

### Directory-Per-Environment

```
environments/
├── dev/
├── nonproduction/
├── preproduction/
└── production/
```

### tfvars Per Environment

```hcl
# environments/dev/terraform.tfvars
environment         = "dev"
cluster_name        = "pax8-dev-aks"
node_count         = 2
node_vm_size       = "Standard_D2s_v3"
resource_group_name = "rg-pax8-dev"
```

```hcl
# environments/production/terraform.tfvars
environment         = "production"
cluster_name        = "pax8-prod-aks"
node_count         = 5
node_vm_size       = "Standard_D4s_v3"
resource_group_name = "rg-pax8-prod"
```

### Backend Config Override

```bash
terraform init -backend-config="key=env/production/project.tfstate"
```

---

## Naming Conventions

### Resource Naming

```hcl
resource "azurerm_kubernetes_cluster" "main" {
  name = "${var.environment}-${var.project}-aks"
}

resource "aws_eks_cluster" "main" {
  name = "${var.environment}-${var.project}-eks"
}
```

Pattern: `{environment}-{project}-{resource-type}` or `{project}-{resource}-{environment}`

### File Naming

| File         | Purpose                                    |
|--------------|--------------------------------------------|
| main.tf      | Primary resources, module calls           |
| variables.tf | Input variable definitions                 |
| outputs.tf   | Output definitions                         |
| providers.tf | Provider configuration                     |
| backend.tf   | Backend configuration (or in terraform {}) |
| versions.tf  | Required version, required_providers        |
| data.tf      | Data sources (optional grouping)           |
| locals.tf    | Local values (optional grouping)           |
| *.tf         | Domain-specific (e.g. network.tf)          |

---

## Configuration Patterns

### Variables with Validation

```hcl
variable "environment" {
  type        = string
  description = "Target environment"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "node_count" {
  type        = number
  default     = 2

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 20
    error_message = "Node count must be between 1 and 20."
  }
}
```

### Locals for Computed Values

```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }

  cluster_name = "${var.environment}-${var.project_name}-aks"
}
```

### Data Sources for Existing Resources

```hcl
data "azurerm_client_config" "current" {}

data "terraform_remote_state" "network" {
  backend = "azurerm"

  config = {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate"
    container_name       = "tfstate"
    key                 = "env/shared/network.tfstate"
  }
}

resource "azurerm_kubernetes_cluster" "main" {
  vnet_subnet_id = data.terraform_remote_state.network.outputs.aks_subnet_id
}
```

---

## Security

### No Hardcoded Secrets

```hcl
variable "client_secret" {
  type        = string
  sensitive   = true
  description = "Provider client secret"
}

provider "identity" {
  client_id     = var.client_id
  client_secret = var.client_secret
}
```

Use environment variables or secret stores (e.g. GitHub Actions secrets, Azure Key Vault) and pass via `TF_VAR_*` or `-var`.

### Backend Encryption

```hcl
backend "s3" {
  encrypt = true
}

backend "azurerm" {
  use_msi = true
}
```

### Sensitive Outputs

```hcl
output "connection_string" {
  value     = azurerm_storage_account.main.primary_connection_string
  sensitive = true
}
```

**Rules:**
- Never commit secrets to version control
- Use `sensitive = true` for variables and outputs containing secrets
- Prefer managed identities over static credentials where possible
- Use `-var-file` for non-sensitive environment config; inject secrets at runtime

---

## Testing Strategy

### terraform validate

```bash
terraform init -backend=false
terraform validate
```

### tflint

```hcl
# .tflint.hcl
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}
```

```bash
tflint --recursive
```

### terraform plan in CI

```yaml
- name: Terraform Plan
  run: |
    terraform init
    terraform plan -out=tfplan -var-file=terraform.tfvars
```

### Terratest (Module Testing)

```go
func TestAKSClusterModule(t *testing.T) {
  t.Parallel()

  terraformOptions := &terraform.Options{
    TerraformDir: "../modules/aks-cluster",
    Vars: map[string]interface{}{
      "cluster_name":   "test-cluster",
      "environment":    "test",
      "resource_group": "rg-test",
      "node_count":     1,
    },
    NoColor: true,
  }

  defer terraform.Destroy(t, terraformOptions)
  terraform.InitAndApply(t, terraformOptions)

  clusterID := terraform.Output(t, terraformOptions, "cluster_id")
  assert.NotEmpty(t, clusterID)
}
```

### tftest (Python)

```python
import tftest

def test_aks_cluster():
    tf = tftest.TerraformTest("./modules/aks-cluster")
    tf.setup()
    tf.apply(tfvars={"cluster_name": "test", "environment": "test"})
    outputs = tf.output()
    assert "cluster_id" in outputs
    tf.destroy()
```

**Rules:**
- Run `terraform validate` on every PR
- Run `tflint` in CI
- Run `terraform plan` on PR; block merge if plan fails
- Use Terratest or tftest for critical reusable modules

---

## CI/CD Integration

### Plan on PR

```yaml
jobs:
  terraform-plan:
    steps:
      - uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: "1.2.2"

      - name: Terraform Init
        run: terraform init -backend=false
        working-directory: terraform/environments/${{ matrix.env }}

      - name: Terraform Validate
        run: terraform validate
        working-directory: terraform/environments/${{ matrix.env }}

      - name: Terraform Plan
        run: terraform plan -no-color -input=false -var-file=terraform.tfvars
        working-directory: terraform/environments/${{ matrix.env }}
```

### Apply on Merge to Main

```yaml
jobs:
  terraform-apply:
    if: github.ref == 'refs/heads/main'
    environment: production
    steps:
      - name: Terraform Init
        run: terraform init
        working-directory: terraform/environments/${{ matrix.env }}

      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: terraform/environments/${{ matrix.env }}
```

**Rules:**
- Plan on every PR; require successful plan before merge
- Apply only on merge to main (or protected branch)
- Use environment protection rules for production (approval gates)
- Pin Terraform version in CI
- Use OIDC or assume-role for cloud credentials; never long-lived keys

---

## Common Patterns

### Lifecycle Blocks

```hcl
resource "azurerm_kubernetes_cluster_node_pool" "main" {
  lifecycle {
    ignore_changes = [node_count]
  }
}

resource "aws_instance" "main" {
  lifecycle {
    create_before_destroy = true
  }
}
```

### Dynamic Blocks

```hcl
resource "aws_security_group" "main" {
  dynamic "ingress" {
    for_each = var.allowed_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidrs
    }
  }
}
```

### Data Sources for Existing Resources

```hcl
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "main" {
  tags = {
    Name = "${var.environment}-vpc"
  }
}
```

### Conditional Resources

```hcl
resource "azurerm_monitor_activity_log_alert" "main" {
  count = var.environment == "production" ? 1 : 0
  name  = "critical-alerts"
}
```

### for_each for Multiple Instances

```hcl
variable "regions" {
  type = list(string)
}

resource "azurerm_resource_group" "main" {
  for_each = toset(var.regions)
  name     = "rg-${var.project}-${each.key}"
  location = each.key
}
```

---

## Checklist

Before completing infrastructure changes, verify:

- [ ] Module structure follows standard layout (main.tf, variables.tf, outputs.tf)
- [ ] Remote state configured with encryption and locking
- [ ] No hardcoded secrets; use variables and inject at runtime
- [ ] Sensitive outputs marked with `sensitive = true`
- [ ] Resource naming follows `{environment}-{project}-{type}` convention
- [ ] `terraform validate` and `tflint` pass
- [ ] `terraform plan` runs successfully in CI on PR
- [ ] Environment-specific values in tfvars; no environment logic in modules
- [ ] Lifecycle blocks used where appropriate (ignore_changes, create_before_destroy)
- [ ] Data sources used for existing resources; no duplicate definitions
