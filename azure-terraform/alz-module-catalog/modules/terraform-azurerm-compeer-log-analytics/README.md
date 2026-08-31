# terraform-azurerm-compeer-log-analytics

A single `azurerm_log_analytics_workspace`. Solutions, data collection rules,
Sentinel onboarding and diagnostic settings are separate modules.

## Inputs (selected)

| Input | Type | Default | Notes |
|---|---|---|---|
| `log_analytics_workspace_name` | string | — | ForceNew |
| `resource_group_name` / `location` | string | — | ForceNew |
| `log_analytics_sku` | string | — | validated (PerGB2018, CapacityReservation, ...) |
| `log_analytics_retention_in_days` | number | — | validated: 7 (Free) or 30-730 |
| `log_analytics_daily_quota_gb` | number | — | `-1` = unlimited; update in place |
| `internet_ingestion_enabled` / `internet_query_enabled` / `local_authentication_disabled` | bool | — | update in place |
| `identity` | object | `null` | optional managed identity |
| `timeouts` | object | `{}` | passthrough |

## Outputs

`id`, `workspace_id` (customer ID), `name`, `primary_shared_key` (sensitive),
`secondary_shared_key` (sensitive).

## Lifecycle contract

`retention`, `daily_quota_gb`, internet/auth flags, `identity`, `tags` → **update
in place**. `sku` change between reservation tiers may be in-place;
`log_analytics_workspace_name` / `rg` / `location` → **replace**. A workspace is a
durable data store — never recreate on a routine upgrade.

**State exposure:** `primary_shared_key` / `secondary_shared_key` are sensitive
outputs and are in state.

## Migration

Interface unchanged (1 consumer). Added `sku` + `retention_in_days` validation and
descriptions.

## Tests

`terraform test` (offline): create, bad-retention rejection.
