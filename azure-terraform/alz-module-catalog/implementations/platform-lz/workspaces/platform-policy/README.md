# Platform Policy Workspace

## Purpose

This deployable root applies the additional Azure Policy controls that are intentionally separate from the management-group hierarchy and initial governance baseline. It reads management-group IDs from `platform-governance` and the central Log Analytics workspace ID from `platform-management`.

The root deploys through [`terraform-azurerm-compeer-platform-policy`](../../../../patterns/terraform-azurerm-compeer-platform-policy).

## Deployment Order

1. Apply `platform-governance` to create the management-group hierarchy and initial baseline.
2. Apply `platform-management` when remediation policies need the Log Analytics workspace.
3. Apply `platform-policy` in Audit/non-enforcing mode.
4. Review compliance and approve exemptions.
5. Promote only approved controls to Deny.

## HCP Terraform Variables

Set these as workspace or variable-set values, not in committed tfvars:

| Variable | Category | Purpose |
|---|---|---|
| `tenant_id` | Terraform | Entra tenant ID. |
| `execution_subscription_id` | Terraform | Subscription context required by the AzureRM provider; policy resources can still be created at management-group scope. |
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
- The policy assignment creates `setByPolicy-LogAnalytics` only when no compliant diagnostic setting already targets the central workspace. Terraform remains the primary diagnostics owner for approved patterns; DINE is the backstop.
- VNet flow logs with Traffic Analytics are enabled by policy for Central US VNets. The policy uses the platform Log Analytics workspace GUID/resource ID and the management subscription's `audit` storage account ID; set `network_flow_logging_policy.storage_account_id` if a dedicated flow-log storage account is approved later.
- Microsoft Defender for Cloud plan auto-enablement is enabled at `compeer-enterprise-mg` for the approved baseline: Servers P1, Storage with malware scanning and sensitive-data discovery, Key Vault, App Service, Azure SQL databases, SQL servers on machines, Containers, and Resource Manager. Servers P2 and Defender CSPM remain explicit security/licensing decisions.
- The workspace also grants the policy assignment identity the configured remediation role at the enterprise management-group scope. The run identity therefore needs permission to create both policy and role assignments at that scope.
- VM guest logs are intentionally excluded until an Azure Monitor Agent Data Collection Rule is approved and configured in `platform-management`.
- Policy remediation still depends on target subscriptions having the required resource providers registered (`Microsoft.Network`, `Microsoft.Security`, and service-specific providers). Subscription onboarding or each resource-owning workspace should register providers before remediation is expected to converge.
- Private connectivity starts in Audit.
- Sandbox and decommissioned management-group assignments must be configured before subscriptions are onboarded to those groups.

## Inputs From Other Workspaces

By default, HCP outputs are read from:

| Workspace | Output |
|---|---|
| `platform-governance` | `management_group_ids` |
| `platform-management` | `log_analytics_workspace_id` or `primary_log_analytics_workspace_id`; `log_analytics_workspace_guid`; `log_analytics_workspace_location`; `platform_storage_account_ids.audit` for VNet flow logs |

Set `use_tfe_outputs = false` and provide `management_group_ids` directly only for isolated testing.

## Validation

```bash
terraform fmt -check
terraform init -backend=false
terraform validate
```

Run the pattern tests from `patterns/terraform-azurerm-compeer-platform-policy` before a live plan.
