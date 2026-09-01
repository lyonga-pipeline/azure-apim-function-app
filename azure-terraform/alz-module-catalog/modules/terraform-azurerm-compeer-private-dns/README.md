# terraform-azurerm-compeer-private-dns

> **⚠ Non-canonical — use [`terraform-azurerm-compeer-private-dns-zone`](../terraform-azurerm-compeer-private-dns-zone) instead** (keyed multi-zone; consumed by platform-connectivity). This module is kept working for backward compatibility; do not pick it for new work.


Manages a **set** of Azure Private DNS zones and their VNet links. Use this when
one owner (typically the connectivity hub) manages all the `privatelink.*` zones
for an estate. For a single independently-owned zone use
`terraform-azurerm-compeer-private-dns-zone` +
`terraform-azurerm-compeer-private-dns-vnet-link`.

Ownership boundary: zones and links only. Record sets are owned by
`terraform-azurerm-compeer-private-dns-a-record` and friends.

## Usage

```hcl
module "private_dns" {
  source              = "../terraform-azurerm-compeer-private-dns"
  resource_group_name = module.rg.name
  tags                = module.tags.tags

  zones = {
    "privatelink.vaultcore.azure.net"  = {}
    "privatelink.blob.core.windows.net" = {}
    "privatelink.database.windows.net" = {
      vnet_links = {
        hub = { virtual_network_id = module.hub.id }
      }
    }
  }
}
```

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `resource_group_name` | string | — | default RG for zones/links |
| `zones` | map(object) | `{}` | key = zone name; per-zone `resource_group_name`, `tags`, `soa_record`, `vnet_links` (map keyed by logical name) |
| `tags` | map(string) | `{}` | merged onto every zone and link |

## Outputs

`zone_ids` (name→id), `zone_names`, `zones` (name→{id,name,number_of_record_sets}),
`vnet_link_ids` ("zone/link"→id).

## Lifecycle contract

| Change | Result |
|---|---|
| add / remove a key in `zones` | create / destroy **only that zone** (stable keys) |
| add / remove a `vnet_links` entry under a zone | create / destroy **only that link** (composite `zone/link` key) |
| `tags`, `soa_record` fields, `registration_enabled` | **update in place** |
| rename a zone key, or change a link's `virtual_network_id` | **replace** that zone / link (Azure ForceNew) |
| `resource_group_name` on an existing zone/link | **replace** |

State exposure: none.

## Migration from the pre-hardening contract

Single-zone → multi-zone. No compatibility shims.

| Old | New |
|---|---|
| `var.private_dns_zone_name` | a key in `var.zones` |
| `var.private_dns_zone_tags` | `var.zones[<name>].tags` or module-level `var.tags` |
| `var.soa_record` (list) | `var.zones[<name>].soa_record` (single object) |
| `output.private_dns_zone_id` | `output.zone_ids[<name>]` |
| `output.private_dns_zone_name` | `output.zone_names[<name>]` |

`moved` blocks are required to preserve state:

```hcl
moved {
  from = azurerm_private_dns_zone.private_dns_zone
  to   = azurerm_private_dns_zone.this["privatelink.vaultcore.azure.net"]
}
```

## Tests

`terraform test` (offline): create, additive zone add, validation rejection.
