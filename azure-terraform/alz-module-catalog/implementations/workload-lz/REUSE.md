# Shared Services And Application Ownership

The spoke references approved platform services instead of deploying a copy.
Reuse is a reference, not an import or an ownership transfer. Both workspace
templates remain disabled; optional telemetry/alerts/data services stay held
until their existing approval gates are met. No locks are added.

Current capability switches, external diagnostics/alert reuse and lifecycle cautions
are in [CAPABILITIES.md](CAPABILITIES.md). Runnable complete variants live in the
blueprint's examples folder. The dedicated vault remains the default; the approved
secretless variant may opt out without substituting the platform vault.

## Resource Decisions

| Resource | Decision |
| --- | --- |
| Central LAW | Existing management output, used for workload diagnostics and approved telemetry. No spoke LAW. |
| Action groups | Reuse management's published primary group, selected approved keys, or explicit existing IDs. Create only for a genuinely different approved application audience. |
| Application Insights | Off by default. Explicitly reference an existing approved application/environment component, or explicitly create one when required. A central LAW does not imply a central Application Insights component exists. |
| Hub, hybrid DNS, private DNS zones, optional DDoS plan | Existing connectivity contracts. A separate platform attachment state owns both peerings and required VNet/zone links; the blueprint has no hub provider or attachment blocks. See ATTACHMENT.md. |
| Sentinel, Defender, flow logs | Existing management/policy owners. No copies in the spoke. |
| Recovery Services vault and backup policy | Existing same-workload-subscription IDs; the optional spoke capability only enrolls specified existing VMs. No new vault/policy. |
| Subscription budget | Removed from this Phase 1 package; Phase 2 belongs with the governance owner. |
| Workload Key Vault and UAMI | UAMI remains dedicated. Vault is dedicated by default; the approved key_vault.enabled=false variation is only for workloads needing no vault. Do not put application secrets in the platform vault or reuse a broad platform identity. |
| Blob data accounts | Empty by default; create only for an actual application requirement. Platform audit/artifact/flow-log accounts are not general application data stores. Existing application stores remain with their owner and are consumed by application code, not recreated here. |
| NSGs, UDRs, private endpoints, diagnostic settings and workload alerts | Resource-specific configuration, not interchangeable shared services. The selected resource owner manages it; policy recognizes the compliant configuration. |

## Action Group Wiring

`platform-management` already publishes `action_group_ids` (including `primary`)
and `action_group_enabled`. The shared adapter reads these **non-sensitive public
outputs**, passes the IDs into `platform.action_group_ids`, and resolves
`operations.platform_action_group_keys`. No producer output or contract version
change is necessary.

The workspace adapter selects `primary` only when it is published and not
disabled; it is used as a notification route when approved alerts are enabled.
It never subscribes every published audience. An explicit ID list or local
creation request suppresses that automatic selection. Explicit keys and IDs
can intentionally be combined; identical IDs are deduplicated.

Inside `spoke` in either workspace's `terraform.tfvars`, after approving alerts:

```hcl
operations = {
  platform_action_group_keys = ["primary"]
}
```

Or select an independently owned approved group:

```hcl
operations = {
  action_group_ids = ["REPLACE_APPROVED_ACTION_GROUP_ARM_ID"]
}
```

Only if a separate application audience is required:

```hcl
operations = {
  create_action_group = true
  notification_emails = ["REPLACE_APPROVED_APPLICATION_ONCALL_EMAIL"]
}
```

Emails alone are rejected rather than implicitly authorizing a new group.
A new group is not created without an enabled alert consumer.
An unavailable selected key fails the plan instead of falling back to creation.
The standalone blueprint has no automatic HCP discovery: callers supply
`platform.action_group_ids` and select keys, or provide explicit IDs.

The spoke does not modify shared recipients, receivers, tags or group settings.
The run identity needs approved read/reference permissions on shared resources
in addition to write permissions on workload alerts. Confirm enabled status,
recipient approval and actual test delivery before go-live; an ARM ID is not
proof of delivery. No blanket cross-subscription role grants are added.

## Application Insights Wiring

Reuse only a component already approved for **this application and environment**.
Do not point unrelated applications or production/non-production at one shared
component merely because they share a LAW. The failed-request alert covers its
entire component; application isolation and its SLO must match that scope.

Choose one of these mutually exclusive configurations inside `spoke`:

```hcl
monitoring = {
  enabled        = true
  alerts_enabled = true
  existing_application_insights = {
    id           = "REPLACE_APPROVED_APPLICATION_COMPONENT_ARM_ID"
    workspace_id = "REPLACE_APPROVED_CENTRAL_LAW_ARM_ID"
  }
}
operations = { platform_action_group_keys = ["primary"] }
```

This does not create an Application Insights resource, change sampling,
retention/authentication/network settings, or claim its lifecycle. The declared
workspace must match the approved LAW. Its existing owner must verify the live
linkage, Entra-only authentication, identity access and working ingestion. The
opt-in integration verifier checks actual LAW/authentication without imposing
the spoke profile's sampling on externally owned components.

By default that owner also grants the workload UAMI its component-scoped
Monitoring Metrics Publisher role. Only with explicit delegation and no
pre-existing grant set `manage_existing_telemetry_access = true` in `monitoring`
to manage that single assignment here. Do not manage the same grant in two states.

When this application needs a new component instead:

```hcl
monitoring = {
  enabled                     = true
  create_application_insights = true
  alerts_enabled              = true
}
operations = { platform_action_group_keys = ["primary"] }
```

The workload state then owns the new component and its scoped publishing role;
the LAW and action group remain shared. Alerts can remain disabled independently.
With telemetry off, no component/publishing role is created. Reuse without
workload alerts creates no empty operations RG.

## Existing Deployments

These switches require an explicit decision, not automatic discovery or fallback.
Existing callers that intend to retain an owned component must now set
`create_application_insights = true` alongside `enabled = true`; existing local
contacts require `create_action_group = true` with their recipients. Keep the
existing module addresses and review the plan before apply.

Changing an owned resource to a shared reference removes it from this state's
configuration and can plan its destruction. Do not apply that plan to achieve
reuse. First agree ownership and perform a separately reviewed state handoff
that preserves the Azure resource. Do not import platform services into a spoke
merely to reference them. No automatic state migration is performed here.

## Guidance And Acceptance

Microsoft documents [reusing an action group across alert rules](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups#reusability-and-execution)
and [multiple Application Insights components using a LAW, with separate
production/non-production resources](https://learn.microsoft.com/en-us/azure/azure-monitor/app/create-workspace-resource?tabs=bicep).
This implementation applies those capabilities with explicit ownership and
application/environment boundaries, rather than treating every service as shared.

Local tests cover reference-only reuse, explicit creation, missing keys,
conflicting choices, wrong workspaces, empty-resource omission and both root
adapters. They do not prove Azure cross-subscription permissions, recipient
delivery, SDK ingestion, policy convergence or backup recovery. Record those
checks in [ACCEPTANCE.md](ACCEPTANCE.md); source/phase decisions remain in
[DESIGN-ALIGNMENT.md](DESIGN-ALIGNMENT.md).
