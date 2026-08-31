# terraform-azurerm-compeer-private-dns-a-record

Private DNS A records (`azurerm_private_dns_a_record`) keyed by a stable logical
key. The zone is referenced by name — zone creation is a separate module.

## Inputs

`records` — `map(object({ name, zone_name, resource_group_name, ttl?=300,
records=list(string), tags? }))`. `ttl` and non-empty `records` are validated.

## Outputs

`ids`, `names`, `fqdns` — keyed by input key.

## Lifecycle contract

`ttl`, `records`, `tags` → **update in place**. `name` / `zone_name` /
`resource_group_name` → **replace** that record. Adding / removing a key affects
only that record.

State exposure: none.

## Migration

Added `ttl` / non-empty-`records` validation and `names` / `fqdns` outputs.

## Tests

`terraform test` (offline): create with default TTL, empty-records rejection.
