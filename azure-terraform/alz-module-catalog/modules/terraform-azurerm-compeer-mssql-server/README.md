# terraform-azurerm-compeer-mssql-server

An Azure SQL **logical server** only. Databases, elastic pools, firewall rules, AD admin and auditing are separate modules.

## Contract

- Resource: `azurerm_mssql_server` (logical server).
- Inputs are explicitly typed; optional blocks are `optional(object(...))` and repeatables are `map(object(...))` keyed by a caller-stable name.
- Adjacent resource-group / network / RBAC / diagnostic capabilities are composed externally.

## Lifecycle

| Change | Effect |
|---|---|
| `administrator_login_password`, `minimum_tls_version`, `public_network_access_enabled`, `outbound_network_restriction_enabled`, `identity`, `azuread_administrator`, `tags` | In-place update |
| `name`, `resource_group_name`, `location` | Replace |
| `mssql_server_version`, `administrator_login` | Replace |

## State exposure

Outputs: `id` / `name` / `fully_qualified_domain_name`, `identity_principal_id` / `identity_tenant_id`. `administrator_login_password` is stored in state.

## Migration

`identity` / `azuread_administrator` `dynamic` blocks no longer misfire on the null default. Identity outputs added.

## Tests

`terraform test` (`tests/defaults.tftest.hcl`, `mock_provider`) — create and attribute wiring; validation failures where the module adds `validation` / `precondition` rules.
