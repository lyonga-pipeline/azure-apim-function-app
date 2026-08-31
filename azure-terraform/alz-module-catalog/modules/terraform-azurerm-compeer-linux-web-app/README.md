# terraform-azurerm-compeer-linux-web-app

Single `azurerm_linux_web_app`. The Service Plan is passed in by ID
(`service_plan_id`) and is caller-owned. Diagnostics are composed via
`terraform-azurerm-compeer-diagnostic-settings` at the pattern layer.

## Usage

```hcl
module "web" {
  source                    = "../terraform-azurerm-compeer-linux-web-app"
  name                      = "app-portal-prod"
  resource_group_name       = module.rg.name
  location                  = "eastus2"
  service_plan_id           = module.plan.id
  virtual_network_subnet_id = module.spoke.subnet_ids["web"]

  site_config = [{
    always_on          = true
    application_stack   = [{ node_version = "20-lts" }]
    minimum_tls_version = "1.2"
  }]

  connection_string = {
    sql = { type = "SQLAzure", value = "@Microsoft.KeyVault(SecretUri=...)" }
  }

  tags = module.tags.tags
}
```

## Inputs (selected)

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` / `resource_group_name` / `location` | string | - | ForceNew |
| `service_plan_id` | string | - | update in place (plan swap) |
| `site_config` | list(object) | `[{}]` | **exactly one element** (validated); maps to the required singleton `site_config` block |
| `connection_string` | map(object) | `{}` | keyed by name - `{type, value}` |
| `app_settings` | map(string) | `null` | update in place |
| `https_only` / `public_network_access_enabled` | bool | `false` | update in place |
| `auth_settings` / `backup` / `logs` / `sticky_settings` / `storage_account` | object \| null | `null` | optional blocks |
| `identity` | object \| null | `null` | optional managed identity |

## Outputs

`id`, `name`, `default_hostname`, `outbound_ip_addresses`,
`possible_outbound_ip_addresses`, `identity_principal_id`.

## Lifecycle contract

| Change | Result |
|---|---|
| `app_settings`, `site_config.*`, `connection_string`, `https_only`, `public_network_access_enabled`, `virtual_network_subnet_id`, `identity`, `tags`, `service_plan_id` | **update in place** |
| `name`, `resource_group_name`, `location` | **replace** |

**State exposure:** `connection_string[*].value`, `backup.storage_account_url` and
`storage_account[*].access_key` are stored in state. Prefer
`@Microsoft.KeyVault(...)` references and `key_vault_reference_identity_id`.

## Migration / fixes applied

- Removed a dead `data "azurerm_monitor_diagnostic_categories"` source and unused
  `locals` (embedded-diagnostics leftover) - these were causing **apply failures**.
- Rewrote the `site_config` nested `dynamic` blocks: `lookup(obj, "k", null)` on a
  typed object returns `null` (not the default) for absent optionals, which broke
  every sub-block `for_each`. Now uses `obj.k == null ? [] : ...`.
- Outputs renamed `webapp_id`->`id`, `webapp_principal_id`->`identity_principal_id`
  (now null-safe), plus `name` / hostname / outbound IPs added.

**Known follow-up:** `site_config`, `auth_settings`, `backup`, `logs`,
`sticky_settings`, `storage_account` are `list(object)` used as singletons.
Converting them to `optional(object(...))` is a non-breaking improvement for the
zero current consumers, deferred to a focused pass.

## Tests

`terraform test` (offline): secure defaults + single site_config block, keyed
connection strings, empty-site_config rejection.
