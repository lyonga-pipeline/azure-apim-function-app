# terraform-azurerm-compeer-private-dns-vnet-link

Private DNS zone ↔ VNet links (`azurerm_private_dns_zone_virtual_network_link`)
keyed by a stable logical key. Zones and records are separate modules. Used by the
hub connectivity pattern to link every `privatelink.*` zone to the hub and to
each spoke.

## Inputs

`links` — `map(object({ name, resource_group_name, private_dns_zone_name,
virtual_network_id, registration_enabled?, tags? }))`. `tags` merged onto each.

## Outputs

`ids`, `names`, `links` (composite) — keyed by input key.

## Lifecycle contract

`registration_enabled`, `tags` → **update in place**. `name` /
`private_dns_zone_name` / `virtual_network_id` / `resource_group_name` →
**replace** that link. Adding / removing a key affects only that link.

State exposure: none.

## Migration

Interface unchanged (3 consumers). Only tests + docs added.

## Tests

`terraform test` (offline): create with `registration_enabled` default.
