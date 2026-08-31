# terraform-azurerm-compeer-user-assigned-identity

A single user-assigned managed identity (`azurerm_user_assigned_identity`).
Federated credentials and role assignments are companion concerns
(`role-assignments`, a federated-credential module).

## Usage

```hcl
module "workload_identity" {
  source              = "../terraform-azurerm-compeer-user-assigned-identity"
  name                = "id-orders-prod"
  resource_group_name = module.rg.name
  location            = "eastus2"
  tags                = module.tags.tags
}
```

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` / `resource_group_name` / `location` | string | - | all ForceNew |
| `tags` | map(string) | `{}` | update in place |

## Outputs

`id`, `name`, `client_id`, `principal_id`, `tenant_id`.

## Lifecycle contract

`tags` update in place; `name` / `resource_group_name` / `location` **replace**
(Azure ForceNew). `principal_id` / `client_id` are stable for the life of the
identity - safe to reference from role assignments.

State exposure: none.

## Migration

Interface unchanged (2 consumers). Added input/output descriptions plus `name`
and `tenant_id` outputs.

## Tests

`terraform test` (offline): create.
