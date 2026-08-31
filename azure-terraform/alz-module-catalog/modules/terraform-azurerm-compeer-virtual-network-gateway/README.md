# terraform-azurerm-compeer-virtual-network-gateway

A single `azurerm_virtual_network_gateway` (VPN or ExpressRoute). GatewaySubnet
and the PIP(s) are caller-owned. Connections are a separate module.

## Inputs (selected)

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` / `resource_group_name` / `location` | string | — | ForceNew |
| `type` | string | `ExpressRoute` | `Vpn` \| `ExpressRoute`; ForceNew |
| `sku` | string | `ErGw1AZ` | update in place (resize) where the platform allows |
| `vpn_type` | string | `RouteBased` | ForceNew |
| `ip_configurations` | map(object) | — | `{public_ip_address_id, subnet_id, private_ip_address_allocation?}` |

## Outputs

`id`, `name`, `bgp_settings`, public IPs.

## Lifecycle contract

`sku` (resize), `bgp_settings`, `tags` → **update in place** (mostly). `type` /
`vpn_type` / `ip_configurations` subnet → **replace**. A gateway takes ~30-45 min
to create — never recreate one on a routine upgrade.

State exposure: none.

## Tests

`terraform test` (offline): create (ExpressRoute default).
