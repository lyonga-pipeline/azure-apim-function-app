# terraform-azurerm-compeer-storage-account

Azure Storage **account** only (`azurerm_storage_account`). Containers, shares,
queues, tables, blob-inventory, lifecycle policy, immutability policy, private
endpoints and diagnostics are separate modules.

## Contract

- Required: `name`, `resource_group_name`, `location`.
- All optional Azure capabilities are typed optional objects — `identity`,
  `customer_managed_key`, `network_rules`, `blob_properties`,
  `queue_properties`, `share_properties`, `azure_files_authentication`,
  `custom_domain`, `immutability_policy`, `routing`, `sas_policy`,
  `static_website`, `timeouts`.
- Bounded scalars (`account_tier`, `account_replication_type`, `account_kind`,
  `access_tier`, `min_tls_version`, ...) carry `validation`.
- **Interface is frozen** — this module has downstream consumers
  (`platform-management`, `palo-alto-hub`). New capability is added via new
  optional inputs only.

## Lifecycle

| Change | Effect |
|---|---|
| `account_replication_type` (e.g. LRS<->GRS), `access_tier`, `min_tls_version`, `blob_properties`, `network_rules`, `identity`, `tags` | In-place update |
| `account_tier` Standard<->Premium | Replace |
| `account_kind`, `is_hns_enabled`, `edge_zone`, `name`, `resource_group_name`, `location` | Replace |

## State exposure

Access keys and SAS tokens are **not** exposed as outputs. Outputs cover `id`,
`name`, identity IDs, and the full set of primary service endpoints / hosts
(`primary_endpoints`, `primary_hosts`) plus
`private_endpoint_ready_subresource_names` for composition.

## Migration

No breaking changes — interface preserved for existing consumers.

## Tests

`terraform test` — create, name wiring, no-op replan.
