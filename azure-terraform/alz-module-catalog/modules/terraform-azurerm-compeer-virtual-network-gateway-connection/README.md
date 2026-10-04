# terraform-azurerm-compeer-virtual-network-gateway-connection

A single `azurerm_virtual_network_gateway_connection`. A precondition requires
the remote endpoint to match the connection `type`:

| `type` | Required endpoint | Also required |
|---|---|---|
| `ExpressRoute` (default) | `express_route_circuit_id` | - |
| `IPsec` | `local_network_gateway_id` | non-empty `shared_key` |
| `Vnet2Vnet` | `peer_virtual_network_gateway_id` | - |

Exactly one endpoint may be set; the other two must be `null`.

## Usage

```hcl
module "expressroute_connection" {
  source = "../../modules/terraform-azurerm-compeer-virtual-network-gateway-connection"

  name                       = "platform-cus-prod-ergw-connection"
  resource_group_name        = "platform-cus-prod-hybrid-rg"
  location                   = "centralus"
  virtual_network_gateway_id = module.expressroute_gateway.id
  express_route_circuit_id   = module.circuit.id
}
```

## Inputs (selected)

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` | string | - | Azure naming rule: 1-80 chars, alphanumerics/underscore/period/hyphen, starts alphanumeric, ends alphanumeric or underscore; ForceNew |
| `resource_group_name` / `location` | string | - | non-empty; ForceNew |
| `type` | string | `ExpressRoute` | `ExpressRoute`, `IPsec` or `Vnet2Vnet`; ForceNew |
| `virtual_network_gateway_id` | string | - | the local gateway |
| `express_route_circuit_id` / `local_network_gateway_id` / `peer_virtual_network_gateway_id` | string | `null` | exactly the one matching `type` |
| `shared_key` / `authorization_key` | string (sensitive) | `null` | supply from a sensitive variable or approved secret store |
| `routing_weight` | number | `0` | zero or greater |
| `connection_mode` | string | `null` | `Default`, `InitiatorOnly` or `ResponderOnly` |
| `connection_protocol` | string | `null` | `IKEv1` or `IKEv2` |
| `ipsec_policy` | object | `null` | enum-validated fields below |
| `custom_bgp_addresses`, `traffic_selector_policies`, NAT-rule IDs, `dpd_timeout_seconds`, `enable_bgp`, `express_route_gateway_bypass`, `use_policy_based_traffic_selectors`, `local_azure_ip_address_enabled`, `private_link_fast_path_enabled` | - | `null` / `{}` | pass-through |
| `timeouts` / `tags` | object / map | `{}` | pass-through |

`ipsec_policy` fields are validated against the documented values: `dh_group`
(`DHGroup1`, `DHGroup14`, `DHGroup2`, `DHGroup2048`, `DHGroup24`, `ECP256`,
`ECP384`, `None`), `ike_encryption`, `ike_integrity`, `ipsec_encryption`,
`ipsec_integrity`, `pfs_group`, plus `sa_datasize` of at least 1024 KB and
`sa_lifetime` of at least 300 seconds.

## Outputs

`id`, `name`, `type`, `resource_group_name`, `location`.

## Lifecycle contract

`shared_key`, `routing_weight`, `connection_mode`, BGP flags and `tags` update in
place. `type`, the remote endpoint ID and `virtual_network_gateway_id` replace the
connection. For ExpressRoute, create the connection only after the circuit's
provider status is `Provisioned`.

State exposure: `shared_key` and `authorization_key` are stored in state.

## Tests

`terraform test` (offline, `mock_provider`): ExpressRoute connection without a
shared key, endpoint-to-type enforcement for all three types, IPsec shared-key
requirement, an accepted IPsec/IKE policy, every enum and minimum above (accept
and reject), naming rules, and output wiring.
