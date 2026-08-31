# terraform-azurerm-compeer-diagnostic-settings

A single `azurerm_monitor_diagnostic_setting` for one target resource. **The
platform's canonical diagnostics module** — every pattern composes it with a
per-resource `for_each`. Interface is a frozen contract.

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` | string | — | |
| `target_resource_id` | string | — | ForceNew |
| `log_analytics_workspace_id` / `storage_account_id` / `eventhub_authorization_rule_id` / `partner_solution_id` | string | `null` | **≥1 required** (precondition) |
| `log_analytics_destination_type` | string | `null` | `AzureDiagnostics` \| `Dedicated` (validated) |
| `logs` | map(object) | `{}` | each entry sets exactly one of `category` / `category_group` (validated) |
| `metrics` | map(object) | `{}` | `{category, enabled?=true}` |
| `timeouts` | object | `{}` | passthrough |

## Outputs

`id`, `name`, `target_resource_id`, `destinations` (composite).

## Lifecycle contract

`logs`, `metrics`, destinations, `log_analytics_destination_type` → **update in
place**. `target_resource_id` → **replace**. Adding / removing a `logs` /
`metrics` map key changes only that category on the setting.

State exposure: none.

## Migration

Interface unchanged (9 consumers). Only tests + docs added.

## Tests

`terraform test` (offline): create (2 logs + 1 metric), no-destination precondition,
log category/category_group exclusivity, destination-type validation.
