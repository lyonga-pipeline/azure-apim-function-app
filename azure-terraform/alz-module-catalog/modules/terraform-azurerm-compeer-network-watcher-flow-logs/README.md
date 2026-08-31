# terraform-azurerm-compeer-network-watcher-flow-logs

NSG flow logs (`azurerm_network_watcher_flow_log`) keyed by a stable logical key,
with optional Traffic Analytics. The Network Watcher, storage account and Log
Analytics workspace are all caller-owned and passed in by ID/name.

## Inputs

`flow_logs` — `map(object({ name, network_watcher_name, resource_group_name,
network_security_group_id, storage_account_id, enabled?, retention_policy?,
traffic_analytics?, timeouts? }))`.

## Outputs

`ids`, `names`, `flow_logs` (composite) — keyed by input key.

## Lifecycle contract

`enabled`, `retention_policy`, `traffic_analytics` → **update in place**. `name`
/ `network_watcher_name` / `network_security_group_id` → **replace** that flow log.

State exposure: none.

## Tests

`terraform test` (offline): create.
