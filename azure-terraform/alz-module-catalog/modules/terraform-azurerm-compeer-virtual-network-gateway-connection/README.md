# terraform-azurerm-compeer-virtual-network-gateway-connection

A single `azurerm_virtual_network_gateway_connection`. A **precondition** enforces
that `type` matches exactly one target: `ExpressRoute` → `express_route_circuit_id`;
`IPsec` → `local_network_gateway_id` (+ `shared_key`); `Vnet2Vnet` →
`peer_virtual_network_gateway_id`.

## Inputs (selected)

`name`, `resource_group_name`, `location`, `virtual_network_gateway_id`, `type`;
one of `express_route_circuit_id` / `local_network_gateway_id` /
`peer_virtual_network_gateway_id`; `shared_key` (sensitive), `authorization_key`
(sensitive), BGP / IPsec-policy / NAT-rule options.

## Outputs

`id`, `name`, `resource_group_name`.

## Lifecycle contract

`shared_key`, `routing_weight`, `connection_mode`, BGP flags, `tags` → **update in
place**. `type`, the target `*_id`, `virtual_network_gateway_id` → **replace**.

**State exposure:** `shared_key` and `authorization_key` are in state.

## Tests

`terraform test` (offline): ExpressRoute connection, IPsec-without-LNG precondition.
