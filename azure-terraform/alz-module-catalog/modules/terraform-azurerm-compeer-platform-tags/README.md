# terraform-azurerm-compeer-platform-tags

Produces the **normalized enterprise tag map** consumed by every pattern as
`module.tags.tags`. This is a frozen contract — the emitted tag **key** names
(`env`, `application`, `created_by`, `bt_owner`, `source_repo`, `tf_workspace`,
`recovery`, `cost_center`, `data_classification`, `compliance_boundary`) must not
change (7 consumers apply them to hundreds of resources).

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `environment` | string | — | validated: `np1` \| `np2` \| `np3` \| `prod` \| `shared` |
| `application` | string | — | app / service code |
| `data_classification` | string | `confidential` | validated: `public` \| `internal` \| `confidential` \| `restricted` |
| `compliance_boundary` | string | `finserv` | |
| `business_owner` / `source_repo` / `terraform_workspace` / `recovery_tier` / `cost_center` | string | `null` | null values are **dropped** from the map |
| `created_by` | string | `terraform` | |
| `additional_tags` | map(string) | `{}` | merged last (wins) |

## Outputs

`tags` — the merged, null-pruned map.

## Migration

Removed the drift-prone `creation_date_utc` / `last_modified_utc` inputs (no
consumer passed them; the doc flagged them). Added `environment` and
`data_classification` value validation. **Tag key names unchanged.**

## Tests

`terraform test` (offline): key mapping (`environment`→`env`,
`business_owner`→`bt_owner`), null pruning, environment + classification validation.
