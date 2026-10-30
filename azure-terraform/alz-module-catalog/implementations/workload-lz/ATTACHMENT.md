# Central Network Attachment

Decision revised: 2026-10-28. Compeer's default is one **platform-owned attachment
workspace per environment and hub/network security boundary**, managing multiple
approved spokes. Dedicated per-spoke states are approved exceptions, not the default.
The authoritative [peering standard](../platform-lz/PEERING-STANDARD.md) defines
the inventory, OIDC/RBAC, routes, shared-hub gate and migration requirements.
Both peering directions and approved private-DNS VNet links share one owner. The
spoke blueprint creates neither peering nor zone-to-VNet link. The reusable
hub-spoke-peering pattern remains the central owner's Azure implementation,
and still composes the existing base peering module twice.

## Ownership And Stages

| Stage | Owner and resources |
| --- | --- |
| 1. Provision foundation | Spoke state: workload RGs, VNet/subnets/NSGs/UDRs, dedicated identity/vault, workload private endpoints and their DNS zone groups; publish attachment_contract. Network approves IPAM and the Git attachment inventory. |
| 2. Attach | Environment/hub platform network state: cross-check producer contracts against approved inventory; serialize changes, create both directions and approved DNS links. Hub/spoke route and Panorama changes stay with their existing owners. |
| 3. Accept | Verify both Connected, DNS, private access, routing/NVA symmetry, policy/log ingestion and stakeholder approval. |
| Subscription onboarding | Governance/CSP, unchanged. No vending or subscription creation is introduced. |

There is no reverse state dependency: the spoke does not read attachment
outputs or wait for connectivity while creating its foundation. Stage 1 is not
a declaration that the application can reach platform services. Attach before
deploying applications that need private DNS or connectivity.

The blueprint no longer requires a hub provider. The DNS alias remains for
the existing-zone subscription assertion; workload endpoint zone groups still
need explicitly approved zone join/read permissions. Optional shared DDoS and
LAW integrations may also need approved reference permissions. Removing peering
write is not a claim that all cross-subscription permissions disappear.

## Target Model And Current Single Pair Configuration

The new batch composition accepts a typed attachment map with stable logical
keys. Four roots named platform-network-peering-np1/np2/np3/prod are illustrative
when there is one compatible hub/network boundary per environment. Each needs its
own directory, release pin, state and trigger path, not runtime tfvars selection.
They are not mandatory: applications may have only one, two or three environments,
and the batch creates only declared instances. The [generic root template](../platform-lz/templates/network-attachments/README.md)
supports other approved labels and platform VNet lifecycle boundaries using the
generic v3 producer. Existing workload-v2 remains compatible; existing identity
half-peerings are never silently taken over.
Environment identities hold only approved resource-scoped grants; they are not
one deployer per application or a tenant-wide network identity. A shared hub still
requires one common deployment gate across all environment roots and exceptions.

**Implemented separately:** the [AzAPI batch pattern](../../patterns/terraform-azapi-compeer-network-attachments/README.md)
and four new environment roots accept the typed map and use full parent IDs across
subscriptions without per-subscription aliases. The adapter/root below remains a
single-pair compatibility building block. [Gate setup, scoped OIDC/RBAC, publishing
and live adoption](../platform-lz/network-attachments/README.md) are required before
enabling the new roots. No deployed resources or backend bindings are moved here.

Both workload templates remain disabled and explicitly set:

```hcl
spoke = {
  enabled               = false
  manage_hub_attachment = false
  # Other approved workload inputs remain required.
}
```

The old flag is retained only as a compatibility guard: true now fails the plan.
No peering/link resource blocks remain behind it.

The existing implementations/platform-lz/workspaces/platform-network-peering
root remains the single-pair compatibility/example implementation for the second
stage. Do not duplicate it per application as the new default or repoint live
states to an environment root without the reviewed handoff. See the standard's
release/adoption gates for the multi-attachment target.

Inside that existing single-pair workspace's network_peering input (not the
new environment attachment-map interface):

```hcl
{
  enabled                              = true
  use_tfe_outputs                      = true
  use_spoke_attachment_contract         = true
  tfe_organization                     = "REPLACE_HCP_ORGANIZATION"
  platform_connectivity_workspace_name = "REPLACE_CONNECTIVITY_WORKSPACE"
  workload_spoke_workspace_name        = "REPLACE_APPLICATION_ENVIRONMENT_WORKSPACE"
  hub_to_spoke                         = {}
  spoke_to_hub                         = {}
  private_dns_zones                    = {} # Exact required zones come from the contract.
}
```

Replace placeholders before enabling. The committed attachment example remains
disabled. Set tenant_id, hub_subscription_id, spoke_subscription_id and the
actual private_dns_subscription_id as Terraform-category workspace inputs.
Configure approved Azure dynamic credentials and scoped HCP output-read access.
Do not enable full remote-state sharing merely to read tfe_outputs.

The adapter reads attachment_contract (or the nested spoke.attachment_contract)
from nonsensitive_values only. Contract mode validates versions 1.0.0/2.0.0, central
ownership, approved hub/provider targets and every requested DNS link's actual
zone name/RG/subscription. New version 2 contracts supply naming_context and no
attachment names. The central adapter calls Compeer naming 1.0.1 with the actual
hub/spoke VNet names, preserving the previous canonical peering/link names.
Version 1 remains supported with its published names unchanged.
Published workload tags are carried onto the central DNS links, with
explicit central tag overrides merged in; review overrides during migration.
An omitted or unsupported contract fails instead of using legacy default
zones. Legacy adapter callers retain their existing input mode unless they
explicitly opt into use_spoke_attachment_contract.

Gateway transit stays off by default. A request in the spoke contract is not
central approval: after network readiness/sign-off, the central owner must
explicitly set BOTH hub_to_spoke.allow_gateway_transit=true and
spoke_to_hub.use_remote_gateways=true to match a true request. Mismatches fail.
Paired intent validation does not make the two Azure writes atomic.

## Attachment Naming Upgrade

Only the nested attachment contract changes to 2.0.0; the outer workload consumer
contract remains 1.0.0. The spoke no longer calls attachment_naming or publishes
peering_names/link_name. Its naming_context is workload metadata, not authority
to choose attachment names. The central adapter rejects v2 contracts that still
try to supply those names.

1. Upgrade the central attachment consumer first. It accepts existing v1 contracts
   and preserves their custom names; review its plan before applying.
2. Publish the updated spoke v2 contract. The primary workload naming call, VNet
   names, resources and endpoint ownership are unchanged.
3. Plan central attachment again. Canonical names and Azure resource addresses
   stay the same. For existing custom names, set central inputs before switching:

   ```hcl
   peering_names = {
     hub_to_spoke = "REPLACE_EXISTING_HUB_PEERING_NAME"
     spoke_to_hub = "REPLACE_EXISTING_SPOKE_PEERING_NAME"
   }
   private_dns_link_names = { key_vault = "REPLACE_EXISTING_DNS_LINK_NAME" }
   ```

   These are fields inside the central workspace's network_peering object.
   Include storage_blob only when that zone is required. Do not apply unexpected
   replacements or DNS-link renames.

Moving this calculation alone requires no Azure-resource state transfer. An
earlier spoke-to-central resource-ownership migration still requires the separate
reviewed handoff below; this naming change does not perform it.

## Permissions And Change Control

Use scoped custom permissions for VNet/peering reads, peering create/update and
delete, and any required remote VNet peer/join operations on the approved pair.
Write-only permissions are insufficient for Terraform lifecycle management.
Zone-link permissions are separately scoped to the actual approved zones.
Have security validate the complete operation set; do not grant subscription-wide
Owner or broad Network Contributor merely for attachment.

An environment principal's hub-VNet-scoped role can still affect other peerings
under that hub, even in other environments. Explicitly review that residual scope;
separate state or OIDC principals do not make it per-peering isolation. Prefer
distinct read-only plan and bounded apply identities with exact workspace/phase
federation subjects. Verify all hub/spoke/DNS aliases with actual dynamic credentials.

Keep platform credentials out of application pipelines. Protect PRs, constrain
apply permissions, separate environments and retain audit evidence. Interactive
PIM/JIT elevation is not assumed to work automatically for an unattended HCP
identity; use the organization's approved automation identity controls.

Serialize attachment changes against the same hub across workspaces. HCP's
per-workspace state lock does not coordinate independent states. The module
orders its own pair only; shared-hub orchestration is an operational gate,
not a feature silently implemented by a Terraform dependency.

The batch implementation must also serialize operations within its own graph;
per-pair dependencies do not order different pairs. Gate relevant connectivity
changes and manual/HCP apply paths as well; a run trigger or approval is not a mutex.

## Routing And Legacy Platform Exception

Hub route tables and their currently inline routes stay in connectivity; spoke
UDRs stay in the spoke owner, and Palo Alto rules/NAT stay with Panorama owners.
Do not add standalone routes from attachment state to those inline-managed tables.
Onboarding may require a connectivity plan and coordinated firewall change; a
default route alone does not prove inspection of more-specific prefixes.

The current identity connection is a legacy split-owner platform exception:
connectivity owns additional_vnet_peerings.identity and directory-services owns
the reciprocal hub_connection. Preserve both until a reviewed handoff transfers
them; this standards update does not change or duplicate them. The VNet resources
themselves always remain exclusively in their foundation states.

## Existing Attachment Migration

**Do not apply a plan deleting existing peerings or DNS links.** Removing their
blocks from the spoke configuration can propose destruction while their state
bindings remain. Setting the old flag false is not a state transfer.

1. Pause automated applies for both states and record actual Azure resource IDs,
   names, gateway flags, DNS links and exact state addresses. Preserve approved,
   access-controlled state backups; state can contain sensitive data.
2. Publish/approve the matching contract and central configuration. Keep existing
   names and settings; this change does not authorize renames or gateway changes.
3. In a coordinated change window, an authorized operator removes ONLY the
   attachment bindings from the old state without destroying Azure resources,
   then imports those same Azure IDs into the central state. Do not import them
   into a second active owner or run an apply in between the handoff steps.
4. Review both plans. The spoke must not delete attachments; central must not
   create duplicates or replace them. Resolve all unexpected changes before apply.
5. Validate live Connected states, DNS/private access and routing, then revoke
   obsolete hub peering permissions from the spoke run identity.

Inventory may contain earlier inline hub_to_spoke/spoke_to_hub addresses or the
later module.peering[0] addresses. Transfer the actual bindings, not assumed ones.
The destination root uses module.network_peering[0].module.attachment with
module.hub_to_spoke_peering, module.spoke_to_hub_peering and
module.private_dns_spoke_links. No state removal/import, RBAC change, HCP
workspace creation or Azure apply is executed by this code update.

A VNet rebuild does not necessarily change its ARM ID: the ID depends on
subscription, RG and name. Even when the ID is unchanged, recreation can disrupt
peering and requires refreshed attachment/runtime validation.

## Evidence And Guidance

The adapter tests provision the real blueprint with mocked Azure, then consume
its output in a separate module state to test central attachment. Tests also
reject competing ownership, unreadable contracts, wrong versions, missing DNS
and unapproved gateway intent. The optional isolated live fixture composes
foundation and attachment as separate modules; it is not a deployment to Compeer.

Microsoft documents [cross-subscription peering and its permissions](https://learn.microsoft.com/en-us/azure/virtual-network/create-peering-different-subscriptions)
and [subscription-vending automation](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/subscription-vending).
Those support automated platform connectivity, not a mandate for one Terraform
workspace layout or a claim about how every enterprise deploys it.
Microsoft's [hub-spoke reference architecture](https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke)
describes centralized platform ownership of shared hub networking, and the
[Azure landing-zone vending module](https://github.com/Azure/terraform-azurerm-lz-vending/blob/main/README.md)
supports paired peering automation. A separate central attachment state is
Compeer's design choice to keep workload identities from writing hub peerings,
not a universal Microsoft requirement or a guarantee of atomic Azure writes.
See [ACCEPTANCE.md](ACCEPTANCE.md) for the pending live evidence.
