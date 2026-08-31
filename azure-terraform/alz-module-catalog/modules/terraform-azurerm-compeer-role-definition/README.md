# terraform-azurerm-compeer-role-definition

A single custom Azure RBAC role definition (`azurerm_role_definition`). Role
*assignments* are a separate lifecycle — use `terraform-azurerm-compeer-role-assignments`.

## Usage

```hcl
module "custom_reader" {
  source = "../terraform-azurerm-compeer-role-definition"
  name   = "Platform Network Reader"
  scope  = "/providers/Microsoft.Management/managementGroups/platform"

  assignable_scopes = ["/providers/Microsoft.Management/managementGroups/platform"]

  permissions = {
    read = {
      actions = [
        "Microsoft.Network/virtualNetworks/read",
        "Microsoft.Network/networkSecurityGroups/read",
      ]
    }
  }
}
```

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` | string | — | ForceNew |
| `scope` | string | — | where the definition lives; ForceNew |
| `role_definition_id` | string | `null` | fixed GUID; leave null for Azure-generated; ForceNew |
| `assignable_scopes` | list(string) | `null` | defaults to `[scope]` |
| `permissions` | map(object) | `{}` | keyed by logical name; **≥1 required** (validated); `actions` / `not_actions` / `data_actions` / `not_data_actions` |

## Outputs

`id`, `name`, `role_definition_id`, `role_definition_resource_id`, `scope`,
`assignable_scopes`.

## Lifecycle contract

`permissions`, `description`, `assignable_scopes` → **update in place**.
`name`, `scope`, `role_definition_id` → **replace** (Azure ForceNew).

State exposure: none.

## Migration

Interface unchanged (1 consumer). Added input descriptions.

## Tests

`terraform test` (offline): create with one permission block, empty-permissions
rejection.
