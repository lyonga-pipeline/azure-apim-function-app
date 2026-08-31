# terraform-azurerm-compeer-load-balancer

A single `azurerm_lb` and its frontend IP configurations (`map(object)` keyed by
name). Backend pools, probes and rules are separate resources — compose at the
pattern layer or via a companion module.

## Inputs (selected)

`name`, `resource_group_name`, `location`; `sku` (default `Standard`), `sku_tier`;
`frontend_ip_configurations` — `map(object({ subnet_id?, private_ip_address?,
private_ip_address_allocation?, public_ip_address_id?, zones?, ... }))`.

## Outputs

`id`, `name`, `frontend_ip_configuration` (composite), `private_ip_addresses`.

## Lifecycle contract

Frontend IP config add/edit/remove, `tags` → **update in place**. `sku`,
`sku_tier`, `name` / `rg` / `location` → **replace**.

State exposure: none.

## Tests

`terraform test` (offline): create (Standard default).
