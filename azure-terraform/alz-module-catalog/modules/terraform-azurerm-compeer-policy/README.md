# terraform-azurerm-compeer-policy

Generic Azure Policy resource module: custom definitions/initiatives, MG/subscription/resource-group **assignments**, and policy **exemptions** (all three scopes) — nothing ALZ-specific lives here.

**Boundary:** this module knows how to turn an already-decided map into the matching `azurerm_policy_*` resources; it does not know which policies Compeer wants or where they apply. That's the calling pattern's job:

- [`global-governance`](../../patterns/terraform-azurerm-compeer-global-governance) decides the tenant-wide baseline (allowed regions, required tags, deny-public-PaaS, secure storage, restrict public IP, private SQL, MCSB) and calls this module.
- [`platform-policy`](../../patterns/terraform-azurerm-compeer-platform-policy) decides the private-only-connectivity guardrail and the DeployIfNotExists remediation bundle, and calls this module.

Every `management_group_id` / `subscription_id` / `resource_group_id` this module's variables take is a **concrete, already-resolved** resource ID — resolving an abstract catalog key (e.g. `management_group_key = "corp"`) into that ID happens in the calling pattern, because that catalog (a management-group hierarchy, a subscription list) lives outside this module's own resource graph. The one exception is `policy_definition_key` / `policy_set_definition_key` / `policy_assignment_key`, which resolve against a **sibling** definition/initiative/assignment this same module call also creates — that resolution has to stay here because the referenced ID is a value this module itself computes.

## Contract

Inputs are explicitly typed; repeatable configuration uses `map(object)` with caller-stable keys. See `variables.tf` for the full surface and `outputs.tf` for composition-ready IDs (including assignment `principal_id`s, for granting a DeployIfNotExists assignment's managed identity the roles its policy requires).

## Lifecycle

Configuration changes update in place unless the Azure resource marks the field ForceNew (name / location / scope / parent). Adding or removing a map key affects only that entry.

State exposure: only where a secret input or sensitive output is documented in `variables.tf` / `outputs.tf` — there are none; policy objects carry no secrets.

## History

Previously named `terraform-azurerm-compeer-policy-baseline` and marked retired in favor of inlining the same resources directly into `global-governance` and `platform-policy`. Re-extracted (and renamed, since it's not just a "baseline" mechanism) before the first client deployment, once the two patterns' inline copies had already drifted from each other — see each pattern's `main.tf` for the resolved-input locals that replace the old inline `azurerm_policy_*` resources.

## Tests

`terraform test` (offline, `mock_provider`): definitions, initiatives (including cross-references to sibling definitions), all 3 assignment scopes (identity, `not_scopes`, `non_compliance_messages`), all 3 exemption scopes (direct ID and key-based assignment resolution), and the validation rules.
