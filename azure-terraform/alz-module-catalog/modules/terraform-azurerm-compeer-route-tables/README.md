# terraform-azurerm-compeer-route-tables

> **⚠ Non-canonical — use [`terraform-azurerm-compeer-route-table`](../terraform-azurerm-compeer-route-table) instead** (singular; used by the connectivity + workload-spoke patterns). This module is kept working for backward compatibility; do not pick it for new work.


Route table + its routes. Subnet association is a separate lifecycle domain,
owned by `terraform-azurerm-compeer-subnet-route-table-association`.

Equivalent to `terraform-azurerm-compeer-route-table` (singular); both are kept
and maintained to the same standard.

## Usage

```hcl
module "spoke_rt" {
  source              = "../terraform-azurerm-compeer-route-tables"
  name                = "rt-spoke-prod"
  location            = "eastus2"
  resource_group_name = module.rg.name

  routes = {
    default-to-firewall = {
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.0.0.4"
    }
  }

  tags = module.tags.tags
}
```

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` | string | — | ForceNew |
| `location` | string | — | ForceNew |
| `resource_group_name` | string | — | ForceNew |
| `bgp_route_propagation_enabled` | bool | `true` | update in place |
| `routes` | map(object) | `{}` | key = route name; `address_prefix`, `next_hop_type`, `next_hop_in_ip_address`; validated |
| `tags` | map(string) | `{}` | update in place |
| `timeouts` | object | `{}` | passthrough |

## Outputs

`id`, `name`, `resource_group_name`, `location`, `subnet_ids` (associations, managed externally).

## Lifecycle contract

| Change | Result |
|---|---|
| `tags`, `bgp_route_propagation_enabled` | **update in place** |
| add / remove / edit a key in `routes` | update in place — routes are inline, the table is never replaced |
| `name`, `location`, `resource_group_name` | **replace** (Azure ForceNew) |

State exposure: none.

## Migration from the pre-hardening contract

| Old | New |
|---|---|
| `var.route_table_name` | `var.name` |
| `var.routes` (`list(map(string))`, name inside each element) | `var.routes` (`map(object)`, key = route name) |
| `var.bgp_route_propagation_enabled` (required) | now defaults to `true` |
| `output.routes`, `output.tags` | removed (input echoes) |

No `moved` block needed — inline `route` blocks are attributes of the table.

## Tests

`terraform test` (offline): create, additive route add, validation rejection.
