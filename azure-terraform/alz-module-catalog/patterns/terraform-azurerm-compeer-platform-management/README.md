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
| Platform hooks | `platform_storage_accounts`, `platform_key_vaults`, `recovery_services_vaults` | Deployable but empty-by-default hooks for platform services (see table below) |

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

It produces the Log Analytics workspace ID and action group ID consumed by platform and workload roots.

For short smoke tests, `terraform.tfvars` leaves `defender_plans = {}` so Microsoft Defender for Cloud paid Standard plans are not enabled accidentally. The Standard plan map is left commented in the tfvars file; uncomment it only after cost approval and when you are ready to test the security baseline.

`defender_soc_posture` is intentionally present but disabled. It records the Defender/SOC target state without deploying Defender Standard, Sentinel, Data Collection Rules, or other paid SOC resources by default. Use it as the no-cost enterprise posture marker until the SOC design and cost approval are complete.

The root now emits `defender_soc_posture` from a no-cost contract resource. Terraform will reject a configuration that claims Defender Standard or security contact posture is enabled unless the supporting `defender_plans` or `security_contact` inputs are also configured.

The smoke-test tfvars also leave `security_contact = null` and `security_center_settings = {}`. Defender settings such as `MCAS` and `WDATP` commonly already exist in Azure subscriptions, so Terraform must import them before it can manage them. Leave them unmanaged for quick platform validation; import and enable them when promoting the enterprise security baseline.

Optional `platform_storage_accounts`, `platform_key_vaults`, and `recovery_services_vaults` expose deployable hooks for platform services from the ALZ workbook while staying disabled in the baseline tfvars:

| Component | Root input | Baseline posture |
| --- | --- | --- |
| `PLT-01` Recovery Services Vault + policies | `recovery_services_vaults` | Empty map, no resource created |
| `PLT-02` Platform Key Vault + private endpoint | `platform_key_vaults`, `platform_key_vault_private_endpoints` | Empty maps, no resource created |
| `PLT-06` Platform storage accounts | `platform_storage_accounts` | Empty map, no resource created |

Populate these maps only after retention, backup policy, private connectivity, encryption, secret ownership, and cost ownership are approved. The Key Vault module owns only the vault resource. Secrets, keys, certificates, private endpoints, diagnostics, RBAC, and locks are composed by the platform pattern so the base module remains reusable.

Resource provider registrations are also left unmanaged in the smoke-test tfvars. Common providers are usually already registered in personal or shared subscriptions; import existing registrations before managing them with Terraform in an enterprise subscription.

Entra diagnostic settings are left unmanaged in the smoke-test tfvars because they are tenant-level `Microsoft.AADIAM` resources, not subscription resources. Enable them only when the HCP run identity has tenant-level permission to read and write Entra diagnostic settings.

Use this root for central monitoring, activity-log diagnostics, Entra diagnostics, action groups, subscription budgets, security contact configuration, Defender plan enablement, and future SOC integration. Add Sentinel onboarding and data-collection rules here when the SOC/SIEM design is approved.

Azure Monitor Data Collection Endpoints, Data Collection Rules, and DCR associations are available through `data_collection_endpoints`, `data_collection_rules`, and `data_collection_rule_associations`. DCRs and associations are separate inputs so telemetry rules can be updated independently from the VMs, connectors, or other resources they target.

## HCP Azure Dynamic Credentials

If a run fails before planning with `AADSTS700213: No matching federated identity record found`, the Entra app configured by `TFC_AZURE_RUN_CLIENT_ID` does not trust this HCP workspace subject yet.

For workspace `platform-management` in HCP organization `lyonga-org` and project `demo`, create federated identity credentials on the Entra application for both run phases:

```text
organization:lyonga-org:project:demo:workspace:platform-management:run_phase:plan
organization:lyonga-org:project:demo:workspace:platform-management:run_phase:apply
```

Use issuer `https://app.terraform.io` with no trailing slash and audience `api://AzureADTokenExchange` unless `TFC_AZURE_WORKLOAD_IDENTITY_AUDIENCE` is explicitly configured. Repeat this per workspace because Azure federated identity credentials are matched by exact subject string.
