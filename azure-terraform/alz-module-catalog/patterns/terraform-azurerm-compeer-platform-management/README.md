# Platform Management Root

## Overview

**What this deploys:** the shared observability + subscription-hygiene
foundation every other platform/workload pattern reads from (Log Analytics
workspace ID, action group ID).

| Area | Resource | Purpose |
|---|---|---|
| Provider registrations | `azurerm_resource_provider_registration.registration` | Registers Azure resource providers (left unmanaged in the smoke-test tfvars — see below) |
| Budgets | `azurerm_consumption_budget_subscription.subscription_budget` | Subscription-scope cost budgets |
| Defender/SOC posture | `azurerm_security_center_contact.contact`, `.setting`, `.pricing` | Security contact + Defender plan pricing tiers — all left disabled/no-cost by default (see `defender_soc_posture` below) |
| Observability | `module.log_analytics_workspace`, `module.action_group`, `module.data_collection_*` | The Log Analytics workspace, action group, and optional Data Collection Endpoints/Rules other patterns consume |
| Platform storage | `platform_storage_accounts` | Diagnostics / artifact storage in the management subscription |

**`defender_soc_posture` — why a `terraform_data` contract instead of a plain
boolean flag:** the goal is a **no-cost posture marker** that Terraform
actively refuses to let drift silently — if `terraform.tfvars` ever claims
"Defender Standard is enabled" or "security contact is configured" without
actually setting the corresponding `defender_plans` / `security_contact`
inputs, the apply fails loudly at the `terraform_data.defender_soc_posture_contract`
precondition instead of silently deploying nothing while the tfvars claims
otherwise. See `tests/defender_soc_posture.tftest.hcl` for the exact
scenarios this catches.

---

This root creates the shared observability foundation for a landing-zone environment.

It produces the Log Analytics workspace ID and action group ID consumed by platform and workload roots. This is a net-new landing-zone monitoring boundary: workload roots send diagnostics to this workspace rather than requiring a separate Sentinel workspace per workload.

**Defender for Cloud / Sentinel enterprise baseline.** The deployable
`platform-management/terraform.tfvars` enables the platform SOC baseline:
Defender Standard plan entries for servers (P1), Storage, Key Vault, App
Services, SQL Servers, Containers, and ARM; Sentinel onboarding with the
module's baseline Palo Alto analytics rules and approved connector posture;
subscription Activity Log export; table-level Log Analytics retention for
active security tables; a Defender security contact; Service Health alerting;
budget alerts; and delete-protection locks. These are intentionally
cost-bearing controls. For a from-scratch smoke test with zero
Defender/Sentinel cost, set
`defender_plans = {}`, `sentinel.enabled = false`, and
`defender_soc_posture.defender_standard_enabled = false`.

`log_analytics_tables` manages Microsoft table retention where the security
operations design calls for a split between analytics retention and total
retention. The production tfvars currently models Compeer's stated 90-day
analytics retention and 1.5-year total retention for the active platform/SOC
tables. Do not add Entra tables (`AuditLogs`, `SigninLogs`) until tenant-level
Entra diagnostics are approved and connected.

`defender_soc_posture` records the Defender/SOC target state as a no-cost
contract-checked posture marker — it doesn't deploy anything itself, but
Terraform rejects a configuration that *claims* Defender Standard is enabled
without `defender_plans` actually backing that claim (or a security-contact
claim without `security_contact` configured). Data Collection Rules and Entra
tenant diagnostic export remain gated until target-resource onboarding and
tenant-level permissions are confirmed.

The identity/governance Sentinel rules in the pattern example
(`new_global_administrator`, `owner_role_assigned`, `pim_role_activation`,
`mg_or_policy_change`, and `password_spray_suspected`) are not active in the
deployable workspace tfvars. They are supported examples to enable after SOC
validates the connected `AuditLogs`, `AzureActivity`, and `SigninLogs` tables
plus incident routing.

The root now emits `defender_soc_posture` from a no-cost contract resource. Terraform will reject a configuration that claims Defender Standard or security contact posture is enabled unless the supporting `defender_plans` or `security_contact` inputs are also configured.

The smoke-test/example tfvars leave `security_contact = null` and
`security_center_settings = {}`. Defender settings such as `MCAS` and `WDATP`
commonly already exist in Azure subscriptions, so Terraform may need imports
before it can manage them. The enterprise tfvars manages `MCAS`; if the apply
reports that the setting already exists, import it into this workspace rather
than deleting it outside Terraform.

Optional `platform_storage_accounts` exposes the management-subscription storage
account placement from the ALZ workbook while staying disabled in the baseline
example tfvars:

| Component | Root input | Baseline posture |
| --- | --- | --- |
| `PLT-06` Platform storage accounts | `platform_storage_accounts` | Empty map, no resource created |

Populate this map only after retention and cost ownership are approved. Shared
platform Key Vaults belong to `platform-identity-security` in the security
subscription. Private endpoints belong to the connectivity subscription because
they attach to the hub VNet private endpoint subnet. Recovery Services vaults
belong with the protected workload subscription/resource group, such as the
identity-subscription DC backup vault in `platform-directory-services`.

Resource provider registrations are also left unmanaged in the smoke-test tfvars. Common providers are usually already registered in personal or shared subscriptions; import existing registrations before managing them with Terraform in an enterprise subscription.

Entra diagnostic settings are left unmanaged in the smoke-test tfvars because they are tenant-level `Microsoft.AADIAM` resources, not subscription resources. Enable them only when the HCP run identity has tenant-level permission to read and write Entra diagnostic settings.

Use this root for central monitoring, activity-log diagnostics, Entra diagnostics, action groups, subscription budgets, security contact configuration, Defender plan enablement, and future SOC integration. Security Operations owns data connectors, analytics rules, threat hunting content, ServiceNow/SIR integration, and incident response process choices after the platform baseline is available.

Azure Monitor Data Collection Endpoints, Data Collection Rules, and DCR associations are available through `data_collection_endpoints`, `data_collection_rules`, and `data_collection_rule_associations`. DCRs and associations are separate inputs so telemetry rules can be updated independently from the VMs, connectors, or other resources they target.

## HCP Azure Dynamic Credentials

If a run fails before planning with `AADSTS700213: No matching federated identity record found`, the Entra app configured by `TFC_AZURE_RUN_CLIENT_ID` does not trust this HCP workspace subject yet.

For workspace `platform-management` in HCP organization `lyonga-org` and project `demo`, create federated identity credentials on the Entra application for both run phases:

```text
organization:lyonga-org:project:demo:workspace:platform-management:run_phase:plan
organization:lyonga-org:project:demo:workspace:platform-management:run_phase:apply
```

Use issuer `https://app.terraform.io` with no trailing slash and audience `api://AzureADTokenExchange` unless `TFC_AZURE_WORKLOAD_IDENTITY_AUDIENCE` is explicitly configured. Repeat this per workspace because Azure federated identity credentials are matched by exact subject string.
