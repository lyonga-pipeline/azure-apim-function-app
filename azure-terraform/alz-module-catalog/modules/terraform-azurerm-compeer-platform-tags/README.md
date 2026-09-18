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
| Operational | `environment`, `application`, `appcode`, `owner`, `source_repo`, `created_on` | **Mandatory** |
| Governance | `criticality_tier`, `data_classification`, `lifecycle_state` | **Mandatory** |
| Financial | `cost_center`, `gl_category` | **Mandatory** |
| Operational | `application_component`, `modified_on` | Optional |
| Operational / Governance | `created_by`, `dr_tier` | Conditional |
| Governance | `expiration_date` | Required when `environment` is `sandbox` or anything other than `dev`/`test`/`uat`/`prod` - enforced by a `check` block, see below |

Plus `additional_tags` (`map(string)`) for client- or workload-specific tags.
First-class standard tag inputs win on key collision so a caller cannot
accidentally override a standard tag value with an escape-hatch value.

### Validated value sets

Every tag below fails the plan with a clear message if set to anything outside
its approved list (source: the FinOps tagging standard's own tag tables):

| Tag | Approved values |
|---|---|
| `data_classification` | `public`, `internal`, `confidential`, `restricted` |
| `lifecycle_state` | `active`, `temporary`, `pilot`, `decommission-pending`, `retired`, `exempt` |
| `criticality_tier` | `tier-0` (foundational platform/enterprise service), `tier-1` (mission-critical business workload), `tier-2` (important business/operational workload), `tier-3` (low-criticality/non-production/temporary/disposable), `tier-4` |
| `dr_tier` | `gold`, `silver`, `bronze`, `none` |
| `appcode` | 1-9 letters only - the same identifier the naming module's own `appcode` input uses, so a resource's tag matches its actual name prefix |
| `created_on`, `modified_on`, `expiration_date` | `YYYY-MM-DD` |

### `created_by` defaults to `"Terraform"`

Every resource this module tags is deployed by Terraform - that's what actually
created it, so it's the accurate default rather than a placeholder. Override it
with a real pipeline/service-principal identity only when a caller has a more
specific one and wants that recorded instead of the deployment mechanism.

### `created_on` is never computed with `timestamp()`

`created_on` is meant to record when a resource was **first** deployed, not
today's date. Terraform's `timestamp()` function re-evaluates on every single
`plan`, which would put a diff on this tag - and therefore on every resource
carrying it - on every run, forever. That directly violates this tagging
standard's own core principle: *"Tag values are durable and do not frequently
change... tag changes must not require redeployment."* The design doc's
"Auto-populated by CI/CD pipeline" note means the **pipeline** captures "first
deployed" once (e.g. only passing `-var created_on=...` on a resource's actual
first apply, or reading an existing value back from state/tags on every
subsequent one) and hands Terraform a frozen literal - Terraform itself has no
built-in way to know "is this really the first apply" without the same state
inspection the pipeline already has to do. This module stays a pure
string-in-string-out variable for exactly that reason.

### `expiration_date` and `environment`

A `check` block (`checks.tf`) enforces the design doc's "Required for sandbox,
POC, temporary, and exception resources" rule directly: if `environment` is
`"sandbox"` or anything other than `dev`/`test`/`uat`/`prod`, `expiration_date`
must be set. This is a `check` block rather than a `variable` `validation`
block because a `validation` block can only see the variable it's declared on
in Terraform versions before 1.9, and this module supports 1.5+ (the same
reason the naming module uses `check` blocks for its own cross-input rules).

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

**Is `mandatory_keys`/`missing_mandatory` redundant, given every mandatory
variable defaults to `null`?** No - tested directly (`all_mandatory_tags_unset_does_not_error`
in the test suite): calling the module with every mandatory variable left at
its `null` default does not error. `missing_mandatory` simply reports all of
them as missing, exactly as designed; nothing in the module itself ever fails
because of it. The mechanism *would* cause an error only if a **consuming
root** added the `precondition` shown above - and that's the intended trigger,
not a bug. Nothing in this module does that today (enforcement is OPA/Azure
Policy's job per the design above), so keep the block: it's the machinery a
workspace opts into for Terraform-side enforcement if it ever wants it,
verified safe to leave wired in even when unused.

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

`terraform test` (offline, 22 runs): only-supplied tags emitted,
`missing_mandatory` reporting, conditional + sandbox tags, `additional_tags`
fill behavior (including that the `created_by` default wins over an
`additional_tags` workaround value), standard-tag precedence,
`data_classification`/`lifecycle_state`/`criticality_tier`/`dr_tier`/`appcode`
validation (valid and invalid cases for each), the `expiration_date` +
`environment` cross-check (both directions), and the "does an all-null
mandatory-tag call actually error" investigation above.
