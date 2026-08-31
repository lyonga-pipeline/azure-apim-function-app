# terraform-azurerm-compeer-vnet-peering

One `azurerm_virtual_network_peering` (one direction). Compose two instances
(hub→spoke and spoke→hub) at the pattern layer, each with the right provider
alias. Non-standard input names (`peering_name`, `rg_name`, `vnet_name`) are kept
for interface stability (3 consumers).

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `peering_name` | string | — | ForceNew |
| `rg_name` / `vnet_name` | string | — | the *local* side; ForceNew |
| `remote_virtual_network_id` | string | — | ForceNew |
| `allow_virtual_network_access` | bool | `false` | update in place |
| `allow_forwarded_traffic` | bool | `false` | update in place |
| `allow_gateway_transit` | bool | `false` | update in place (hub side) |
| `use_remote_gateways` | bool | `false` | update in place (spoke side) |

## Outputs

`id`, `name` (+ legacy `peering_*` aliases), `peering_resource_group_name`,
`peering_virtual_network_name`, `peering_remote_virtual_network_id`, and each
`allow_*` / `use_remote_gateways` value.

## Lifecycle contract

All `allow_*` / `use_remote_gateways` flags → **update in place**. `peering_name`,
`rg_name`, `vnet_name`, `remote_virtual_network_id` → **replace**. Peering is a
durable link — do not let upgrades recreate it (that briefly drops connectivity).

State exposure: none.

## Migration

`allow_virtual_network_access` / `allow_forwarded_traffic` / `allow_gateway_transit`
/ `use_remote_gateways` changed from **required** to `default = false` (safe:
existing callers pass them explicitly).

## Tests

`terraform test` (offline): flag defaults, hub gateway-transit.
