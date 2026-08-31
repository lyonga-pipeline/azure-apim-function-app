# terraform-azurerm-compeer-virtual-network

The **canonical** VNet + subnets module (used by both the hub connectivity and
workload-spoke patterns). Subnets are a `map(object)` keyed by name — adding or
removing a subnet never re-creates the others. NSGs, route tables, DDoS plans,
DNS zones and peerings are owned by their dedicated modules and passed in by ID.

`networking` is the equivalent legacy-named module (also maintained).

## Inputs (selected)

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` / `resource_group_name` / `location` | string | — | ForceNew |
| `address_space` | list(string) | — | ≥1 CIDR (validated); adding prefixes is in-place |
| `subnets` | map(object) | `{}` | key = subnet name; `optional()` for endpoints, delegations (map), policies, ip_address_pool, timeouts |
| `dns_servers` | list(string) | `null` | update in place |
| `ddos_protection_plan_id` + `enable_ddos_protection_plan` | string / bool | `null` / `true` | update in place |
| `encryption` | object | `null` | validated enforcement |
| `flow_timeout_in_minutes` | number | `null` | validated 4-30 |
| `private_endpoint_vnet_policies` | string | `null` | Disabled \| Basic |

## Outputs

`id`, `name`, `resource_group_name`, `location`, `guid`, `address_space`,
`dns_servers`, `subnet_ids`, `subnet_names`, `subnets` (composite).

## Lifecycle contract

| Change | Result |
|---|---|
| `tags`, `dns_servers`, `ddos_protection_plan_id`, add a CIDR, `flow_timeout_in_minutes` | **update in place** |
| add / remove a `subnets` key | create / destroy **only that subnet** |
| change a subnet's prefixes / endpoints / delegations / policies | update in place on that subnet |
| `name`, `resource_group_name`, `location`, `edge_zone` | **replace** |

State exposure: none.

## Migration

Interface unchanged (2 consumers). Added `address_space` non-empty and
`flow_timeout_in_minutes` range validation; input descriptions. (Fixed the
`encryption` validation null-deref in an earlier sweep.)

## Tests

`terraform test` (offline): create, additive subnet add, empty-address_space
rejection.
