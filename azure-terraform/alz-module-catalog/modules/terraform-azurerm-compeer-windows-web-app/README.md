# terraform-azurerm-compeer-windows-web-app

Single `azurerm_windows_web_app`. Same shape and contract as
`terraform-azurerm-compeer-linux-web-app` (see that README for full input /
output / lifecycle detail) except `site_config.application_stack` uses the Windows
fields (`current_stack`, `dotnet_version`, `dotnet_core_version`, `tomcat_version`,
`java_version`, `node_version`, `php_version`, `python`).

Service Plan is passed in by ID; diagnostics compose at the pattern layer.

## Outputs

`id`, `name`, `default_hostname`, `outbound_ip_addresses`, `identity_principal_id`.

## Lifecycle contract

`app_settings`, `site_config.*`, `connection_string`, `https_only`,
`public_network_access_enabled`, `identity`, `tags`, `service_plan_id` -> **update
in place**. `name` / `resource_group_name` / `location` -> **replace**.

State exposure: `connection_string[*].value` and `storage_account[*].access_key`
are in state - prefer Key Vault references.

## Migration / fixes applied

- Removed dead `data "azurerm_monitor_diagnostic_categories"` + unused `locals`
  (embedded-diagnostics leftover - caused apply failures).
- Rewrote `site_config` nested `dynamic` `for_each` to null-safe form.
- Removed stray commented-out `variable` blocks that broke `terraform fmt`.
- Outputs renamed to `id` / `name` / `identity_principal_id` (null-safe).

**Known follow-up:** same `list(object)`-as-singleton refactor as `linux-web-app`.

## Tests

`terraform test` (offline): secure defaults, keyed connection strings,
empty-site_config rejection.
