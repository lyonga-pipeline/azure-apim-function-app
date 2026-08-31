# terraform-azurerm-compeer-nat-gateway

A single `azurerm_nat_gateway`. Public IP / prefix association and
subnet association are separate resources — compose them at the pattern layer
(a NAT gateway with no public IP does nothing).

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` / `location` / `resource_group_name` | string | — | ForceNew |
| `sku_name` | string | `Standard` | |
| `idle_timeout_in_minutes` | number | `4` | validated 4-120; update in place |
| `zones` | list(string) | `null` | zonal; ForceNew |
| `tags` | map(string) | `{}` | update in place |

## Outputs

`id`, `name`, `resource_group_name`.

## Lifecycle contract

`idle_timeout_in_minutes`, `tags` → **update in place**. `name` / `location` /
`resource_group_name` / `sku_name` / `zones` → **replace**.

State exposure: none.

## Migration

`nat_gateway_name` → `name`; `output.nat_gateway_id` → `id`,
`nat_gateway_name` → `name` (0 consumers). Added `idle_timeout_in_minutes`
validation and descriptions. Removed the dead `data.tf`.

## Tests

`terraform test` (offline): create, bad-idle-timeout rejection.
