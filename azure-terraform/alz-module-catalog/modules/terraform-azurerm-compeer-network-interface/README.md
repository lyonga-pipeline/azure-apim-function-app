# terraform-azurerm-compeer-network-interface

A single `azurerm_network_interface`. IP configurations are a `map(object)` keyed
by config name. Used by the VM and directory-services patterns.

## Inputs (selected)

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` / `resource_group_name` / `location` | string | — | ForceNew |
| `ip_configurations` | map(object) | — | ≥1 required (validated); `{subnet_id, private_ip_address_allocation(Static\|Dynamic), private_ip_address?, primary?, public_ip_address_id?, ...}`; Static requires `private_ip_address` (validated) |
| `accelerated_networking_enabled` | bool | `true` | update in place (v4 name) |
| `ip_forwarding_enabled` | bool | `false` | update in place (v4 name) |
| `dns_servers` | list(string) | `null` | update in place |

## Outputs

`id`, `name`, `resource_group_name`, `mac_address`, `private_ip_address`,
`private_ip_addresses`, `ip_configurations` (composite, keyed by config name).

## Lifecycle contract

`ip_configurations` (add/edit/remove entries), `dns_servers`,
`accelerated_networking_enabled`, `ip_forwarding_enabled`, `tags` → **update in
place**. `name` / `resource_group_name` / `location` → **replace**.

State exposure: none.

## Migration

**Fixed broken outputs:** `ip_configuration_ids` and `ip_configurations[*].id`
referenced a non-existent `id` attribute on the ip_configuration block (azurerm
4.x) — removed / corrected. Added `≥1 ip_configuration` and allocation-method
validation; input descriptions.

## Tests

`terraform test` (offline): create, no-ipconfig rejection, bad-allocation rejection.
