# terraform-azurerm-compeer-key-vault

> **⚠ Non-canonical — use [`terraform-azurerm-compeer-keyvault`](../terraform-azurerm-compeer-keyvault) instead** (the consumed vault module (3 pattern consumers)). This module is kept working for backward compatibility; do not pick it for new work.


Azure Key Vault (vault resource only). Same capability as
`terraform-azurerm-compeer-keyvault`; this variant uses a keyed
`access_policies` map (stable identity) and has no current pattern consumers, so
its interface can evolve more freely. Data-plane objects, private endpoints,
diagnostics and RBAC are composed by the dedicated companion modules.

## Usage

```hcl
module "vault" {
  source              = "../terraform-azurerm-compeer-key-vault"
  name                = "kv-app-prod"
  resource_group_name = module.rg.name
  location            = "eastus2"
  tenant_id           = var.tenant_id
  tags                = module.tags.tags
}
```

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` | string | — | ForceNew; validated |
| `resource_group_name` / `location` / `tenant_id` | string | — | first two ForceNew |
| `sku_name` | string | `standard` | `standard` \| `premium` |
| `soft_delete_retention_days` | number | `90` | 7-90 |
| `purge_protection_enabled` | bool | `true` | one-way |
| `public_network_access_enabled` | bool | `false` | update in place |
| `rbac_authorization_enabled` | bool | `true` | update in place |
| `access_policies` | map(object) | `{}` | keyed by stable id; used only when RBAC off |
| `network_acls` | object \| null | `null` | `null` = no ACL block; object = validated |
| `contacts` | map(object) | `{}` | keyed certificate contacts |
| `timeouts` | object | `{}` | passthrough |

## Outputs

`id`, `name`, `vault_uri`, `resource_group_name`, `tenant_id`,
`rbac_authorization_enabled`, `private_endpoint_subresource_name` (`"vault"`).

## Lifecycle contract

| Change | Result |
|---|---|
| `sku_name`, `public_network_access_enabled`, `network_acls`, `contacts`, `tags`, `access_policies` | **update in place** |
| `rbac_authorization_enabled` toggle | update in place (auth-model switch) |
| lower `soft_delete_retention_days` | **replace** |
| `name`, `resource_group_name`, `location`, `tenant_id` | **replace** |

State exposure: none directly.

## Migration

Fixed a latent bug: `network_acls` validation used `x == null || x.attr` which
throws on the null default - now `x == null ? true : ...`.

## Tests

`terraform test` (offline): secure defaults, keyed access policy, name validation,
RBAC-off precondition.
