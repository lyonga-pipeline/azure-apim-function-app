# terraform-azurerm-compeer-bastion-host

A single `azurerm_bastion_host`. The `AzureBastionSubnet` and its Standard Static
Public IP are caller-owned and passed in by ID.

## Inputs (selected)

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` / `resource_group_name` / `location` | string | — | ForceNew |
| `bastion_subnet_id` | string | — | must be an `AzureBastionSubnet`; ForceNew |
| `public_ip_id` | string | — | externally managed Standard Static PIP |
| `sku` | string | `Standard` | validated Basic/Standard/Premium; ForceNew |
| `tunneling_enabled` / `file_copy_enabled` / `ip_connect_enabled` / ... | bool | see vars | Basic SKU rejects the advanced flags (precondition) |
| `scale_units` | number | `2` | Standard/Premium only |
| `zones` | list(string) | — | |

## Outputs

`id`, `name`, `dns_name`, `virtual_network_id`, `public_ip_id`.

## Lifecycle contract

`copy_paste_enabled`, `file_copy_enabled`, `tunneling_enabled`, `scale_units`,
`tags` → **update in place** (Standard/Premium). `sku`, `bastion_subnet_id`,
`public_ip_id`, `name`/`rg`/`location` → **replace**.

State exposure: none.

## Migration

Interface unchanged (1 consumer). Added `sku` validation and descriptions.

## Tests

`terraform test` (offline): Standard defaults, Basic-with-tunneling precondition,
bad-SKU rejection.
