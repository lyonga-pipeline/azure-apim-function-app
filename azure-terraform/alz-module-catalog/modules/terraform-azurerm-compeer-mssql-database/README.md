# terraform-azurerm-compeer-mssql-database

A single database on a caller-owned Azure SQL logical server. The server, firewall, auditing and failover groups are owned elsewhere.

## Contract

- Resource: `azurerm_mssql_database` (database).
- Inputs are explicitly typed; optional blocks are `optional(object(...))` and repeatables are `map(object(...))` keyed by a caller-stable name.
- Adjacent resource-group / network / RBAC / diagnostic capabilities are composed externally.

## Lifecycle

| Change | Effect |
|---|---|
| `sku_name` (vCore/DTU tier change), `max_size_gb`, `auto_pause_delay_in_minutes`, `min_capacity`, retention policies, `tags` | In-place update |
| `name`, `server_id` | Replace |
| `collation`, `create_mode`, `ledger_enabled` | Replace |

## State exposure

Outputs: database `id` / `name`. No secrets.

## Migration

No breaking changes. Dead commented `data.tf` removed.

## Tests

`terraform test` (`tests/defaults.tftest.hcl`, `mock_provider`) — create and attribute wiring; validation failures where the module adds `validation` / `precondition` rules.
