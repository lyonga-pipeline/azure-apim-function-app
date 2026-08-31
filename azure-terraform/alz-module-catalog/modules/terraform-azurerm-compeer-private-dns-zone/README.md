# terraform-azurerm-compeer-private-dns-zone

Private DNS **zones** keyed by a stable logical key (`azurerm_private_dns_zone`
via `for_each`). VNet links and records are separate lifecycle domains
(`private-dns-vnet-link`, `private-dns-a-record`).

## Usage

```hcl
module "zones" {
  source = "../terraform-azurerm-compeer-private-dns-zone"
  tags   = module.tags.tags
  zones = {
    kv   = { name = "privatelink.vaultcore.azure.net",  resource_group_name = module.rg.name }
    blob = { name = "privatelink.blob.core.windows.net", resource_group_name = module.rg.name }
  }
}
```

## Inputs

`zones` — `map(object({ name, resource_group_name, tags? }))`, zone name
validated. `tags` — merged onto every zone.

## Outputs

`ids`, `names`, `resource_group_names`, `zones` (composite) — keyed by input key.

## Lifecycle contract

`tags` → update in place. `name` / `resource_group_name` → **replace** that zone.
Adding / removing a map key affects only that zone. Private DNS zones are durable
— routine upgrades must not recreate them.

State exposure: none.

## Migration

Interface unchanged (1 consumer). Added zone-name validation and descriptions.

## Tests

`terraform test` (offline): create, zone-name validation.
