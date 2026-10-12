# Compeer Platform Policy Pattern

## Purpose

This pattern manages Azure Policy after the management-group hierarchy exists. It creates custom definitions, initiatives, assignments at management-group, subscription, or resource-group scope, time-bound exemptions, and opt-in DeployIfNotExists or Modify remediation assignments.

It uses the reusable [`terraform-azurerm-compeer-policy`](../../modules/terraform-azurerm-compeer-policy) module for Azure resources. This pattern adds landing-zone composition: management-group key resolution, naming, private-connectivity controls, and remediation identity configuration.

## Workspace Boundary

| Workspace | Ownership |
|---|---|
| `platform-governance` | Management-group hierarchy and the initial enterprise baseline: locations, mandatory tags, public exposure, storage security, SQL network posture, and MCSB. |
| `platform-policy` | Additional built-in/custom controls, policy exemptions, private-connectivity controls, and DINE/Modify assignments. |
| `platform-authorization` | Entra groups, custom role definitions, PIM integration, and Azure RBAC assignments. |
| `platform-management` | Log Analytics, Activity Log and Entra diagnostics, Sentinel, Defender plans, and resource diagnostic settings owned by the platform resources. |

Do not define the same assignment in two workspaces. Move ownership only through a deliberate state migration or import.

## Inputs

| Input | Purpose |
|---|---|
| `management_group_ids` | Management-group IDs keyed by the governance catalog key. |
| `custom_policy_definitions` | Custom definitions created at management-group scope. |
| `custom_policy_set_definitions` | Custom initiatives and their policy references. |
| `management_group_policy_assignments` | Enterprise or child management-group assignments. |
| `subscription_policy_assignments` | Subscription-specific controls that should not be inherited from a management group. |
| `resource_group_policy_assignments` | Narrow resource-group controls. |
| `policy_exemptions` | Waiver or mitigated exemptions at management-group, subscription, or resource-group scope. |
| `private_only_connectivity` | Optional custom public-IP initiative and assignment. |
| `remediation` | Optional DINE/Modify assignments with a system-assigned identity. |

`management_group_key` is resolved to a full Azure ID before the generic policy module is called. Definition, initiative, and assignment keys remain stable composition references inside the base module.

## Required Control Coverage

The following mapping covers the Identity and RBAC design recommendations and the Phase 1 component list without mixing policy and authorization ownership.

| Requirement | Owner | Current implementation |
|---|---|---|
| GOV-05 approved locations, public exposure, secure storage, SQL posture | `platform-governance` | Enterprise baseline initiative at `compeer-enterprise-mg`. |
| GOV-05 approved resource types | `platform-policy` | Built-in assignment, audit/non-enforcing until the approved catalog is complete. |
| GOV-06 mandatory tags | `platform-governance` | Enterprise tagging policy inherited by descendants. Tag value validation also exists in OPA and the tagging module. |
| GOV-07 resource diagnostics DINE | `platform-policy` | Assigns the Microsoft built-in `allLogs` initiative to the enterprise management group with an approved resource-type list and the central workspace ID. App Service and Function App use dedicated built-ins. |
| NET/OBS VNet flow logs | `platform-policy` + `platform-management` | Assigns Network Watcher and VNet flow-log DINE policies at the enterprise management group. The deployable root reads the platform Log Analytics workspace GUID/resource ID and audit storage account ID from `platform-management`. |
| OBS-03 Activity Log collection | `platform-management` | Direct diagnostic setting to the central Log Analytics workspace. An Activity Log DINE assignment can be added as a governance backstop. |
| Managed identity where supported | `platform-policy` | App Service, Function App, and Automation audit assignments. Add service-specific built-ins as the approved service catalog grows. |
| Key Vault authorization and recovery | `platform-policy` | RBAC authorization and deletion-protection audit assignments. |
| SEC-09 encryption at rest | Both policy workspaces | Secure storage is in governance; Windows/Linux VM disk encryption audits are in platform-policy. Service-native encryption remains configured by resource patterns. |
| SEC-10 encryption in transit | Both policy workspaces | Storage TLS is in governance; App Service and Function TLS audits are in platform-policy. |
| Private endpoints where applicable | Resource patterns and `platform-policy` | Resources create endpoints explicitly; policy audits public IPs. Platform Key Vault/storage exceptions must follow the approved placement decision and must not be blocked by a blanket PaaS deny. |
| Privileged access audit and group-only assignments | `platform-authorization` and PIM | Not an Azure Policy responsibility. OPA can reject direct user assignments in Terraform plans. |
| Custom roles and management-group RBAC | `platform-authorization` | Kept out of policy state. |
| Defender plans | `platform-management` + `platform-policy` | `platform-management` configures the platform-management subscription directly; `platform-policy` assigns the approved MG-level DINE baseline so newly onboarded descendant subscriptions inherit Servers P1, Storage, Key Vault, App Service, Azure SQL, SQL on machines, Containers, and Resource Manager. The deployable root adds the platform-management subscription to the Defender DINE `not_scopes` list from the management output contract, so Policy does not fight Terraform-owned subscription pricing. Servers P2 and Defender CSPM remain explicit licensing/SOC decisions. |
| CIS/NIST/FFIEC/PCI initiatives | `platform-policy` | CIS is available as reporting-only. Additional frameworks are deferred until scope, licensing, and applicability are approved. |
| GOV-14 sandbox guardrail | `platform-policy` | Add the approved sandbox assignment before subscriptions are onboarded. |
| GOV-16 deny new deployments | `platform-policy` | Add the approved decommissioned-MG assignment and test exemptions before subscriptions are moved. |

Naming is enforced by the reusable naming module and OPA. Azure Policy naming rules should only be added when resource-specific patterns and exceptions are approved; one generic expression cannot correctly validate every Azure resource type.

## Assignment Model

Azure uses different Terraform resource types for management-group, subscription, and resource-group assignments and exemptions. The base module preserves that distinction so plans show the actual deployment scope.

Prefer enterprise assignments at `compeer-enterprise-mg` so descendants inherit them. Use lower scopes only when the control is intentionally narrower or requires different parameters. Start new controls in Audit or non-enforcing mode, review compliance, approve exemptions, and then promote selected controls to Deny.

## Private Connectivity

The optional initiative creates two custom policies:

| Policy | Purpose |
|---|---|
| `deny-public-ip-address` | Audits or denies Public IP resources outside approved edge resource groups. |
| `deny-nic-public-ip` | Audits or denies NICs attached to Public IPs. |

Built-in PaaS public-network policies are opt-in because their IDs and applicability must be tenant verified. Do not enable a blanket PaaS deny when the approved platform design requires public network access for platform Key Vault or storage. Workload Key Vault and storage remain private by default unless an approved exception exists.

```hcl
private_only_connectivity = {
  enabled              = true
  management_group_key = "compeer-enterprise-mg"
  effect               = "Audit"
  enforce              = true
  allowed_public_ip_resource_group_names = [
    "platform-cus-prod-firewall-rg",
    "platform-cus-prod-security-rg",
    "platform-cus-prod-hybrid-rg",
  ]
}
```

## Remediation

DINE and Modify assignments require a location and managed identity. The deployable root reads public outputs from `platform-management` and can inject its workspace ID into policies that use a `logAnalytics` parameter. Contract checks require the actual destination and explicit ownership boundaries; a default diagnostic profile is not proof that every resource uses those defaults.

`remediation.dine_assignments` accepts exactly one policy/initiative ID or local definition key. Every assignment receives a system-assigned identity. Each entry can override `management_group_key` and `location`; its `role_definition_ids` are granted at that same management-group scope, not an unrelated bundle scope. The existing built-ins require their documented roles, including Owner for some Defender plans. Those broad inherited privileges require security review.

The implementation uses Microsoft's built-in initiative `0884adba-2312-4468-abeb-5422caed1038`. Its children deploy the `allLogs` category group, not metrics. Their existence conditions also inspect categories/groups, not just destination or setting name. An explicit Key Vault `AuditEvent` setting is therefore not interchangeable with the built-in group test. The root excludes Terraform-owned platform scopes from diagnostic DINE and assigns read-only audits there. Category-based Key Vault, Bastion, and blob-service audits match the approved profiles; other selected types use the built-ins with `AuditIfNotExists`. Metrics remain explicitly owned by the resource workspace.

The initiative's `resourceTypeList` contains the Phase 1 catalog plus a controlled pilot buffer of common workload services. Extend it only after service approval. App Service and Function Apps use dedicated Microsoft definitions. Storage roots are metrics-only; platform-management configures blob logs on `blobServices/default`. Other service children need explicit settings/profiles when used. Workspace-based Application Insights is excluded to avoid exporting into its own underlying workspace. See [Microsoft's diagnostic settings guidance](https://learn.microsoft.com/en-us/azure/azure-monitor/data-collection/diagnostic-settings).

Virtual machines are not diagnostic-setting equivalents of PaaS resources. Guest telemetry requires Azure Monitor Agent and an approved Data Collection Rule. Do not add `Microsoft.Compute/virtualMachines` to this initiative: deploy the AMA/DCR policy only after `platform-management` publishes the approved DCR and its data sources.

VNet flow-log child resources are separately Policy-owned, even when Terraform owns the VNet parent. The root composes Microsoft's Network Watcher policy with a versioned custom flow-log definition adapted from built-in `3e9965dc` v1.1.1. Unlike that built-in, it requires enabled logging/Traffic Analytics, exact storage/workspace destinations, interval, retention, and JSON v2. Its deployment reuses an existing log's name. Exclude scopes with Terraform-owned flow logs using `network_flow_logging_policy.not_scopes` before applying it. The deprecated workspace GUID parameter is not required. The storage account must be in the VNet region, accessible to Network Watcher, and in the same Entra tenant. The checked-in configuration uses management's audit account; validate that service access in Azure before a rollout.

Microsoft Defender inheritance uses individual assignments and explicit per-plan `enabled` flags. Omitted plans stay disabled; unknown keys are rejected. The existing checked-in eight-plan selection is preserved, not newly approved by these changes. Security must approve licensing, subplans and scanning costs. Management's direct subscription baseline can intentionally differ; review its published `defender_plan_configuration` against fleet choices rather than imposing a paid feature silently.

The deployable root defaults `defender_for_cloud_policy.exclude_platform_management_subscription = true`. This keeps direct Defender plan ownership in `platform-management` for the platform-management subscription while using `platform-policy` only as the inheritance backstop for downstream landing-zone subscriptions. Add extra `not_scopes` only for approved exceptions; do not remove the platform-management exclusion without importing or migrating ownership of the direct Defender resources.

Before enabling a remediation policy:

1. Verify the built-in definition and parameters in the target tenant.
2. Confirm the target resource types and regions.
3. Grant the assignment identity only the roles required by that policy.
4. Deploy in audit/non-enforcing mode where supported.
5. Create remediation tasks only after the assignment and permissions are validated.

`remediation.tasks` defaults to `{}`. Each opted-in task references an enabled assignment by key, has bounded resource count/concurrency/failure threshold, and depends on remediation RBAC. Initiative tasks require a verified `policy_definition_reference_id`; use one task per selected child. Apply assignments/RBAC first, allow permissions to propagate, trigger a compliance scan, then approve a separate task change. AzureRM 4.x management-group remediation uses existing compliance results, not a `resource_discovery_mode` argument. A completed task is not a recurring controller: a fresh approved task name is needed for another run. Disabled or audit-only assignments cannot receive these tasks. See [Microsoft's remediation workflow](https://learn.microsoft.com/en-us/azure/governance/policy/how-to/remediate-resources).

Policy-created settings are expected only in Policy-owned scopes. Naming prevents name collisions, not duplicate ingestion; explicit scope boundaries prevent concurrent writers. When a workspace adopts diagnostics, exclude that scope first and import the existing setting into its designated Terraform address, or remove the duplicate only after verifying ingestion through the intended setting. Never use blanket `ignore_changes` to hide conflicting ownership. See the deployable root README for the ownership and rollout checklist.

## Exemptions

Each exemption sets `scope_type`, the corresponding scope ID or management-group key, and either `policy_assignment_id` or a key for an assignment created by this pattern. Use `Waiver` for accepted temporary non-compliance and `Mitigated` when another control addresses the risk. Set `expires_on` and a tracked reason for every time-bound exception.

## Naming

Custom policy definition names are explicit because the approved naming standard does not define a universal policy-definition pattern. Initiative naming can use `domain` and `purpose`; assignment naming can use `policy` and `policy_scope`. Explicit names always take precedence.

## Validation

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
```

Tests cover naming precedence, scope resolution, exemptions, remediation contracts, built-in guardrails, and private-connectivity behavior.
