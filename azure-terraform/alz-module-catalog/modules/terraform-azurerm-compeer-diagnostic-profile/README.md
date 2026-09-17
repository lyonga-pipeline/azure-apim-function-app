# terraform-azurerm-compeer-diagnostic-profile

Pure-constants module (no resources, no provider) that defines the platform's
**canonical default diagnostic-settings profile** — Platform_Output_Contracts_IAC-10's
`management_diagnostic_profile`: `object({ log_categories, metric_categories, destination_key })`.

## Why this exists

Every pattern in this catalog that calls `terraform-azurerm-compeer-diagnostic-settings`
authors its own `logs`/`metrics` map independently — reasonable for a
resource-specific category (Bastion's `BastionAuditLogs` isn't something any
other resource type even has), but there was no single place that answered
"what does *properly monitored* mean for this landing zone as a baseline,"
and the GOV-07 DeployIfNotExists remediation policy that auto-fixes missing
diagnostics has to encode that same answer somewhere too. This module is that
one place — instantiated by `platform-management` (which owns the
destination, the Log Analytics workspace) and published as
`management_diagnostic_profile` for every other root and for audit evidence.

`allLogs` / `AllMetrics` are Azure's own "send everything" category-group
idiom — every resource type that supports diagnostic settings supports
category groups, so this profile never needs a per-resource-type category
list to stay current as Azure adds new log categories to a resource type.

## What this module deliberately does NOT do

It does not change what any existing pattern's `diagnostic_settings` calls
actually send today. Defaulting every diagnostic-capable resource in the
catalog to `allLogs` would be a real, resource-type-dependent increase in Log
Analytics ingestion volume and cost — a decision for whoever owns that
budget, not something a shared module should force silently. Treat this
profile as the **recommended default for new diagnostic_settings entries**
and as the reference the GOV-07 DINE policy's own parameters should be kept
aligned with; retrofitting existing resources to it is a deliberate,
separate, cost-reviewed change.

## Usage

```hcl
module "diagnostic_profile" {
  source = "../../modules/terraform-azurerm-compeer-diagnostic-profile"
}

# A new diagnostic_settings entry that wants the platform default:
logs = {
  for category_group in module.diagnostic_profile.log_categories : category_group => {
    category_group = category_group
  }
}
metrics = {
  for category in module.diagnostic_profile.metric_categories : category => {
    category = category
  }
}
```

## Tests

`terraform test` (offline, no provider needed): default values resolve as
documented, and an override produces the expected profile shape.
