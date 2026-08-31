# terraform-azurerm-compeer-local-network-gateway

Local network gateways (on-premises site definitions for S2S VPN),
`azurerm_local_network_gateway`, keyed by a stable logical name so adding a site
never touches the others.

## Usage

```hcl
module "sites" {
  source = "../terraform-azurerm-compeer-local-network-gateway"
  local_network_gateways = {
    hq = {
      name                = "lng-hq"
      resource_group_name = module.rg.name
      location            = "eastus2"
      gateway_address     = "203.0.113.1"
      address_space       = ["10.100.0.0/16"]
      bgp_settings        = { asn = 65010, bgp_peering_address = "10.100.0.254" }
    }
  }
}
```

## Inputs

`local_network_gateways` — `map(object({ name, resource_group_name, location,
gateway_address, address_space, bgp_settings?, tags?, timeouts? }))`.

## Outputs

`ids`, `names`, `gateway_addresses`, `gateways` (composite) — all keyed by input key.

## Lifecycle contract

`gateway_address`, `address_space`, `bgp_settings`, `tags` → **update in place**.
`name` / `resource_group_name` / `location` → **replace** that gateway. Adding /
removing a map key affects only that gateway.

State exposure: none.

## Tests

`terraform test` (offline): create, additive add.
