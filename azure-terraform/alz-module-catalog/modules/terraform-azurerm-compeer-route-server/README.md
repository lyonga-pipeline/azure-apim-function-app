# terraform-azurerm-compeer-route-server

Azure Route Servers (`azurerm_route_server`) + their BGP connections, both keyed
maps so adding a server or a peer never touches the others. RouteServerSubnet and
the Standard Static PIP are caller-owned.

## Inputs

`route_servers` — `map(object({ name, resource_group_name, location, sku?,
subnet_id, public_ip_address_id, branch_to_branch_traffic_enabled?, tags?,
timeouts?, bgp_connections?=map(object({ name, peer_asn, peer_ip, ... })) }))`.

## Outputs

`ids`, `names`, `resource_group_names`, `route_servers` (composite),
`bgp_connection_ids`, `bgp_connections` — keyed by input / generated key.

## Lifecycle contract

`branch_to_branch_traffic_enabled`, `tags`, BGP-connection add/remove → **update
in place** / per-connection. `name`, `subnet_id`, `public_ip_address_id`, `sku` →
**replace** that route server.

State exposure: none.

## Tests

`terraform test` (offline): create.
