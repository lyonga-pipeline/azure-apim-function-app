# terraform-azurerm-compeer-route-table

A single route table + its routes (`azurerm_route_table`). Routes are a
`map(object)` keyed by route name. Subnet association is
`subnet-route-table-association`. Canonical route-table module (2 pattern
consumers); `route-tables` (plural) is the equivalent legacy name.

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` / `resource_group_name` / `location` | string | — | ForceNew |
| `bgp_route_propagation_enabled` | bool | `true` | update in place |
| `routes` | map(object) | `{}` | key = route name; `{address_prefix, next_hop_type, next_hop_in_ip_address?}` — `next_hop_type` validated; appliance IP required iff `VirtualAppliance` |
| `tags` | map(string) | `{}` | update in place |

## Outputs

`id`, `name`, `resource_group_name`, `subnet_ids` (associations, external).

## Lifecycle contract

`bgp_route_propagation_enabled`, `routes` (add/edit/remove), `tags` → **update in
place** (routes are inline). `name` / `resource_group_name` / `location` →
**replace**.

State exposure: none.

## Migration

Interface unchanged (2 consumers). Added `next_hop_type` + appliance-IP
validation, input descriptions, `resource_group_name` / `subnet_ids` outputs.

## Tests

`terraform test` (offline): create, appliance-without-IP rejection.
