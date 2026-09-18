# terraform-azurerm-compeer-platform-tags

Produces the **normalized enterprise tag map** consumed by platform and workload
patterns as `module.tags.tags`.

This module validates the *shape* of every tag value it's given, and reports
which mandatory tags weren't supplied. It is deliberately NOT the enforcement
layer for whether a mandatory tag was supplied at all - that's handled by OPA
plan guardrails and Azure Policy, because enforcement posture can vary by
workspace, environment, exception status, and rollout phase.

The module defines the **whole tag vocabulary** from the FinOps tagging
standard's tag tables. Every tag is an **optional** input, so a caller sets
only the tags it has values for and the output map drops the rest.

## Tag vocabulary (emitted keys are frozen)

| Category | Tags | Required |
|---|---|---|
| Operational | `environment`, `application`, `appcode`, `owner`, `source_repo`, `created_on` | **Mandatory** |
| Governance | `criticality_tier`, `data_classification`, `lifecycle_state` | **Mandatory** |
| Financial | `cost_center`, `gl_category` | **Mandatory** |
| Operational | `application_component`, `modified_on` | Optional |
| Governance | `dr_tier`, `time_bound_exception` | Conditional / Optional |
| Operational | `created_by` | Fixed to `"Terraform"` |
| Governance | `expiration_date` | Required and permitted only when `environment` is `sandbox` - enforced by `check` blocks, see below |

Plus `additional_tags` (`map(string)`) for organization-specific metadata
**outside** this standard schema. It cannot contain a standard tag key at
all - see below.

### Validated value sets

Every tag below fails the plan with a clear message if set to anything outside
its approved list (source: the FinOps tagging standard's own tag tables):

| Tag | Approved values |
|---|---|
| `environment` | `dev`, `test`, `uat`, `prod`, `sandbox`, `np1`, `np2`, `np3`; POC deployments use `sandbox`, and existing-LZ aliases `np1`/`np2`/`np3` represent dev/test/uat |
| `data_classification` | `public`, `internal`, `confidential`, `restricted` |
| `lifecycle_state` | `active`, `temporary`, `pilot`, `decommission-pending`, `retired`, `exempt` - exact meanings below |
| `criticality_tier` | `tier-0` (foundational platform/enterprise service), `tier-1` (mission-critical business workload), `tier-2` (important business/operational workload), `tier-3` (low-criticality/non-production/temporary/disposable), `tier-4` |
| `dr_tier` | `gold`, `silver`, `bronze`, `none` |
| `appcode` | 1-9 letters only - the same identifier the naming module's own `appcode` input uses, so a resource's tag matches its actual name prefix |
| `created_by` | Fixed to exactly `"Terraform"` |
| `created_on`, `modified_on`, `expiration_date` | A real calendar date in `YYYY-MM-DD` format - `2026-99-99` or `2026-02-30` are rejected, not just wrong-shaped strings |
| `owner` | Non-empty team name, or a well-formed `user@domain` distribution-list address if it contains `@` |
| `source_repo` | Non-empty URI with a scheme, e.g. `ado://Compeer/landing-zone` or `https://github.com/org/repo` |
| `application`, `cost_center`, `gl_category`, `application_component` | Non-empty when supplied. `cost_center`/`gl_category` deliberately have no stricter format check yet - confirm the exact format with Finance before adding one |

### `lifecycle_state` - exact meanings (FinOps tag standard)

- **active** - Resource is approved, in use, and expected to continue operating.
  Use for production, shared, and long-lived non-production resources.
- **temporary** - Resource is intentionally short-lived and must have an
  expiration date. Use for sandboxes, POCs, test labs, one-time analysis, and
  migration staging.
- **pilot** - Resource supports a formal pilot or controlled rollout. Use for
  early cloud workloads, limited production trials, and PLANT-related pilots.
- **decommission-pending** - Resource is no longer strategically needed but has
  not yet been removed. Use for post-migration cleanup, dual-run transition,
  app retirement, and pending data/archive validation.
- **retired** - Resource should no longer be running or incurring meaningful
  cost. Use only for records, snapshots, final archive, or audit evidence;
  ideally time-boxed.
- **exempt** - Resource has an approved exception from normal lifecycle
  automation. Use for security tooling, shared platform services, DR
  dependencies, legal/audit hold, or vendor constraints. Set
  `time_bound_exception = true` only when the approved exception has a planned
  end date.

### Canonical emitted values

The output normalizes controlled identifiers so case and surrounding whitespace
cannot fragment cost reporting. `environment`, `application`, `appcode`, and
`application_component` are trimmed and lowercased. `owner`, `source_repo`,
`cost_center`, and `gl_category` are trimmed while preserving meaningful case.

### `created_by` is fixed to `"Terraform"`, not just defaulted

Every resource this module tags is deployed by Terraform - that's what
actually created it. `created_by` has `nullable = false` plus a `validation`
block that requires the literal value `"Terraform"`, so:
- An explicit `null` from a consuming pattern (e.g. an unset optional field on
  a `platform_tags` object flowing straight through as `null`) still resolves
  to `"Terraform"` - `nullable = false` makes Terraform substitute the default
  even for an explicit `null` argument, closing a real gap the previous
  plain-`default` implementation had.
- Any other value is rejected outright, not silently accepted and overridden -
  a caller can no longer set a stale identity here and have it silently
  discarded without a clear signal.

If a future non-Terraform deployment mechanism must be recorded here, remove
the `validation` block but keep `nullable = false`.

### `created_on` is never computed with `timestamp()`

`created_on` is meant to record when a resource was **first** deployed, not
today's date. Terraform's `timestamp()` function re-evaluates on every single
`plan`, which would put a diff on this tag - and therefore on every resource
carrying it - on every run, forever. That directly violates this tagging
standard's own core principle: *"Tag values are durable and do not frequently
change... tag changes must not require redeployment."*

This module stays a pure string-in-string-out variable: it validates whatever
frozen value it's handed, regardless of where that value came from. The
recommended source is a `time_static` resource declared in the **consuming
root**, not in this module - the root owns the deployment-lifecycle boundary:

```hcl
resource "time_static" "deployment_created" {}

module "tags" {
  source     = "../../modules/terraform-azurerm-compeer-platform-tags"
  created_on = formatdate("YYYY-MM-DD", time_static.deployment_created.rfc3339)
  # ...
}
```

`time_static` computes its value once, on first apply, and stores it in
state - every later plan reads the same value back instead of recomputing it.
See `examples/basic` for a full working example, and
`examples/basic/tests/basic.tftest.hcl` for a test that proves the value is
actually stable across a subsequent no-change plan (not just documented as
such).

For a root that deploys a **growing map** of similar resources over time (so
a single shared `time_static` would wrongly give every resource the same
`created_on`, including ones added months later), key `time_static` by the
same key as the resource map instead:

```hcl
resource "time_static" "storage_created" {
  for_each = var.storage_accounts
}
```

Adding a new key later creates only that key's `time_static` (and therefore
only that key's `created_on`) - every already-existing key keeps reading its
own value back from state, unchanged. See
`examples/keyed_deployment_timestamps` for a full working example and a test
that proves adding a key doesn't touch any existing key's timestamp.

A pipeline-generated, persisted date is an equally valid source for
`created_on` - `timestamp()` directly is the one thing to avoid.

### `expiration_date` requirement (`expiration_date_required` check)

Two `check` blocks (`checks.tf`) make the environment boundary explicit:

- `environment = "sandbox"` requires `expiration_date`.
- Every other approved environment rejects `expiration_date`, including
  `dev`, `test`, `uat`, `prod`, `np1`, `np2`, and `np3`. POC deployments
  are represented by `sandbox` and therefore follow the sandbox expiration rule.

`time_bound_exception = true` is permitted only for a sandbox resource with
`lifecycle_state = "exempt"`. `lifecycle_state = "temporary"` does not by
itself permit an expiration date outside sandbox.

This is a `check` block rather than a `variable` `validation` block because a
`validation` block can only see the variable it's declared on in Terraform
versions before 1.9, and this module supports 1.5+ (the same reason the
naming module uses `check` blocks for its own cross-input rules).

### Date ordering: `modified_on` / `expiration_date` vs `created_on`

Two more `check` blocks enforce that a resource's timeline is internally
consistent whenever both values are supplied: `modified_on` must not be
before `created_on`, and `expiration_date` must not be before `created_on`.
Malformed dates are left to each date's own `validation` block to report -
these checks only compare two values that are already individually valid.

### `additional_tags` cannot contain a standard tag key

`additional_tags` exists to extend the schema with organization-specific
metadata that is NOT part of the standard vocabulary above - it is not a
second way to set (or override) a standard tag. A `check` block
(`additional_tags_no_standard_key_overlap`) rejects the plan outright if
`additional_tags` contains any standard key name, e.g.
`additional_tags = { data_classification = "secret" }` - that value would
never go through `data_classification`'s own `contains()` validation, which
is exactly the bypass this exists to close. Use each standard tag's own
dedicated variable instead, even to leave it unset.

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

Put another way, `default = null` means the reusable module will not invent
business metadata such as an owner or cost center. `mandatory_keys` states
which of those values a compliant deployment must eventually supply. Null
values are filtered out of `tags`, reported through `missing_mandatory`, and
enforced by OPA/Azure Policy (or optionally by a consuming root precondition).
The defaults therefore do not need to be changed from `null` merely because a
key appears in `mandatory_keys`.

## Outputs

| Output | Description |
|---|---|
| `tags` | the merged, null-pruned tag map |
| `missing_mandatory` | list of unsupplied Required=Yes tags (empty when all set) |
| `mandatory_keys` | standard tag keys considered mandatory |
| `all_standard_keys` | full standard tag vocabulary before `additional_tags` are merged |

## Examples

- `examples/basic` - the standard tag composition used by platform and
  workload patterns, including the recommended root-owned `time_static`
  pattern for `created_on`.
- `examples/keyed_deployment_timestamps` - the per-resource variant of that
  same pattern, for a root that deploys a growing map of similar resources
  on different dates over time.

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
  `created_by`, `dr_tier`, `expiration_date`, `time_bound_exception`.
- `created_by` is now fixed to `"Terraform"` (previously just defaulted to
  it) - a caller passing anything else now fails the plan instead of having
  the value silently accepted.
- `additional_tags` can no longer contain a standard tag key at all - it
  previously allowed filling an unset standard key this way, with the
  first-class input winning only on an actual collision.
- `environment`, `owner`, `source_repo`, `application`, `cost_center`,
  `gl_category`, `application_component` now have their own shape
  validation (previously unvalidated) - see the tables above.
- `created_on`/`modified_on`/`expiration_date` now validate as real calendar
  dates, not just `YYYY-MM-DD`-shaped strings.

## Tests

`terraform test` (offline, 47 runs across `tests/defaults.tftest.hcl`), plus
2 example test suites (`examples/basic/tests`, 2 runs;
`examples/keyed_deployment_timestamps/tests`, 2 runs) exercising the real
`hashicorp/time` provider rather than mocks. Coverage: only-supplied tags
emitted, `missing_mandatory` reporting, `created_by` fixed-value enforcement
(omitted, explicit-null, and non-`"Terraform"` cases), `additional_tags`
standard-key rejection, every standard value-set validation (valid and
invalid cases), the sandbox-only `expiration_date` required/permitted checks,
the existing-LZ `np1`/`np2`/`np3` aliases, date-ordering checks (`modified_on`/
`expiration_date` vs `created_on`), empty-mandatory-value rejection,
malformed `owner`/`source_repo` rejection, impossible-calendar-date
rejection, the `time_static` stability guarantee, the keyed-`time_static`
independence guarantee, and the "does an all-null mandatory-tag call
actually error" investigation.
