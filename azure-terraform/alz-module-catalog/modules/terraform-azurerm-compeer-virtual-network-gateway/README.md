# terraform-azurerm-compeer-virtual-network-gateway

A single `azurerm_virtual_network_gateway`, either `ExpressRoute` or `Vpn`. The
`GatewaySubnet` and the public IP(s) are caller-owned. Connections are a separate
module (`terraform-azurerm-compeer-virtual-network-gateway-connection`).

## Usage

```hcl
module "expressroute_gateway" {
  source = "../../modules/terraform-azurerm-compeer-virtual-network-gateway"

  name                = "platform-cus-prod-ergw"
  resource_group_name = "platform-cus-prod-hybrid-rg"
  location            = "centralus"
  type                = "ExpressRoute"
  sku                 = "ErGw3AZ"
  ip_configurations = {
    default = {
      public_ip_address_id = module.gateway_pip.id
      subnet_id            = "<hub vnet id>/subnets/GatewaySubnet"
    }
  }
}
```

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` | string | - | Azure naming rule: 1-80 chars, alphanumerics/underscore/period/hyphen, starts alphanumeric, ends alphanumeric or underscore; ForceNew |
| `resource_group_name` / `location` | string | - | non-empty; ForceNew |
| `type` | string | `ExpressRoute` | `ExpressRoute` or `Vpn`; ForceNew |
| `sku` | string | `ErGw1AZ` | documented SKU values only; must match `type` (see Validation) |
| `vpn_type` | string | `RouteBased` | `RouteBased` or `PolicyBased`; `PolicyBased` requires the `Basic` SKU |
| `active_active` | bool | `false` | requires at least two `ip_configurations` |
| `bgp_enabled` | bool | `null` | preferred input; resolves to `true` when neither this nor `enable_bgp` is set |
| `enable_bgp` | bool | `null` | deprecated alias for `bgp_enabled` |
| `generation` | string | `null` | `Generation1`, `Generation2` or `None` |
| `ip_configurations` | map(object) | - | `{ public_ip_address_id, subnet_id, private_ip_address_allocation? }`; at least one entry |
| `tags` | map(string) | `{}` | update in place |

## Validation

- SKU is one of the documented values: `Basic`, `Standard`, `HighPerformance`,
  `UltraPerformance`, `ErGwScale`, `ErGw1AZ`-`ErGw3AZ`, `VpnGw1`-`VpnGw5`,
  `VpnGw1AZ`-`VpnGw5AZ`.
- An ExpressRoute gateway cannot use a VPN SKU (`Basic`, `VpnGw*`); a VPN gateway
  cannot use an ExpressRoute SKU (`UltraPerformance`, `ErGw*`). `Standard` and
  `HighPerformance` exist for both types and are accepted for either.
- `PolicyBased` VPN gateways support only the `Basic` SKU.
- Every `ip_configurations[*].subnet_id` must reference `GatewaySubnet`.
- `active_active` requires at least two IP configurations.
- Name rule, enum checks and non-empty resource group/location.

## Outputs

`id`, `name`.

## Lifecycle contract

`sku` (resize where Azure allows it), BGP setting and `tags` update in place.
`type`, `vpn_type` and the gateway subnet replace the gateway. A gateway takes
roughly 30-45 minutes to create, so review every plan for replacement.

State exposure: none.

## Tests

`terraform test` (offline, `mock_provider`): ExpressRoute and active-active VPN
gateway shapes, SKU/type pairing, the `PolicyBased` rule, generation and enum
checks, GatewaySubnet and active-active guards, naming rules, and output wiring.
