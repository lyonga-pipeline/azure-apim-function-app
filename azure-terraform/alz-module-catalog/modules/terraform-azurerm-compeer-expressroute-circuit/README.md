# terraform-azurerm-compeer-expressroute-circuit

A single `azurerm_express_route_circuit`. Peerings, connections and the gateway
are separate modules.

## Inputs (selected)

| Input | Type | Notes |
|---|---|---|
| `name` / `resource_group_name` / `location` | string | ForceNew |
| `service_provider_name` / `peering_location` | string | ForceNew |
| `bandwidth_in_mbps` | number | update in place (upgrade only) |
| `sku` / `tier` / `family` | string | see vars |

## Outputs

`id`, `name`, `service_key` (sensitive — provisioning key for the provider),
`service_provider_provisioning_state`.

## Lifecycle contract

`bandwidth_in_mbps` increase, `tags` → **update in place**. `service_provider_name`
/ `peering_location` / `name` / `rg` / `location` → **replace**. A circuit is a
billed, provider-provisioned resource — never let an upgrade recreate it.

**State exposure:** `service_key` is a sensitive output.

## Tests

`terraform test` (offline): create.
