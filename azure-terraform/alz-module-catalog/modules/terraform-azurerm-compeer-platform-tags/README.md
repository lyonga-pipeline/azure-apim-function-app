# Compeer Platform Tags

Produces a normalized enterprise tag map for platform and workload resources.
The module validates supplied values, removes unset tags, and reports missing
mandatory tags without enforcing their presence.

OPA and Azure Policy remain the ALZ enforcement layers. This separation lets
the same module support platform, workload, migration, and exception use cases.

## Usage

```hcl
resource "time_static" "deployment_created" {}

module "tags" {
  source = "app.terraform.io/Compeer-Financial-Services/compeer-platform-tags/azurerm"

  environment         = "prod"
  application         = "landing-zone"
  appcode             = "lz"
  owner               = "cloud-platform"
  source_repo         = "ado://project/repo"
  created_on          = formatdate("YYYY-MM-DD", time_static.deployment_created.rfc3339)
  criticality_tier    = "tier-0"
  data_classification = "confidential"
  lifecycle_state     = "active"
  cost_center         = "CC-1000"
  gl_category         = "opex-cloud"
}
```

Apply the output directly to resources:

```hcl
resource "azurerm_resource_group" "this" {
  name     = "example-rg"
  location = "centralus"
  tags     = module.tags.tags
}
```

## Tag Schema

| Requirement | Tags |
|---|---|
| Mandatory | `environment`, `application`, `appcode`, `owner`, `source_repo`, `created_on` |
| Mandatory | `criticality_tier`, `data_classification`, `lifecycle_state`, `cost_center`, `gl_category` |
| Optional | `application_component`, `modified_on`, `dr_tier` |
| Fixed | `created_by = "Terraform"` |
| Sandbox only | `expiration_date`, `time_bound_exception` |
| Extension | `additional_tags` |

Unset values are omitted from the output map. Controlled identifiers
(`environment`, `application`, `appcode`, and `application_component`) are
trimmed and lowercased. Other free-form values are trimmed while preserving
case.

### Approved Values

| Input | Accepted values |
|---|---|
| `environment` | `dev`, `test`, `uat`, `prod`, `sandbox`, `np1`, `np2`, `np3` |
| `data_classification` | `public`, `internal`, `confidential`, `restricted` |
| `lifecycle_state` | `active`, `temporary`, `pilot`, `decommission-pending`, `retired`, `exempt` |
| `criticality_tier` | `tier-0`, `tier-1`, `tier-2`, `tier-3`, `tier-4` |
| `dr_tier` | `gold`, `silver`, `bronze`, `none` |
| `appcode` | 1-9 letters |
| Date inputs | Real calendar dates in `YYYY-MM-DD` format |

POC deployments use `sandbox`. Existing landing-zone values `np1`, `np2`, and
`np3` represent dev, test, and UAT respectively.

### Lifecycle States

- `active`: approved and expected to continue operating.
- `temporary`: intentionally short-lived, such as a test lab or migration stage.
- `pilot`: part of a controlled rollout or limited production trial.
- `decommission-pending`: awaiting removal, archive, or migration validation.
- `retired`: no longer operating except for retained records or audit evidence.
- `exempt`: covered by an approved exception to normal lifecycle automation.

## Cross-Input Rules

Terraform loads `checks.tf` with the rest of the module. It validates rules
that involve more than one input:

- `sandbox` requires `expiration_date`.
- Other environments cannot set `expiration_date`.
- `time_bound_exception = true` requires both `environment = "sandbox"` and
  `lifecycle_state = "exempt"`.
- `modified_on` and `expiration_date` cannot be before `created_on`.
- `additional_tags` cannot contain a standard tag key. This prevents callers
  from bypassing the dedicated input validation.

Individual date variables use `timecmp` rather than a format-only regex. This
rejects impossible dates such as `2026-02-30`, not only malformed strings.

## Stable Creation Dates

`created_on` records the first deployment date. Do not set it with
`timestamp()`, because that function is evaluated again on later Terraform
runs and can cause recurring tag changes.

Use `time_static` in the consuming root. It creates the value once and stores
it in Terraform state:

```hcl
resource "time_static" "deployment_created" {}

created_on = formatdate(
  "YYYY-MM-DD",
  time_static.deployment_created.rfc3339
)
```

Use [`examples/basic`](examples/basic) when a root needs one shared deployment
date. Use
[`examples/keyed_deployment_timestamps`](examples/keyed_deployment_timestamps)
when entries in a growing `for_each` collection need independent creation
dates.

## Mandatory Tags

Mandatory inputs default to `null` intentionally. The module must not invent
business values such as an owner or cost center. `mandatory_keys` defines the
required schema, and `missing_mandatory` reports which values were not supplied.
Null values are filtered out before the final tag map is emitted.

This does not produce an error by itself. OPA and Azure Policy enforce the
required tags. A root that needs Terraform-side enforcement can use:

```hcl
lifecycle {
  precondition {
    condition     = length(module.tags.missing_mandatory) == 0
    error_message = "Missing mandatory tags: ${join(", ", module.tags.missing_mandatory)}"
  }
}
```

## Additional Tags

Use `additional_tags` only for metadata outside the standard schema:

```hcl
additional_tags = {
  business_unit = "technology"
}
```

A standard key such as `data_classification` is rejected in `additional_tags`.
Set standard tags through their dedicated module inputs.

## Outputs

| Output | Description |
|---|---|
| `tags` | Normalized, merged tag map with unset values removed |
| `missing_mandatory` | Mandatory keys that were not supplied |
| `mandatory_keys` | Standard mandatory tag keys |
| `all_standard_keys` | Complete standard tag vocabulary |

## Testing

Run the module tests:

```shell
terraform test
```

The main suite covers value validation, normalization, mandatory-tag reporting,
sandbox expiration rules, date ordering, and additional-tag collisions. Each
example also has tests proving that `time_static` values remain stable.
