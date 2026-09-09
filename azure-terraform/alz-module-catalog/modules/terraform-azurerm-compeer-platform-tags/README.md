# terraform-azurerm-compeer-platform-tags

Produces the **normalized enterprise tag map** consumed by platform and workload
patterns as `module.tags.tags`.

This module only sets and normalizes tags. Enforcement is intentionally handled
by OPA plan guardrails and Azure Policy, because enforcement posture can vary by
workspace, environment, exception status, and rollout phase.

The module defines the **whole tag vocabulary** from the design-doc tag tables.
Every tag is an **optional** input, so a caller sets only the tags it has values
for and the output map drops the rest.

## Tag vocabulary (emitted keys are frozen)

| Category | Tags | Required |
|---|---|---|
| Operational | `environment`, `application`, `owner`, `source_repo`, `created_on` | **Mandatory** |
| Governance | `criticality_tier`, `data_classification`, `lifecycle_state` | **Mandatory** |
| Financial | `cost_center`, `gl_category` | **Mandatory** |
| Operational | `application_component`, `modified_on` | Optional |
| Operational / Governance | `created_by`, `dr_tier` | Conditional |
| Governance | `expiration_date` | Required for sandbox / temporary / POC / exception resources |

Plus `additional_tags` (`map(string)`) for client- or workload-specific tags.
First-class standard tag inputs win on key collision so a caller cannot
accidentally override a standard tag value with an escape-hatch value.

## Enforcing the mandatory set

The module never fails on a missing mandatory tag. `missing_mandatory` output
lists the Required=Yes tags the caller did not supply. A consuming root can add
a precondition if a specific workspace wants Terraform-side enforcement, but the
normal ALZ enforcement path is OPA and Azure Policy.

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
| `mandatory_keys` | standard tag keys considered mandatory |
| `all_standard_keys` | full standard tag vocabulary before `additional_tags` are merged |

## Example

See `examples/basic` for the standard tag composition used by platform and
workload patterns.

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
reporting, conditional + sandbox tags, `additional_tags` fill behavior,
standard-tag precedence, `data_classification` validation, and date-format
validation.
