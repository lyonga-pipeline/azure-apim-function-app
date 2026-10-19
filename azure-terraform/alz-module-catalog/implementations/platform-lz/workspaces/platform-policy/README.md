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
| `existing_resource_remediation` | Terraform, HCL enabled | Optional approved subscription/plan backfill selection; defaults to empty targets. See remediation-example.tf. Does not replace the policy object. |
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
- GOV-07 diagnostics remediation is enabled after `platform-management` publishes the central Log Analytics workspace ID. Microsoft's built-in `allLogs` initiative covers the remaining selected catalog, with dedicated built-ins for App Service and Function Apps. Key Vault, Bastion and blob services use the explicit category profiles below for both audit and gap-filling DINE; those types are removed from the initiative's effective resource list to prevent overlapping deployments.
- The existing `platform-mg` boundary is retained until directly managed targets are inventoried. Exact `terraform_resource_ids` can protect only known diagnostic targets and automatically add read-only category/allLogs audits for supported catalog types. This permits mixed IaC/manual scopes without excluding every Terraform-created resource. Outside explicit boundaries, a compliant setting satisfies the policy regardless of its name or deployment tool. Application Insights and storage roots remain excluded; metrics remain the resource owner's responsibility.
- Built-in diagnostic audit assignments retain `AuditIfNotExists` and receive a SystemAssigned identity and location because Azure validates their embedded deployment metadata even in audit mode. These audit identities receive no remediation roles or tasks. Custom audit-only definitions have no deployment metadata and remain identity-free.
- Central US VNet flow-log child resources are Policy-owned separately from diagnostic settings. A strict custom definition requires the approved storage/workspace, enabled state, retention, interval and format. Exclude any Terraform-owned flow-log scopes separately. No deprecated workspace GUID is required.
- The checked-in Defender selection enables Servers P1, Storage with malware scanning and sensitive-data discovery, Key Vault, App Service, Azure SQL databases, SQL servers on machines, Containers, and Resource Manager at `compeer-enterprise-mg`. This preserves the prior selection; it is not evidence of client licensing approval or deployment. Servers P2 and Defender CSPM remain separate security/licensing decisions.
- Defender Storage's `capGBPerMonthPerStorageAccount` is an Integer, while its two feature switches are Strings (`"true"` / `"false"`) in built-in definition `cfdc5972-75b3-4418-8ae1-7f5c36839390` v1.5.0. Assignment selection preserves those JSON types; do not wrap the heterogeneous assignment object in a conditional that coerces all parameter values to strings.
- The workspace grants each assignment identity its configured roles at that assignment's management-group scope. Diagnostic, Defender, and flow-log target scopes are independent. The run identity needs policy and role-assignment permissions at those scopes.
- Existing-resource remediation remains opt-in: the manual tasks map and existing_resource_remediation targets default empty. An approved selection starts bounded jobs on apply; new-resource DINE remains independent of this backfill.
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
| Connectivity, identity/security, workload diagnostics | Resource-owning workspace | Register explicitly owned diagnostic targets for guaranteed audit-only protection; compatible unregistered settings can coexist with DINE but noncompliance can trigger deployment |
| Management-subscription Defender pricing | platform-management | Security approves direct plan configuration; fleet DINE excludes this subscription |
| Other targeted subscriptions' Defender pricing | platform-policy DINE | Security approves explicitly enabled plans and costs |
| Policy definitions, assignments, identities, RBAC, exemptions, tasks | platform-policy | Reviewed scope and remediation approval; governance retains its separate initial baseline |
| VNet flow-log children and Traffic Analytics | platform-policy DINE | Network/Security approve destinations, access and region; exclude any directly managed flow logs |
| Sentinel detections, connectors, hunting, ServiceNow integration | Security Operations | Existing Terraform baseline content remains in its current state until an explicit handover |

These are lifecycle boundaries, not automatically enforced human approval/RBAC separation. Use protected PRs, restricted workspace apply rights, and distinct run identities. Security Operations can approve Terraform-managed Sentinel content through PRs; do not also edit the same managed rules in the portal. An independent SOC workspace or external tool must first adopt/import those resources. Do not toggle off existing rules/connectors as a handover, because that can destroy them.

`configuration_ownership` publishes the effective policy exclusions and enabled plans. Management publishes `diagnostic_configuration` (actual storage targets/categories, not assumed defaults) and `defender_plan_configuration`. These outputs describe desired configuration, not live compliance evidence.

The audits cover selected catalog types, App Service/Functions, and explicit Key Vault/Bastion/blob profiles. They do not cover VM guest logs, every future storage service, or subscription Activity Log export across the enterprise. Add service-specific profiles and AMA/DCR or Activity Log controls when approved. For broad `additional_terraform_scopes` outside platform-mg, configure an equivalent audit assignment/CI check explicitly; that legacy exclusion alone does not create one. Exact registered target IDs receive audits for configured category profiles and enabled allLogs catalog types. Metrics and unsupported services remain direct workspace responsibilities.

## Terraform And DINE Coexistence

The lifecycle owner is the diagnostic setting, Defender pricing resource or flow-log child, not necessarily the resource that produces logs. A Terraform-created Key Vault without directly managed diagnostics can still use Policy-owned diagnostics. DINE does not read Terraform state and cannot infer that ownership.

The checked-in diagnostic baseline is:

| Resource | Required enabled categories at the central LAW |
|---|---|
| Key Vault | `AuditEvent` |
| Bastion | `BastionAuditLogs` |
| Storage blob service | `StorageRead`, `StorageWrite`, `StorageDelete` |
| Other enabled fleet catalog types and App Service/Functions | Enabled `allLogs` category group, matching the Microsoft built-ins |

Category-profile audit and DINE definitions reuse the same existence condition. Each required category must be enabled in the same setting and target the approved workspace. An enabled `allLogs` group can satisfy these category profiles; another setting name does not cause deployment. DINE creates only those log categories, not metrics. Its 30-minute evaluation delay gives Terraform a deployment window, but is not a guarantee against a slow or concurrent deployment.

Microsoft's built-in allLogs policies recognize the category group, not an arbitrary hand-picked category list. Do not assume an individually configured list satisfies those policies. Change the owning Terraform configuration to the approved group or introduce a reviewed, resource-specific category profile and remove overlapping built-in coverage first. Do not add a `Microsoft.Web/sites` category profile alongside the App Service/Function policies without also defining disjoint kind filters and retiring their overlapping assignments.

| Situation | Expected result |
|---|---|
| Any compliant setting in a DINE scope | No policy deployment, irrespective of its creator/name |
| Missing or noncompliant setting in a DINE scope | Deployment can occur following eligible create/update events; an approved task handles existing noncompliant resources |
| Explicitly registered Terraform-owned target | DINE excluded; read-only audits flag missing/noncompliant logs for correction in Terraform |
| Approved intentional difference | Reviewed, time-bound exemption or a separately scoped baseline; not an unrecorded portal change |

To narrow the current platform boundary, inventory **all** directly managed targets first, register their full parent/service IDs, confirm their audit coverage, then remove the MG exclusion. Do not replace the production configuration with an empty registry merely because current settings appear compliant. Merge the following fields into the existing `policy.diagnostic_ownership` object only after approval:

```hcl
profile_dine_enabled            = true
profile_dine_effect             = "AuditIfNotExists" # Pilot first, then DeployIfNotExists.
terraform_management_group_keys = []
terraform_resource_ids = [
  "/subscriptions/<actual-subscription-uuid>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<vault>",
  "/subscriptions/<actual-subscription-uuid>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<account>/blobServices/default",
]
shared_scope_enabled = true
```

Use target IDs, not diagnostic-setting IDs. Register ownership before creating/adopting a direct setting. A strict exclusion deliberately means Policy cannot repair a deleted setting there: the owner must repair it through Terraform. Conversely, unregistered Terraform settings in a shared scope have **no guaranteed audit-only protection** when noncompliant. If Policy fills a gap and the team later wants direct ownership, exclude the target, import the existing setting into one state and verify a no-op plan before deployment; do not create a second setting.

The platform boundary remains conservative in committed tfvars because this repository does not contain a verified inventory of the client's applied targets. Defender and flow-log ownership/exclusions remain independent and unchanged. Human approvals and least-privilege RBAC review remain deployment responsibilities, not something these flags enforce.

This strategy follows [Microsoft's DINE evaluation/existence-condition guidance](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/effect-deploy-if-not-exists), [diagnostic policies at scale](https://learn.microsoft.com/en-us/azure/azure-monitor/data-collection/diagnostic-settings-policy), and [ALZ governance recommendations](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/governance). These sources support policy guardrails and scoped assignments; they do not prescribe one universal Terraform ownership model or prove how every large company operates.

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

### Existing Subscription Backfill

[remediation-example.tf](remediation-example.tf) is executable workspace code,
with commented, placeholder-only HCP/tfvars examples and a separate variable.
It addresses the actual missing step from the portal review: assigning DINE
does not deploy the missing plans/flow logs on already-existing subscriptions.
Do not replace the entire policy object or duplicate its existing assignments.

1. Verify the applied HCP commit/overrides and actual Defender plan state. Review
   the eight currently selected plans and costs with Security; this helper adds
   no new plans, subplans or contacts and does not remediate CIS, tags or locks.
2. Verify target subscription ancestry, exclusions, provider registration and
   assignment-identity RBAC. The management subscription stays Defender-excluded.
   The HCP run identity also needs permission to create PolicyInsights remediation
   resources at each selected subscription. No automatic registration or extra
   role grant is added by this helper.
3. Set existing_resource_remediation with an approved stable batch_name, actual
   subscription UUIDs and explicit defender_targets.plan_keys. Start with a
   small pilot. Each selected plan gets one subscription-scoped job, no region
   filter, a resource cap of one, serial deployment and zero failure tolerance.
4. Optionally select flow_log_targets separately, with an approved resource cap.
   Those jobs use the existing policy's Central US region filter. Network Watcher
   already reported compliant, so no second Watcher deployment is added. Confirm
   actual watcher/storage/LAW accessibility and the applicable noncompliant VNets;
   a cap of one does not name a particular VNet. Diagnostics backfill remains
   separate because directly owned targets must stay protected from policy writes.
5. Review the plan: expect remediation resources and a batch contract only,
   without new pricing resources, policy assignments or changes to exclusions.
   Subscription jobs request ReEvaluateCompliance before acting on unmet policy
   conditions. After apply inspect job/deployment results, actual pricing and
   flow-log resources, raw storage log arrival and LAW Traffic Analytics. A
   task ID, passing mock test or green assignment is not end-to-end evidence.

The helper merges with manually configured policy.remediation.tasks and rejects
name collisions. The generic pattern still accepts lower-scope initiative jobs
when a verified child reference is supplied; none are generated here. Backfill
inherits all existing assignment exclusions and cannot make all CIS/MCSB controls
green. Correct non-DINE settings in their owning Terraform workspace, or approve
an intentional exception rather than hiding a finding.

Keep names stable during a batch; a new batch name deliberately starts new jobs.
Record completion evidence, then retire completed target selections through a
reviewed plan so a service-expired task is not unintentionally recreated later.
Removing a task record does not undo prior changes made by its deployment.
No Azure scan, remediation or pricing operation runs merely from adding this file.

For a Policy-to-Terraform handover: exclude the target scope first, freeze concurrent changes, match the intended configuration to the existing setting, import it into exactly one owning state, and confirm a no-op plan. For Terraform-to-SOC handover, use a reviewed `removed` block with `destroy = false` and adopt the resource in the new owner; do not merely remove its resource block. Never mask competing writers with `ignore_changes`.

### Coexistence Pilot Acceptance

Mock tests validate generated policies, baselines, ownership boundaries and rejected inputs. They do not execute Azure's policy engine or prove ingestion. Before broad application, run this matrix in a dedicated pilot scope and retain before/after evidence:

1. Create a compliant Terraform-owned Key Vault setting with a non-policy name. After evaluation/remediation, confirm the setting count/configuration is unchanged and the owning Terraform plan is a no-op.
2. Register a directly owned target, then remove/disable a required log category in the pilot. Verify audit reports noncompliance, DINE does not write there, and Terraform proposes the correction. Do not use unmanaged production edits for this test.
3. Create an unregistered resource without diagnostics. Verify gap filling sends enabled categories to the central LAW and creates one Policy-owned setting after evaluation. For an existing resource, use a bounded, approved remediation task after compliance evaluation.
4. Test a wrong LAW, disabled category and partial categories. These must fail the approved existence condition; remediation is permitted only outside protected targets. Inventory pre-existing noncompliant settings because deploying a new policy-named setting does not remove older settings or guarantee there is only one ingestion path.
5. Confirm intended exceptions remain excluded and flow-log/Defender boundaries are unchanged. Verify permissions, actual log arrival and licensing/cost approval separately.

Inspect a pilot target with `az monitor diagnostic-settings list --resource <target-resource-id>` and compare the owning workspace's plan before/after. Freeze concurrent deployments during controlled remediation. A passing Terraform mock test is not a substitute for this Azure pilot.

## Validation

```bash
terraform fmt -check
terraform init -backend=false
terraform validate
terraform test
```

Run the pattern tests from `patterns/terraform-azurerm-compeer-platform-policy` before a live plan.
