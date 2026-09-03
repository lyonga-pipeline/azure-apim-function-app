# terraform-azurerm-compeer-platform-tags

Produces the **normalized enterprise tag map** consumed by every pattern as
`module.tags.tags`. The module defines the **whole tag vocabulary** (design-doc
tag tables); every tag is an **optional** input, so a caller sets only the tags
it has values for and the output map drops the rest.

## Tag vocabulary (emitted keys are frozen)

| Category | Tags | Required |
|---|---|---|
| Operational | `environment`, `application`, `owner`, `source_repo`, `created_on` | **Mandatory** |
| Governance | `criticality_tier`, `data_classification`, `lifecycle_state` | **Mandatory** |
| Financial | `cost_center`, `gl_category` | **Mandatory** |
| Operational | `application_component`, `modified_on` | Optional |
| Operational / Governance | `created_by`, `dr_tier` | Conditional |
| Governance | `expiration_date` | Required for sandbox / temporary / POC / exception resources |

Plus `additional_tags` (`map(string)`) — merged last, wins on key collision.

## Enforcing the mandatory set

The module never fails on a missing mandatory tag (all inputs are optional).
`missing_mandatory` output lists the Required=Yes tags the caller didn't supply;
a caller that wants them enforced can:

```hcl
lifecycle {
  precondition {
    condition     = length(module.tags.missing_mandatory) == 0
    error_message = "Missing mandatory tags: ${join(", ", module.tags.missing_mandatory)}"
  }
}
```

## Outputs

| Output | Description |
|---|---|
| `tags` | the merged, null-pruned tag map |
| `missing_mandatory` | list of unsupplied Required=Yes tags (empty when all set) |

## Migration

**Breaking:** the schema changed to the design-doc tag tables.
- `data_classification` no longer defaults to `confidential`; `compliance_boundary`
  and its `finserv` default are gone. Both may be passed via `additional_tags`.
- Renames: `business_owner` → `owner`, `recovery_tier` → `dr_tier`.
- `terraform_workspace` removed (put it in `additional_tags` if wanted).
- Emitted key names changed to match the doc (`env` → `environment`,
  `bt_owner` → `owner`, `tf_workspace` gone, `recovery` → `dr_tier`,
  `compliance_boundary` gone). New keys: `created_on`, `criticality_tier`,
  `lifecycle_state`, `gl_category`, `application_component`, `modified_on`,
  `created_by`, `dr_tier`, `expiration_date`.

## Tests

`terraform test` (offline): only-supplied tags emitted, `missing_mandatory`
reporting, conditional + sandbox tags, `additional_tags` precedence,
`data_classification` validation.
