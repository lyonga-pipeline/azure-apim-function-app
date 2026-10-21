# Spoke Landing Zone Blueprint

Reusable Azure application landing-zone foundation for WKL-01, consumed by the
production NET-23 and non-production NET-24 deployments. Deploy one instance
per application/environment in an existing workload subscription. Compute,
application data and service-specific architecture remain with the application.

[Requirements](#requirements) | [Creation/reuse](#creation-and-reuse) | [Inputs](#inputs) | [Examples](#configuration-examples) | [Outputs](#outputs) | [Deployment](#deployment-and-lifecycle)

This repository edition composes [local catalog modules](../../modules) and the
[workload Key Vault pattern](../terraform-azurerm-compeer-workload-key-vault).
The separately maintained Compeer edition uses HCP dependency pins and stays
outside this repository; do not replace one edition's sources with the other.

## Requirements

| Requirement | Contract |
| --- | --- |
| Terraform | Stable `>= 1.11.4, < 2.0.0`; Terraform 1.7 is unsupported. |
| AzureRM | `>= 4.81.0, < 5.0.0`; select and commit approved provider locks in the caller. |
| Providers | `azurerm` for the workload; `azurerm.dns` for the actual private-zone subscription, in the same tenant. No spoke-side hub provider. |
| Platform prerequisites | Existing subscription/MG placement, hub/NVA, central LAW, hybrid DNS and required private zones; management/connectivity public contracts `0.1.0`. |
| Deployment identity | Approved workload resource-write and separately scoped role-assignment permissions, plus existing-zone read/join permissions. No hub peering write access is needed by this state. |
| Operations | Approved IPAM inventory, tags, application rules and separate backend/state/run identities for production and non-production. Register required resource providers before deployment. |

Configure Azure/HCP credentials outside source and tfvars. The supplied roots use
`storage_use_azuread=true` and `features.storage.data_plane_available=false`:
private storage control-plane provisioning must not temporarily enable public
access or shared keys. Private data operations require an authorized connected runner.

## Creation And Reuse

The foundation is **created and managed**, not adopted by supplying existing IDs.
Only the reuse interfaces below reference resources owned by another state.

| Component | Creation/default | Reuse or disable |
| --- | --- | --- |
| Workload RGs, VNet/subnets, subnet NSGs/UDRs and associations | Always created. RG keys: `network`, `security`, `application`; `operations` only for locally created operations, `data` only for enabled storage. | No existing-network/RG adoption flag. Use a reviewed state migration for existing deployments. |
| Workload user-assigned identity | Always created; attach/select it in the application runtime. | No existing-identity input. It does not receive subscription-wide privileges. |
| Workload Key Vault | Dedicated private vault by default, with its PE and DNS zone group. | `key_vault.enabled=false` for an approved secretless workload. No shared/existing-vault substitution. |
| Blob storage | None by default; every enabled `storage_accounts` entry creates a private account and Blob PE/zone group. | Omit an entry or set its `enabled=false`. No existing-account ID input. |
| Central LAW and private DNS zones | Never created here. | Supply approved IDs in `platform`; vault/Blob zone IDs are required when those capabilities are enabled. |
| DDoS plan | Never created here. | Optional association through `platform.ddos_protection_plan_id`. |
| Application Insights | Off by default. Explicitly create a component or reference an approved application/environment component. | `monitoring.enabled`, `create_application_insights`, `existing_application_insights`. Reuse requires the same central LAW. |
| Failed-request alert | Off by default; can create a rule when telemetry and alerts are enabled. | `create_failed_requests_alert=false` plus `existing_failed_requests_alert` references an external rule and its existing routes. |
| Action group | Created only for a new enabled alert with explicit approval and recipients. | Prefer `operations.platform_action_group_keys` or `action_group_ids`; no missing-key fallback creation. |
| Audit diagnostic settings | Created by default for every enabled vault/storage target. | `diagnostics.existing_settings` references external settings. Disabling creation never permits removing required audit coverage. |
| VM backup protection | None by default; optional enrollment of existing VMs only. | Supply existing same-subscription vault/policy/VM IDs in `backup`; `null` or `enabled=false` disables enrollment. Vault/policy and compute are not created. |
| Hub attachment and DNS VNet links | Never created here. | A separate platform-controlled attachment state consumes `attachment_contract` and creates both peerings and required links. |

Reader/Contributor grants use existing group IDs in `workload_access_group_ids`;
Entra groups/PIM remain externally owned. Select `resource_group_keys` to narrow
a grant; omitting them grants the requested role across all blueprint RGs.
Vault readers get scoped Secrets User; Officer groups must be explicitly supplied.
Storage Blob Data Contributor requires `grant_workload_blob_access=true`.

**Not included:** subscription vending/onboarding, MG moves, compute/AKS/PaaS
runtimes, databases, ingress/WAF, hub firewalls/gateways/Bastion, central LAW/
Sentinel, Defender pricing and VNet flow logs. Those retain platform/application
ownership. Budgets and management locks are not implemented in this Phase 1 blueprint.

OBS-09 telemetry and OBS-04 alerts remain opt-in pending approved scope, SLOs and
recipients. Disabled optional services do not establish production observability
coverage; retain the documented security/operations release sign-off.

## Basic Usage

Caller example from the catalog/package root; define these root variables and
configure providers/backend using the supplied [workspace templates](../../implementations/workload-lz/workspaces).
There is no global `enabled` input on this module; deployment roots/examples
provide their own enable/approval gates.

```hcl
module "spoke" {
  source = "./patterns/terraform-azurerm-compeer-spoke-landing-zone"
  providers = {
    azurerm     = azurerm
    azurerm.dns = azurerm.dns
  }

  subscription_id             = var.subscription_id
  tenant_id                   = var.tenant_id
  environment                 = var.environment
  location                    = var.location
  appcode                     = var.appcode
  domain                      = var.domain
  workload_tags               = var.workload_tags
  platform                    = var.platform
  address_space               = var.address_space
  reserved_address_spaces     = var.reserved_address_spaces
  inspection_address_prefixes = var.inspection_address_prefixes
  subnets                     = var.subnets
  egress_next_hop_ip          = var.egress_next_hop_ip
}

output "attachment_contract" {
  value = module.spoke.attachment_contract
}
```

Re-export required contracts from the caller: child-module outputs are not
automatically visible to another HCP workspace. The shared deployment adapter
reads declared platform outputs with `tfe_outputs`, not full remote state.
It additionally requires readable governance `mandatory_tag_keys`. Output-read
authorization is separate from Azure authentication; do not enable broad state sharing.

## Inputs

[variables.tf](variables.tf) is the authoritative nested schema. `object` and
`map(object)` below are schema summaries, not untyped inputs.

| Input | Type | Default | Purpose |
| --- | --- | --- | --- |
| `subscription_id` | `string` | Required | Existing workload subscription UUID; must match the provider. |
| `tenant_id` | `string` | Required | Common Entra tenant UUID. |
| `environment` | `string` | Required | `prod`, `dev`, `test`, `uat`, `np1`, `np2`, `np3`; `nonprod` is not a valid token. |
| `appcode` | `string` | Required | Approved application naming/tag token. |
| `workload_tags` | `object` | Required | Stable, approved business/governance metadata; fields below. |
| `platform` | `object` | Required | Existing public platform contracts and resource IDs; fields below. |
| `address_space` | `list(string)` | Required | IPAM-approved IPv4 VNet ranges. |
| `subnets` | `map(object)` | Required | At least two subnets, including non-delegated `private_endpoints`; prefixes /29 or larger. |
| `egress_next_hop_ip` | `string` | Required | Approved NVA/firewall IPv4 frontend within the hub range. |
| `location` | `string` | `"centralus"` | Supported Azure region; naming derives its abbreviation. |
| `domain` | `string` | `"internal-apps"` | Workload naming domain. |
| `reserved_address_spaces` | `list(string)` | `[]` | Complete relevant on-prem/other-spoke IPAM inventory; hub overlap is checked automatically. |
| `inspection_address_prefixes` | `list(string)` | `[]` | Exact approved remote prefixes forced through the NVA, distinct from IPAM inventory. |
| `private_endpoint_client_cidrs` | `list(string)` | `[]` | Additional approved HTTPS clients, such as private deployment agents; spoke CIDRs are included. |
| `allow_azure_provided_dns` | `bool` | `false` | Explicit exception when central DNS server IPs are not supplied. |
| `gateway_transit_enabled` | `bool` | `false` | Requested intent only; central attachment must approve/apply matching flags. |
| `manage_hub_attachment` | `bool` | `false` | Compatibility guard: must remain false; true fails validation. |
| `key_vault` | `object` | `{}` | Defaults to `enabled=true`, `sku_name="standard"`; optional name, secret readers and Officer group IDs. |
| `diagnostics` | `object` | `{}` | Defaults to `enabled=true`, `existing_settings={}`; reuse exact target settings, not substitute destinations. |
| `workload_access_group_ids` | `map(object)` | `{}` | Group `principal_id`, Reader/Contributor `role`, optional RG-key selection. |
| `operations` | `object` | `{}` | Creation defaults false; platform action-group keys, explicit IDs and notification email sets default empty. |
| `monitoring` | `object` | `{}` | Defaults: `enabled=false`, `create_application_insights=false`, `alerts_enabled=false`; `create_failed_requests_alert=true` is used only when alerts are enabled. |
| `storage_accounts` | `map(object)` | `{}` | Per-key `enabled` defaults true; optional name, replication/retention overrides and explicit data-access grant. |
| `backup` | `object` | `null` | When supplied, requires `recovery_vault_id`, `backup_policy_id`, `virtual_machines`; `enabled` defaults true. |

**Tag fields:** `application`, `owner`, `source_repo`, `created_on`,
`criticality_tier`, `data_classification`, `lifecycle_state`, `cost_center`,
`gl_category`, `dr_tier`. Optional: `application_component`, `modified_on`,
`additional_tags`. Keep `created_on` lifecycle-owned and stable, never `timestamp()`;
the shared root persists it with `time_static`. Approved mandatory keys must exist.

**Platform fields:** `management_contract_version` and
`connectivity_contract_version` must both be `"0.1.0"`; provide
`log_analytics_workspace_id`, `hub_virtual_network_id`, `hub_address_space`
and hybrid `dns_server_ips` unless explicitly excepted. Conditional zone IDs:
`key_vault_private_dns_zone_id`, `storage_blob_private_dns_zone_id`. Optional:
`ddos_protection_plan_id`, governance `mandatory_tag_keys`, and
`action_group_ids` keyed by approved audience, for example `primary`.

## Configuration Examples

These assignments go inside the module call; `var.*` refers to caller variables.
For the [example root](examples), use top-level tfvars objects with literal IDs,
not variable references. Workspace templates nest these objects **inside `spoke`**.
Terraform replaces objects between tfvars files; it does not deep-merge them.

### Create Telemetry, Reuse Alert Routing

```hcl
monitoring = {
  enabled                     = true
  create_application_insights = true
  alerts_enabled              = true
}
operations = {
  create_action_group        = false
  platform_action_group_keys = ["primary"]
}
```

This creates an application component and failed-request rule, referencing
`platform.action_group_ids.primary`. To use explicit contacts instead, replace
the key set with `action_group_ids=[existing_id]`. To create a new application
group, use `create_action_group=true` and approved `notification_emails`.
Emails are invalid when creation is false; no group is created without a new alert consumer.
The shared workspace adapter can select the enabled platform `primary` group;
a direct module call must choose its routes explicitly.

### Reuse Telemetry And An Existing Alert

```hcl
monitoring = {
  enabled                     = true
  create_application_insights = false
  existing_application_insights = {
    id           = var.existing_application_insights_id
    workspace_id = var.platform.log_analytics_workspace_id
  }
  manage_existing_telemetry_access = false
  alerts_enabled                   = true
  create_failed_requests_alert     = false
  existing_failed_requests_alert = {
    id                      = var.existing_failed_requests_alert_id
    application_insights_id = var.existing_application_insights_id
    action_group_ids        = var.existing_alert_action_group_ids
  }
}
operations = {}
```

Reuse only an approved same-application/environment component, not a shared
catch-all across unrelated workloads. Existing alerts must target that component
and have non-empty existing routes; do not supply new `operations` routes when
reusing the rule. Component configuration and alert/routing ownership stay external.
Verify the existing component's actual LAW linkage, Entra authentication and
network path. New components grant the workload UAMI scoped Monitoring Metrics
Publisher; for reuse, the owner must grant publishing rights or delegate them with
`manage_existing_telemetry_access=true`. The runtime still needs its SDK/agent
and must attach/select the UAMI; this module does not instrument applications.

### Reuse Audit Settings Without Duplicate Creation

Vault-only example; the parent vault must already be managed in this state:

```hcl
diagnostics = {
  enabled = false
  existing_settings = {
    key_vault = {
      id                = var.existing_vault_audit_setting_id
      workspace_id      = var.platform.log_analytics_workspace_id
      log_categories    = ["AuditEvent"]
      metric_categories = ["AllMetrics"]
    }
  }
}
```

`enabled=false` disables **creation**, not auditing. Declare every enabled
target below; with `enabled=true`, named existing settings are reused and the
remaining required settings are created. IDs must be canonical ARM
`.../providers/Microsoft.Insights/diagnosticSettings/NAME`, never `TARGET|NAME`.
Declared target, destination and categories are checked; live configuration must
also be independently verified.

| Setting key | Exact target | Required logs | Required metrics |
| --- | --- | --- | --- |
| `key_vault` | Workload vault | `AuditEvent` | `AllMetrics` |
| `storage.<key>.account` | Storage account | None | `AllMetrics` |
| `storage.<key>.blob` | Account's `blobServices/default` | `StorageRead`, `StorageWrite`, `StorageDelete` | `Transaction` |

Use `diagnostic_ownership` and each storage account's diagnostic target IDs for
approved exact-resource registration with platform-policy when strict Terraform
ownership is required. Do not create duplicate settings, blanket exemptions,
vault-category Blob logs or `allLogs` on the storage-account parent.

### Complete Runnable Variants

[examples/README.md](examples/README.md) and
[baseline.tfvars](examples/baseline.tfvars) supply synthetic reference values,
not client deployment approval. Combine the baseline with exactly one variant:

| Variant | Use case |
| --- | --- |
| [phase-one](examples/variants/phase-one.tfvars) | Dedicated audited vault and foundation; optional services off. |
| [all-optional-off](examples/variants/all-optional-off.tfvars) | Approved secretless workload; network and identity remain. |
| [production-create](examples/variants/production-create.tfvars) | ZRS Blob storage, telemetry, alert and dedicated contacts. |
| [new-telemetry-shared-alert-routing](examples/variants/new-telemetry-shared-alert-routing.tfvars) | New telemetry/rule with platform action-group reuse. |
| [nonproduction-private-telemetry](examples/variants/nonproduction-private-telemetry.tfvars) | Dev profile with an already approved AMPLS/private DNS path. |
| [reuse-observability](examples/variants/reuse-observability.tfvars) | Existing component, alert, routes and external audit settings. |
| [existing-vm-backup](examples/variants/existing-vm-backup.tfvars) | Protect existing VMs with an existing workload vault/policy. |

## Profiles And Security

| Setting | Production | Non-production |
| --- | --- | --- |
| Blob replication | ZRS default; only ZRS/GZRS/RAGZRS accepted | LRS default |
| Blob/container soft deletion | 30 days default/minimum | 7 days default |
| Telemetry sampling | 100% starting value | 20% starting value |
| Failure alert severity / frequency / 5-minute count | 1 / PT1M / 5 | 3 / PT5M / 20 |
| Vault, subnet controls, TLS/keyless storage and central audit coverage | Same baseline | Same baseline |

Sampling and failed-request thresholds are tunable starting values, not an
approved application SLO. Central LAW/table retention stays platform-owned and
is not reduced by choosing a non-production profile.

- **Network:** every subnet has an NSG/UDR, default outbound access off and
  gateway BGP propagation disabled. Default plus hub/approved remote-prefix routes
  use the NVA. Sunstream `10.169.0.0/16` is explicitly blocked at priority 100.
  Supply complete reserved ranges and exact inspection prefixes; overlap/
  containment checks do not allocate IPAM or prove NVA readiness/return-path symmetry.
- **Application rules:** priorities 300-4000; reserved baseline names cannot be
  overwritten. Use one address/prefix-set/ASG form per side and one destination-port
  form; omitted source ports mean `*`. Internet-wide inbound allows are rejected.
  ASGs must be in the workload subscription; application owners verify NIC/VNet membership.
- **Private access:** the `private_endpoints` subnet is always required, even
  when optional services are off; no delegation or service endpoints there.
  Private-zone links do not configure DNS forwarders. Gateway transit is intent
  only, requiring separate network approval and paired central attachment flags.
- **Vault/storage:** RBAC-only private vault, ACL Deny, purge protection and
  90-day soft delete; no automatic operator secret access. Blob storage uses
  TLS 1.2, HTTPS, no public/shared-key access, versioning and delete retention.
  No containers/blobs are created; data operations need private network access.
- **Telemetry/recovery:** new telemetry is Entra-authenticated but defaults to
  public HTTPS ingestion/query through approved egress, not private-only access.
  Disabling either endpoint requires a working central AMPLS/DNS path and
  `private_link_ready=true`; that declaration is not connectivity proof.
  Backup needs compatible VM/vault region and permissions, approved RPO/RTO and
  restore evidence. Supplied roots retain backup data on protection removal.

## Outputs

[outputs.tf](outputs.tf) defines these non-secret contracts. Disabled services
return null IDs or empty collections; outputs do not prove runtime connectivity.

| Output | Consumer/purpose |
| --- | --- |
| `contract_version` | Blueprint consumer contract `1.0.0`, distinct from a module release version. |
| `resource_group_names`, `resource_group_ids` | RGs keyed by logical purpose; `application` maps to the `app-rg` naming purpose. |
| `spoke_virtual_network_id`, `subnet_ids` | Network ID and logical-key subnet IDs for application resources. |
| `key_vault` | Vault ID/name/URI and PE ID; null when disabled, never secret contents. |
| `workload_identity` | UAMI resource, client and principal IDs for runtime attachment/authentication. |
| `log_analytics_workspace_id`, `mandatory_tag_keys` | Approved platform passthroughs so applications need no platform-state access. |
| `attachment_contract` | Contract `2.0.0`: network IDs, naming context, gateway intent and required DNS zones; names/attachments owned centrally. |
| `application_services` | Application RG, telemetry/alert/contact ownership and IDs, storage endpoints/recovery/diagnostic targets, backup enrollments. |
| `diagnostic_ownership` | Exact targets, owner, required categories and declared external setting IDs. |
| `security_baseline` | Configuration evidence and security-resource IDs, not policy-compliance attestation. |
| `environment_profile` | Resolved environment defaults. |
| `context` | Subscription, tenant, environment, region, naming context and shared tags. |

No instrumentation keys, connection strings or secret values are published.

## Deployment And Lifecycle

1. Replace synthetic values, obtain IPAM/security/operations approval and configure
   the approved backend, provider contexts and public-output read permissions.
   Use the [production/non-production roots](../../implementations/workload-lz/workspaces)
   for separate application/environment states; committed placeholders stay disabled.
2. Review/apply the workload foundation. Root examples use `enabled` and
   `deployment_approved` gates; a disabled plan is not enabled-resource validation.
3. Re-export `attachment_contract` and apply the separately authorized central
   [network-peering adapter](../terraform-azurerm-compeer-network-peering).
   It owns both peerings, their names and required VNet/private-zone links.
4. Validate both peerings Connected, effective routes/firewall symmetry, private
   DNS/access, audit ingestion, telemetry/notification delivery and backup restore
   where applicable. Apply application compute separately.

**Reuse is not import or ownership transfer.** Parents referenced by reused
diagnostics must already be in this state, with settings owned elsewhere.
Switching a deployed resource to disabled/reuse can plan destruction; first
arrange an approved state handoff and verify no unintended destroys.
Never manage a peering, zone link or diagnostic setting from two states.

Do not repoint a legacy workload-spoke state at this blueprint. Naming follows
`<app>-<region>-<env>-<purpose>-rg`, for example `orders-cus-prod-app-rg`;
correcting old names, changing environment/replication or removing existing budgets
requires migration/replacement review. `moved.tf` covers only declared address
changes, not cross-state handoffs. See [ATTACHMENT.md](../../implementations/workload-lz/ATTACHMENT.md)
and [REUSE.md](../../implementations/workload-lz/REUSE.md).

## Validation And Maintenance

From the catalog root, run all spoke, attachment, helper, workspace and seven
example-variant suites:

```bash
bash implementations/workload-lz/test.sh
```

For direct module tests, initialize first and run `terraform test`.
[TESTING.md](../../implementations/workload-lz/TESTING.md) records verification;
[integration-tests](integration-tests/README.md) documents the isolated,
billable opt-in Azure fixture. Mock success is not live acceptance, private
registry certification or permission to deploy placeholders.

Provisioning stays in `main.tf`, one locals block in `locals.tf`, cross-input
contracts in `contracts.tf`, typed inputs in `variables.tf` and public contracts
in `outputs.tf`. [DESIGN-ALIGNMENT.md](../../implementations/workload-lz/DESIGN-ALIGNMENT.md)
and [STEP11.md](../../implementations/workload-lz/STEP11.md) retain placement,
component mappings, holds and ownership decisions.

Further guidance: [Private Link/DNS in hub-spoke networks](https://learn.microsoft.com/en-us/azure/architecture/networking/guide/private-link-hub-spoke-network),
[hub-spoke topology](https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke),
[Key Vault isolation and security](https://learn.microsoft.com/en-us/azure/key-vault/general/secure-key-vault),
[explicit outbound access](https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/default-outbound-access).
