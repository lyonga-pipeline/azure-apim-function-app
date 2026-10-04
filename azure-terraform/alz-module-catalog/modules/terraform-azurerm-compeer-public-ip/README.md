# terraform-azurerm-compeer-public-ip

A single `azurerm_public_ip`. Use it for the public addresses required by
gateways, Route Server and network virtual appliances; workloads should stay on
private connectivity unless an approved edge pattern requires otherwise.

## Usage

```hcl
module "route_server_pip" {
  source = "../../modules/terraform-azurerm-compeer-public-ip"

  name                = "platform-cus-prod-rs-pip"
  resource_group_name = "platform-cus-prod-hybrid-rg"
  location            = "centralus"
  zones               = ["1", "2", "3"] # zone-redundant Standard IP
  tags                = module.tags.tags
}
```

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` | string | - | Azure naming rule: 1-80 chars, alphanumerics/underscore/period/hyphen, starts alphanumeric, ends alphanumeric or underscore; ForceNew |
| `resource_group_name` / `location` | string | - | non-empty; ForceNew |
| `allocation_method` | string | `Static` | `Static` or `Dynamic`; Standard SKU requires `Static` |
| `sku` | string | `Standard` | `Basic` or `Standard`; ForceNew |
| `sku_tier` | string | `Regional` | `Regional` or `Global`; `Global` requires Standard SKU; ForceNew |
| `ip_version` | string | `IPv4` | `IPv4` or `IPv6`; ForceNew |
| `zones` | list(string) | `[]` | requires Standard SKU; ForceNew |
| `idle_timeout_in_minutes` | number | `4` | 4-30 |
| `ddos_protection_mode` | string | `null` | `Disabled`, `Enabled` or `VirtualNetworkInherited` |
| `ddos_protection_plan_id` | string | `null` | only valid when `ddos_protection_mode = "Enabled"` |
| `domain_name_label` / `domain_name_label_scope` / `reverse_fqdn` | string | `null` | scope: `TenantReuse`, `SubscriptionReuse`, `ResourceGroupReuse` or `NoReuse` |
| `public_ip_prefix_id` / `edge_zone` / `ip_tags` | - | `null` / `{}` | pass-through |
| `timeouts` / `tags` | object / map | `{}` | pass-through |

## Validation

Enum checks on allocation method, SKU, tier, IP version, DNS label scope and
DDoS mode; idle-timeout range; the Azure resource-name rule; non-empty resource
group and location. Optional inputs left at `null` are accepted. Lifecycle
preconditions enforce the documented provider constraints: Standard SKU requires
Static allocation, zones and Global tier require Standard SKU, and a DDoS plan
requires mode `Enabled`.

## Outputs

`id`, `name`, `resource_group_name`, `location`, `ip_address` (known after apply
for Dynamic allocation), `fqdn`, `zones`.

## Lifecycle contract

`idle_timeout_in_minutes`, `ddos_protection_*`, `domain_name_label`,
`reverse_fqdn` and `tags` update in place. `sku`, `sku_tier`, `ip_version`,
`zones`, `name`, resource group and location replace the address, which changes
the IP.

State exposure: none.

## Tests

`terraform test` (offline, `mock_provider`): defaults and null-optional handling,
the zone-redundant Route Server shape, every validation and precondition (accept
and reject), and output wiring.
