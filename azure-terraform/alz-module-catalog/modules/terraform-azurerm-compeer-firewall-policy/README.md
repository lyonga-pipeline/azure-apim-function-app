# terraform-azurerm-compeer-firewall-policy

A single `azurerm_firewall_policy`. Rule collection groups are separate resources
(compose them at the pattern layer, or add a companion module). The Azure
Firewall associates to this policy by ID via `azure-firewall`'s
`firewall_policy_id`.

## Inputs (selected)

`name`, `resource_group_name`, `location`; optional `sku`, `threat_intelligence_mode`,
`dns` (proxy), `identity`, `tls_certificate`, `intrusion_detection`.

## Outputs

`id`, `name`, `child_policies`, `firewalls`, `rule_collection_groups`.

## Lifecycle contract

Most settings → **update in place**. `sku` and `base_policy_id` → **replace**.
`name` / `rg` / `location` → **replace**.

State exposure: none directly.

## Tests

`terraform test` (offline): create.
