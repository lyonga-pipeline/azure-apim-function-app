# terraform-azurerm-compeer-networking

> **⚠ Non-canonical — use [`terraform-azurerm-compeer-virtual-network`](../terraform-azurerm-compeer-virtual-network) instead** (the consumed VNet module). This module is kept working for backward compatibility; do not pick it for new work.


Virtual Network + subnets. This is a **resource module**: it owns the VNet and
its subnets and nothing else. Resource groups, DDoS protection plans, Network
Watcher, NSGs, route tables, private DNS zones and peerings are owned by their
dedicated modules and passed in by ID.

> Functionally equivalent to `terraform-azurerm-compeer-virtual-network`. Prefer
> that module for new consumers; this one is kept and maintained to the same
> standard for existing pipelines.

## Usage

```hcl
module "hub" {
  source = "../terraform-azurerm-compeer-networking"

  name                = "vnet-hub-prod"
  resource_group_name = module.rg.name
  location            = "eastus2"
  address_space       = ["10.0.0.0/16"]

  subnets = {
    AzureFirewallSubnet = { address_prefixes = ["10.0.0.0/26"] }
    shared-services     = { address_prefixes = ["10.0.1.0/24"] }
    private-endpoints = {
      address_prefixes                  = ["10.0.2.0/24"]
      private_endpoint_network_policies = "Disabled"
    }
  }

  tags = module.tags.tags
}
```

## Inputs (summary)

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` | string | — | ForceNew |
| `resource_group_name` | string | — | ForceNew |
| `location` | string | — | ForceNew |
| `address_space` | list(string) | — | update-in-place when adding prefixes; at least one required |
| `subnets` | map(object) | `{}` | keyed by subnet name; `optional()` fields; add/remove is additive |
| `dns_servers` | list(string) | `null` | update-in-place |
| `ddos_protection_plan_id` | string | `null` | update-in-place (associate/disassociate) |
| `encryption` | object | `null` | optional block |
| `bgp_community` / `edge_zone` | string | `null` | `edge_zone` is ForceNew |
| `flow_timeout_in_minutes` | number | `null` | validated 4-30 |
| `private_endpoint_vnet_policies` | string | `null` | `Disabled` \| `Basic` |
| `timeouts` | object | `{}` | passthrough |

## Outputs

`id`, `name`, `resource_group_name`, `location`, `address_space`, `guid`,
`subnet_ids` (name -> id), `subnet_names`, `subnets` (name -> {id,name,address_prefixes}).

## Lifecycle contract

| Change | Result |
|---|---|
| `tags`, `dns_servers`, `ddos_protection_plan_id`, `flow_timeout_in_minutes`, `bgp_community` | **update in place** |
| add a CIDR to `address_space` | update in place |
| add / remove a key in `subnets` | create / destroy **only that subnet** (stable `for_each` keys) |
| change a subnet's `address_prefixes` / `service_endpoints` / `delegations` / `private_endpoint_network_policies` | update in place on that subnet |
| add / remove the `encryption` block | update in place |
| change `name`, `resource_group_name`, `location`, `edge_zone` | **replace** (Azure ForceNew) |
| provider 4.x -> 5.x | not supported; pin holds at `< 5.0` pending qualification |

State exposure: none (no secret inputs).

## Migration from the pre-hardening contract

Breaking input/output renames (no compatibility shims):

| Old | New |
|---|---|
| `var.vnetwork_name` | `var.name` |
| `var.vnet_address_space` | `var.address_space` |
| `var.vnet_encryption` | `var.encryption` |
| `subnets[*].subnet_name` | the map key |
| `subnets[*].subnet_address_prefix` | `subnets[*].address_prefixes` |
| `subnets[*].delegations[*].service_delegation.{name,actions}` | `subnets[*].delegations[*].{name,actions}` |
| `output.vnet_id` | `output.id` |
| `output.vnet_name` | `output.name` |

Also removed: the standalone `azurerm_virtual_network_dns_servers` resource
(folded back into the VNet `dns_servers` argument) and the
`create_resource_group` / `create_network_watcher` toggles. Subnet
`private_endpoint_network_policies` default changed from `Disabled` to `Enabled`
to match Azure's own default — set it explicitly on private-endpoint subnets.

The subnet `for_each` key was already the map key, so no `moved` blocks are
needed; only the caller's variable/output references change.

## Tests

`terraform test` (offline, `mock_provider`): create, additive subnet add,
optional `encryption` block, validation rejection.

```bash
terraform test
```
