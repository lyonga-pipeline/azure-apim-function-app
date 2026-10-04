# terraform-azurerm-compeer-route-server

Azure Route Servers (`azurerm_route_server`) and their BGP peer connections
(`azurerm_route_server_bgp_connection`). Both are keyed maps, so adding a server
or a peer never touches the others.

Route Server is a routing control plane: it exchanges BGP routes between network
virtual appliances (for example the SD-WAN or firewall pair) and the virtual
network, and, with branch-to-branch enabled, with ExpressRoute/VPN gateways. It
does not carry data traffic.

## Scope

- **Owned here:** the Route Server and its BGP connections.
- **Caller-owned:** the `RouteServerSubnet` (it must carry no NSG and no UDR)
  and the Standard, Static public IP that Azure requires for Route Server
  management traffic.

## Usage

```hcl
module "route_servers" {
  source = "../../modules/terraform-azurerm-compeer-route-server"

  route_servers = {
    primary = {
      name                 = "platform-cus-prod-rs"
      resource_group_name  = "platform-cus-prod-hybrid-rg"
      location             = "centralus"
      subnet_id            = "<hub vnet id>/subnets/RouteServerSubnet"
      public_ip_address_id = module.route_server_pip.id
      bgp_connections = {
        sdwan1 = { name = "sdwan-nva-1", peer_asn = 65010, peer_ip = "10.102.0.132" }
      }
    }
  }
}
```

## Inputs

`route_servers` — `map(object)`:

| Field | Type | Default | Notes |
|---|---|---|---|
| `name` / `resource_group_name` / `location` | string | - | required, non-empty |
| `sku` | string | `Standard` | `Standard` is the only SKU Azure supports |
| `subnet_id` | string | - | must reference a subnet named `RouteServerSubnet` |
| `public_ip_address_id` | string | - | required, non-empty |
| `branch_to_branch_traffic_enabled` | bool | `true` | lets Route Server exchange routes between NVAs and ExpressRoute/VPN gateways; confirm the routing design before production cutover |
| `bgp_connections` | map(object) | `{}` | `{ name, peer_asn, peer_ip, ipv4_route_server_id?, timeouts? }` |
| `tags` / `timeouts` | map / object | `{}` | pass-through |

## Validation

| Rule | Why |
|---|---|
| `subnet_id` ends in `/subnets/RouteServerSubnet` | Azure requires the dedicated subnet name |
| Each route server uses its own subnet | Azure allows one Route Server per virtual network |
| `sku` is `Standard` | only documented value |
| At most 16 `bgp_connections` per route server | Azure Route Server peer limit |
| `peer_asn` is a 2-byte ASN (1-65534), excluding Azure-reserved (8074, 8075, 12076, 65515, 65517-65520) and IANA-reserved (23456, 64496-64511, 65535) values | Route Server supports only 16-bit ASNs and rejects reserved ones |
| `peer_ip` is a valid IPv4 address | Route Server does not support IPv6 |
| Name, resource group, location and public IP are non-empty; an unresolved (null) value fails cleanly | avoids function errors at plan |

## Outputs

| Output | Description |
|---|---|
| `ids`, `names`, `resource_group_names` | keyed by input key |
| `route_servers` | composite map (id, name, resource group, location, subnet, public IP, branch-to-branch) |
| `bgp_connection_ids`, `bgp_connections` | keyed `<route-server-key>-<connection-key>` |

## Operational notes

- Creating or deleting a Route Server in a virtual network that already has a
  VPN or ExpressRoute gateway causes roughly 10 minutes of gateway downtime and
  a 30-60 minute deployment; deploy it before the gateways where possible.
- Peer each NVA with both Route Server instances; Route Server keeps ASN 65515,
  so NVAs must use a different ASN.

## Lifecycle contract

`branch_to_branch_traffic_enabled`, `tags` and BGP-connection add/remove update
in place (per connection). `name`, `subnet_id`, `public_ip_address_id` and `sku`
replace that route server.

State exposure: none.

## Tests

`terraform test` (offline, `mock_provider`): route server shape, BGP connection
creation, multi-server and empty-map behaviour, every validation above (accept
and reject, including the 16-peer boundary and reserved ASNs), unresolved
subnet/public-IP handling, and output wiring.
