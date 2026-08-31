# terraform-azurerm-compeer-public-ip

A single `azurerm_public_ip`. Used by App Gateway, NAT Gateway, Bastion,
VPN/ER gateways and the route server.

## Inputs (selected)

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` / `resource_group_name` / `location` | string | — | ForceNew |
| `allocation_method` | string | `Static` | validated; Standard SKU requires Static (precondition) |
| `sku` | string | `Standard` | validated Basic/Standard; ForceNew |
| `sku_tier` | string | `Regional` | ForceNew |
| `ip_version` | string | `IPv4` | ForceNew |
| `zones` | list(string) | `[]` | ForceNew; set for zone-redundant Standard IPs |
| `idle_timeout_in_minutes` | number | `4` | update in place |
| `ddos_protection_mode` / `ddos_protection_plan_id` | string | `null` | update in place |
| `domain_name_label` / `reverse_fqdn` | string | `null` | update in place |
| `timeouts` | object | `{}` | passthrough |

## Outputs

`id`, `name`, `resource_group_name`, `location`, `ip_address`, `fqdn`, `zones`.

## Lifecycle contract

`idle_timeout_in_minutes`, `ddos_protection_*`, `domain_name_label`,
`reverse_fqdn`, `tags` → **update in place**. `sku`, `sku_tier`, `ip_version`,
`zones`, `allocation_method` on Basic, `name`/`rg`/`location` → **replace**.
`ip_address` is only known after apply for Dynamic IPs.

State exposure: none.

## Migration

Interface unchanged (5 consumers). Added `allocation_method` / `sku` validation
and the Standard-requires-Static precondition; input descriptions.

## Tests

`terraform test` (offline): Standard/Static defaults, Standard+Dynamic
precondition, bad-SKU validation.
