# Platform Policy Workspace

## Purpose

This deployable root applies the additional Azure Policy controls that are intentionally separate from the management-group hierarchy and initial governance baseline. It reads management-group IDs from `platform-governance` and the central Log Analytics workspace ID from `platform-management`.

The root deploys through [`terraform-azurerm-compeer-platform-policy`](../../../../patterns/terraform-azurerm-compeer-platform-policy).

## Deployment Order

1. Apply `platform-governance` to create the management-group hierarchy and initial baseline.
2. Apply `platform-management` when remediation policies need the Log Analytics workspace.
3. Review all enabled DINE effects and paid plans before applying `platform-policy`; use a pilot scope and Audit/Disabled effects where supported during validation.
4. Review compliance and approve exemptions.
5. Promote only approved controls to Deny.

## HCP Terraform Variables

Set these as workspace or variable-set values, not in committed tfvars:

| Variable | Category | Purpose |
|---|---|---|
| `tenant_id` | Terraform | Entra tenant ID. |
| `execution_subscription_id` | Terraform | Subscription context required by the AzureRM provider; policy resources can still be created at management-group scope. |
| `management_subscription_id` | Terraform | Optional actual management subscription UUID when the producer's public output is unavailable; preserves the Defender exclusion and must agree with the output when available. |
| `TFC_AZURE_PROVIDER_AUTH` | Environment | Enables HCP dynamic Azure credentials. |
| `TFC_AZURE_RUN_CLIENT_ID` | Environment | Client ID used by HCP dynamic credentials. |

The run identity needs policy definition, initiative, assignment, exemption, and remediation permissions at the scopes managed by this workspace. A subscription-level role alone does not grant management-group permissions.

## Policy Organization

`terraform.tfvars` is organized in this order:

1. Enterprise built-in assignments.
2. Workload-specific assignments.
3. Optional lower-scope assignments.
4. Exemptions.
5. DINE/Modify remediation.
6. Private-connectivity controls.

The governance baseline is not repeated here. See the pattern README for the complete component and Identity/RBAC design coverage matrix.

## Current Rollout State

- Approved resource types is non-enforcing until the resource catalog is finalized.
- Managed identity, Key Vault, TLS, disk encryption, and VM backup controls are audit/reporting controls.
- CIS is reporting-only and should remain non-enforcing.
- GOV-07 diagnostics remediation is enabled after `platform-management` publishes the central Log Analytics workspace ID. It assigns Microsoft's built-in resource-specific `allLogs` initiative at `compeer-enterprise-mg` for the Phase 1 catalog and common pilot workload services. Dedicated built-ins cover App Service and Function Apps.
- Diagnostic DINE excludes `platform-mg` and any additional explicitly Terraform-owned scopes. Platform resources receive audit-only assignments instead. DINE owns missing `allLogs` settings on remaining selected resources; it does not configure metrics. Application Insights and storage roots are excluded from the DINE catalog.
- Central US VNet flow-log child resources are Policy-owned separately from diagnostic settings. A strict custom definition requires the approved storage/workspace, enabled state, retention, interval and format. Exclude any Terraform-owned flow-log scopes separately. No deprecated workspace GUID is required.
- The checked-in Defender selection enables Servers P1, Storage with malware scanning and sensitive-data discovery, Key Vault, App Service, Azure SQL databases, SQL servers on machines, Containers, and Resource Manager at `compeer-enterprise-mg`. This preserves the prior selection; it is not evidence of client licensing approval or deployment. Servers P2 and Defender CSPM remain separate security/licensing decisions.
- The workspace grants each assignment identity its configured roles at that assignment's management-group scope. Diagnostic, Defender, and flow-log target scopes are independent. The run identity needs policy and role-assignment permissions at those scopes.
- Existing-resource remediation tasks remain disabled (`tasks = {}`) until a separately approved, bounded pilot. New-resource DINE evaluation can still deploy missing settings in Policy-owned scopes; disabling tasks is not disabling DINE.
- VM guest logs are intentionally excluded until an Azure Monitor Agent Data Collection Rule is approved and configured in `platform-management`.
- Policy remediation still depends on target subscriptions having the required resource providers registered (`Microsoft.Network`, `Microsoft.Security`, and service-specific providers). Subscription onboarding or each resource-owning workspace should register providers before remediation is expected to converge.
- Private connectivity starts in Audit.
- Sandbox and decommissioned management-group assignments must be configured before subscriptions are onboarded to those groups.

## Inputs From Other Workspaces

By default, HCP outputs are read from:

| Workspace | Output |
|---|---|
| `platform-governance` | `management_group_ids` |
| `platform-management` | `subscription_id` for Defender exclusion; `log_analytics_workspace_id` or `primary_log_analytics_workspace_id`; `log_analytics_workspace_location`; `platform_storage_account_ids.audit` for VNet flow logs |

Set `use_tfe_outputs = false` and provide `management_group_ids` directly only for isolated testing.

Only non-sensitive outputs are consumed. Use scoped HCP output access, not broad full-state access; an empty output map must be resolved before planning enforcement. Match workspace names to the client workspace names before running.

### Troubleshooting Ownership Preconditions

The contract reports producer workspace names, public output names, available MG keys, and unresolved diagnostic MG keys. These checks intentionally stop plans that would lose ownership exclusions; do not remove them to make a plan pass.

- A missing management subscription scope means the run cannot read `subscription_id` from the configured management producer. Verify the exact organization/workspace name, applied root output, non-sensitive classification, and scoped output access. A workspace visible in the UI is not proof that this run can read its public output. As a controlled alternative, set the root Terraform-category variable `management_subscription_id` to the actual management subscription UUID. Do not substitute `execution_subscription_id` unless the subscriptions are confirmed to be the same.
- `diagnostic_terraform_scopes = ["unset"]` means a configured Terraform-owned MG key cannot resolve to a non-empty ID. Verify `management_group_ids` from governance. The root `management_group_ids` map can override or supplement those outputs using the exact logical keys in `policy.diagnostic_ownership.terraform_management_group_keys`. Values can be actual MG IDs or full `/providers/Microsoft.Management/managementGroups/<id>` paths. Provide all other required keys when the producer's whole map is unavailable. A management-group display name is not its ID.
- An Application Insights failure means the effective `policy.remediation.dine_assignments.diagnostics_to_log_analytics.parameters.resourceTypeList.value` still includes `Microsoft.Insights/components` (case insensitive). Remove it there, not from the contract. The checked-in catalog already excludes it. Check workspace/variable-set `policy` values, `*.auto.tfvars`, and CLI variable overrides for an older whole object; changing `terraform.tfvars` alone may not change the effective configuration. Workspace-based Application Insights already sends telemetry to its underlying LAW and cannot use that same LAW as its diagnostic export destination.

Example root inputs in the policy workspace, with verified environment-specific values:

```hcl
management_workspace_name = "<actual-management-workspace-name>"
governance_workspace_name = "<actual-governance-workspace-name>"
management_subscription_id = "<actual-management-subscription-uuid>"
management_group_ids = {
  "platform-mg" = "/providers/Microsoft.Management/managementGroups/<actual-platform-mg-id>"
}
```

The last two inputs are optional fallbacks, not replacements for the central LAW/storage destination contract. Explicit input IDs do not grant HCP or Azure access, and a mismatch with a published management subscription ID still fails the plan. Keep `defender_for_cloud_policy.exclude_platform_management_subscription` enabled.

## Ownership And Duties

| Configuration | Lifecycle Owner | Security/Governance Responsibility |
|---|---|---|
| LAW, retention, Sentinel onboarding | platform-management | Security approves destination and retention |
| Management diagnostics, including audit blob logs | platform-management | Read-only policy audits; Terraform corrects findings |
| Connectivity, identity/security, workload diagnostics | Resource-owning workspace | Platform scopes excluded; workload owners must register an exclusion before adopting direct settings |
| Management-subscription Defender pricing | platform-management | Security approves direct plan configuration; fleet DINE excludes this subscription |
| Other targeted subscriptions' Defender pricing | platform-policy DINE | Security approves explicitly enabled plans and costs |
| Policy definitions, assignments, identities, RBAC, exemptions, tasks | platform-policy | Reviewed scope and remediation approval; governance retains its separate initial baseline |
| VNet flow-log children and Traffic Analytics | platform-policy DINE | Network/Security approve destinations, access and region; exclude any directly managed flow logs |
| Sentinel detections, connectors, hunting, ServiceNow integration | Security Operations | Existing Terraform baseline content remains in its current state until an explicit handover |

These are lifecycle boundaries, not automatically enforced human approval/RBAC separation. Use protected PRs, restricted workspace apply rights, and distinct run identities. Security Operations can approve Terraform-managed Sentinel content through PRs; do not also edit the same managed rules in the portal. An independent SOC workspace or external tool must first adopt/import those resources. Do not toggle off existing rules/connectors as a handover, because that can destroy them.

`configuration_ownership` publishes the effective policy exclusions and enabled plans. Management publishes `diagnostic_configuration` (actual storage targets/categories, not assumed defaults) and `defender_plan_configuration`. These outputs describe desired configuration, not live compliance evidence.

The platform audits cover selected catalog types, App Service/Functions, and explicit Key Vault/Bastion/blob profiles. They do not cover VM guest logs, every future storage service, or subscription Activity Log export across the enterprise. Add service-specific profiles and AMA/DCR or Activity Log controls when approved. For `additional_terraform_scopes` outside platform-mg, configure an equivalent audit assignment/CI check explicitly; the exclusion alone does not create one. Metrics and unsupported services remain direct workspace responsibilities.

## Controlled Rollout

1. Review the management plan: the audit account is pinned to the known deployed `cfaudit6e1ecusprdsa` name. No account replacement is intended. Apply blob diagnostics and publish public contracts.
2. Inventory existing Policy/Terraform diagnostic settings. Exclusions stop future writes but do not delete prior duplicates. Confirm one intended ingestion path per resource and retain evidence before any cleanup.
3. Verify all MG keys, ancestry, workspace names, existing assignments, and resource providers in the client environment. This code cannot detect other assignments already inherited in Azure. Check licensing and intentional differences between management and fleet Defender baselines.
4. Validate custom policy aliases/ARM templates with an Azure pilot, inspect compliance and ingestion, then approve scope expansion. Changing the flow definition may replace its policy assignment/identity; inspect that plan and ensure the old assignment is retired so only one flow-log writer remains.
5. Apply identities/RBAC with `tasks = {}`. After role propagation and a compliance scan, add only approved tasks. For an initiative, obtain its child reference IDs with:

```bash
az policy set-definition show --name 0884adba-2312-4468-abeb-5422caed1038 \
  --query 'policyDefinitions[].{reference:policyDefinitionReferenceId,id:policyDefinitionId}'
```

Example inside the existing `policy.remediation` object:

```hcl
tasks = {
  flow-pilot-01 = {
    assignment_key       = "vnet_flow_logs_traffic_analytics"
    location_filters     = ["centralus"]
    resource_count       = 20
    parallel_deployments = 2
    failure_percentage   = 0.1
  }
}
```

A region filter/resource count limits size, not an exact resource allowlist. Use a pilot MG/scope for precise targeting. Initiative tasks additionally require the actual verified `policy_definition_reference_id`. Start a new task revision only after another approval; do not repeatedly rerun blindly.

For a Policy-to-Terraform handover: exclude the target scope first, freeze concurrent changes, match the intended configuration to the existing setting, import it into exactly one owning state, and confirm a no-op plan. For Terraform-to-SOC handover, use a reviewed `removed` block with `destroy = false` and adopt the resource in the new owner; do not merely remove its resource block. Never mask competing writers with `ignore_changes`.

## Validation

```bash
terraform fmt -check
terraform init -backend=false
terraform validate
terraform test
```

Run the pattern tests from `patterns/terraform-azurerm-compeer-platform-policy` before a live plan.
