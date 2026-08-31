# terraform-azurerm-compeer-windows-function-app

Single `azurerm_windows_function_app` + its Service Plan is passed in by ID
(`service_plan_id`, caller-owned). The backing storage account is also
caller-owned; auth to it is one of: `storage_account_access_key`,
`storage_uses_managed_identity = true`, or `storage_key_vault_secret_id`.

Diagnostics compose via `terraform-azurerm-compeer-diagnostic-settings` at the
pattern layer.

## Usage

```hcl
module "fn" {
  source                        = "../terraform-azurerm-compeer-windows-function-app"
  name                          = "fn-orders-prod"
  resource_group_name           = module.rg.name
  location                      = "eastus2"
  service_plan_id               = module.plan.id
  storage_account_name          = module.storage.name
  storage_uses_managed_identity = true

  site_config = [{
    application_stack = { dotnet_version = "v8.0" }
  }]

  tags = module.tags.tags
}
```

## Inputs (selected)

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` / `resource_group_name` / `location` | string | — | ForceNew |
| `service_plan_id` | string | — | update in place |
| `storage_account_name` + one of (`storage_account_access_key` \| `storage_uses_managed_identity` \| `storage_key_vault_secret_id`) | — | — | exactly one auth path required by the provider |
| `site_config` | list(object) | `[{}]` | exactly one element (validated) |
| `connection_string` | map(object) | `{}` | keyed by name |
| `public_network_access_enabled` / `https_only` | bool | `false` / `true` | update in place |
| `identity` / `auth_settings` / `backup` / `sticky_settings` / `storage_account` | list(object) | `[]` | optional blocks |

## Outputs

`id`, `name`, `default_hostname`, `outbound_ip_addresses`, `identity_principal_id`.

## Lifecycle contract

| Change | Result |
|---|---|
| `app_settings`, `site_config.*`, `connection_string`, `identity`, `tags`, `service_plan_id`, `public_network_access_enabled` | **update in place** |
| storage auth method switch | update in place |
| `name`, `resource_group_name`, `location` | **replace** |

**State exposure:** `storage_account_access_key`, `connection_string[*].value`.
Prefer `storage_uses_managed_identity` / `storage_key_vault_secret_id`.

## Migration / fixes applied

- Fixed two broken `.value` chains in the `site_config` `ip_restriction` /
  `scm_ip_restriction` `headers` sub-blocks.
- Outputs: `windows_function_id`→`id`; dropped the `name` / `resource_group_name`
  input-echo outputs; `principal_id`→`identity_principal_id` (now null-safe).
- The earlier `ignore_changes = [app_settings, functions_extension_version,
  storage_account_access_key, tags]` was already removed by the redesign baseline.

**Known follow-up:** `site_config`, `identity`, `auth_settings`, `backup`,
`sticky_settings`, `storage_account` are `list(object)` used as singletons —
convert to `optional(object(...))` in a focused pass.

## Tests

`terraform test` (offline): secure defaults, keyed connection strings,
empty-site_config rejection.
