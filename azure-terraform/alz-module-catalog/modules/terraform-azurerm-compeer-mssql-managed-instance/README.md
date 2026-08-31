# terraform-azurerm-compeer-mssql-managed-instance

An Azure SQL Managed Instance. Databases, AD admin, failover groups, TDE and networking (the delegated subnet, route table, NSG) are owned by the pattern.

## Contract

- Resource: `azurerm_mssql_managed_instance` (managed instance).
- Inputs are explicitly typed; optional blocks are `optional(object(...))` and repeatables are `map(object(...))` keyed by a caller-stable name.
- Adjacent resource-group / network / RBAC / diagnostic capabilities are composed externally.

## Lifecycle

| Change | Effect |
|---|---|
| `vcores`, `storage_size_in_gb`, `sku_name` within family, `license_type`, `minimum_tls_version`, `public_data_endpoint_enabled`, `identity`, `tags` | In-place update (long-running) |
| `name`, `resource_group_name`, `location`, `subnet_id`, `dns_zone_partner_id` | Replace |

## State exposure

Outputs: `id` / `fqdn`, `identity_principal_id` / `identity_tenant_id` (deprecated aliases `principal_id` / `tenant_id`). `administrator_login_password` is stored in state.

## Migration

Identity `dynamic` block no longer misfires on the null default; identity outputs are now null-safe.

## Tests

`terraform test` (`tests/defaults.tftest.hcl`, `mock_provider`) — create and attribute wiring; validation failures where the module adds `validation` / `precondition` rules.
