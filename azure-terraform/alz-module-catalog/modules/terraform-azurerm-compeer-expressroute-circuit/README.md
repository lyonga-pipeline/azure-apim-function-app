# terraform-azurerm-compeer-expressroute-circuit

A single provider-model `azurerm_express_route_circuit`. This module creates the
circuit only; it does not create peerings (private peering is configured with the
provider once the circuit is provisioned), the gateway
(`terraform-azurerm-compeer-virtual-network-gateway`) or the gateway connection
(`terraform-azurerm-compeer-virtual-network-gateway-connection`).

## Usage

```hcl
module "circuit" {
  source = "../../modules/terraform-azurerm-compeer-expressroute-circuit"

  name                  = "platform-cus-prod-er"
  resource_group_name   = "platform-cus-prod-hybrid-rg"
  location              = "centralus"
  service_provider_name = "Equinix"
  peering_location      = "Chicago Metro"
  bandwidth_in_mbps     = 2000
  sku = {
    tier   = "Standard"
    family = "UnlimitedData"
  }
  tags = module.tags.tags
}
```

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` | string | - | Azure naming rule: 1-80 chars, alphanumerics/underscore/period/hyphen, starts alphanumeric, ends alphanumeric or underscore; ForceNew |
| `resource_group_name` / `location` | string | - | non-empty; ForceNew |
| `service_provider_name` / `peering_location` | string | - | non-empty; set together |
| `bandwidth_in_mbps` | number | - | whole number greater than zero; can be increased but not decreased |
| `sku` | object | `{ tier = "Standard", family = "MeteredData" }` | `tier`: `Basic`, `Local`, `Standard`, `Premium`; `family`: `MeteredData`, `UnlimitedData` |
| `allow_classic_operations` | bool | `false` | leave disabled unless a classic deployment requires it |
| `tags` | map(string) | `{}` | update in place |

Billing model: `family` can be upgraded from `MeteredData` to `UnlimitedData` but
not back. Set it deliberately; the default is `MeteredData`, so set
`UnlimitedData` explicitly where the design calls for an unlimited circuit.

## Outputs

| Output | Description |
|---|---|
| `id`, `name` | circuit identity |
| `service_key` | sensitive; hand to the connectivity provider to provision the circuit |
| `service_provider_provisioning_state` | provider-side state; the circuit must be `Provisioned` before the gateway connection is created |

## Lifecycle contract

`bandwidth_in_mbps` (increase only), `sku` upgrades and `tags` update in place.
`service_provider_name`, `peering_location`, `name`, resource group and location
replace the circuit. A circuit is a billed, provider-provisioned resource, so
review every plan for replacement.

State exposure: `service_key` is a sensitive output and is stored in state.

## Tests

`terraform test` (offline, `mock_provider`): the design circuit shape, default
SKU, tier/family validation, bandwidth validation, naming and required-string
rules, and output wiring.
