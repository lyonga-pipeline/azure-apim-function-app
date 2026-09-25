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
| GOV-07 resource diagnostics DINE | `platform-policy` | Assigns the Microsoft built-in `allLogs` initiative to the enterprise management group with an approved resource-type list and the central workspace ID. |
| OBS-03 Activity Log collection | `platform-management` | Direct diagnostic setting to the central Log Analytics workspace. An Activity Log DINE assignment can be added as a governance backstop. |
| Managed identity where supported | `platform-policy` | App Service, Function App, and Automation audit assignments. Add service-specific built-ins as the approved service catalog grows. |
| Key Vault authorization and recovery | `platform-policy` | RBAC authorization and deletion-protection audit assignments. |
| SEC-09 encryption at rest | Both policy workspaces | Secure storage is in governance; Windows/Linux VM disk encryption audits are in platform-policy. Service-native encryption remains configured by resource patterns. |
| SEC-10 encryption in transit | Both policy workspaces | Storage TLS is in governance; App Service and Function TLS audits are in platform-policy. |
| Private endpoints where applicable | Resource patterns and `platform-policy` | Resources create endpoints explicitly; policy audits public IPs. Platform Key Vault/storage exceptions must follow the approved placement decision and must not be blocked by a blanket PaaS deny. |
| Privileged access audit and group-only assignments | `platform-authorization` and PIM | Not an Azure Policy responsibility. OPA can reject direct user assignments in Terraform plans. |
| Custom roles and management-group RBAC | `platform-authorization` | Kept out of policy state. |
| Defender plans | `platform-management` | Subscription management configuration because plans have cost and tier decisions. |
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
    "rg-conn-palo-alto",
    "rg-conn-bastion",
    "rg-conn-route-server",
    "rg-hybrid-gateway",
  ]
}
```

## Remediation

DINE and Modify assignments require a location and managed identity. The deployable root reads the Log Analytics workspace ID from `platform-management` and can inject it into policies that use a `logAnalytics` parameter.

`remediation.dine_assignments` accepts exactly one of `policy_definition_id` or `policy_set_definition_id`. Every assignment receives a system-assigned identity. `role_definition_ids` creates the management-group role assignments that identity needs to remediate resources.

The implementation uses Microsoft's built-in initiative `0884adba-2312-4468-abeb-5422caed1038`. Its child policies are resource-type specific, deploy the `allLogs` category group, enable `AllMetrics` where supported, and recognize an existing setting that already targets the configured Log Analytics workspace. Approved Terraform patterns therefore remain the primary owner of diagnostics; Policy creates `setByPolicy-LogAnalytics` only when the compliant setting is absent.

The initiative's `resourceTypeList` is the Phase 1 catalog, not every type Azure supports. Extend that list when a new service is approved. Services not supported by the built-in initiative, including resource types whose logs live on child resources, remain explicit Terraform diagnostics until a reviewed policy is added.

Before enabling a remediation policy:

1. Verify the built-in definition and parameters in the target tenant.
2. Confirm the target resource types and regions.
3. Grant the assignment identity only the roles required by that policy.
4. Deploy in audit/non-enforcing mode where supported.
5. Create remediation tasks only after the assignment and permissions are validated.

Policy-created diagnostic settings are expected platform-managed resources. Drift-health checks must not classify `setByPolicy-LogAnalytics` as an unauthorized resource. Terraform diagnostic modules manage only their named setting and must not treat all settings on a target as an authoritative collection.

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
