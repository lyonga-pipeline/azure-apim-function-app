# terraform-azurerm-compeer-keyvault

Azure Key Vault (the vault resource only). Data-plane objects, private endpoints,
diagnostics and RBAC are composed by their dedicated modules:
`key-vault-secret`, `key-vault-key`, `key-vault-certificate`, `private-endpoint`,
`diagnostic-settings`, `role-assignments`.

This is the module currently used by the platform patterns. Its interface is a
stable contract — new capability is added only through backward-compatible
optional inputs.

## Usage

```hcl
module "vault" {
  source              = "../terraform-azurerm-compeer-keyvault"
  name                = "kv-plat-identity-prod"
  resource_group_name = module.rg.name
  location            = "eastus2"
  tenant_id           = var.tenant_id
  tags                = module.tags.tags
}
```

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` | string | — | ForceNew; validated against the Azure name rule |
| `resource_group_name` / `location` / `tenant_id` | string | — | first two ForceNew |
| `sku_name` | string | `standard` | `standard` \| `premium`; update in place |
| `soft_delete_retention_days` | number | `90` | 7-90; ForceNew on decrease |
| `purge_protection_enabled` | bool | `true` | one-way: cannot be disabled once on |
| `public_network_access_enabled` | bool | `false` | update in place |
| `rbac_authorization_enabled` | bool | `true` | update in place; toggling switches the auth model |
| `access_policies` | list(object) | `[]` | used only when RBAC off; keyed internally by object_id |
| `access_policies_by_key` | map(object) | `{}` | used only when RBAC off; stable keys |
| `network_acls` | object \| null | `{}` | `{}` = deny-by-default; `null` omits the block |
| `enabled_for_*` | bool | `false` | update in place |
| `contacts` | list(object) | `[]` | certificate contacts |
| `timeouts` | object | `{}` | passthrough |

## Outputs

`id`, `name`, `vault_uri`, `resource_group_name`, `tenant_id`,
`rbac_authorization_enabled`, `private_endpoint_subresource_name` (`"vault"`).

## Lifecycle contract

| Change | Result |
|---|---|
| `sku_name`, `public_network_access_enabled`, `enabled_for_*`, `network_acls`, `contacts`, `tags`, `access_policies*` | **update in place** |
| `rbac_authorization_enabled` toggle | update in place (switches auth model - plan carefully) |
| lower `soft_delete_retention_days` | **replace** |
| `name`, `resource_group_name`, `location`, `tenant_id` | **replace** (ForceNew) |
| `purge_protection_enabled` true -> false | rejected by Azure |

State exposure: none directly. Secrets/keys created via the companion modules
land in Terraform state - protect the backend.

## Migration

The redesigned baseline had briefly changed `access_policies` to a map, dropped
`access_policies_by_key`, and made `contacts` a map. This module **restores** the
original list/map contract, so callers on the pre-redesign interface need no
changes. `network_acls` default is `{}` (deny-by-default, bypass `AzureServices`).

## Tests

`terraform test` (offline, `mock_provider`): secure defaults, list+keyed access
policy merge, retention validation, RBAC-off precondition.
