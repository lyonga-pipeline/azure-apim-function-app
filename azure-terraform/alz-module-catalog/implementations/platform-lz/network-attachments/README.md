# Network Attachment Operations

Implementation of [Option A](../../../patterns/terraform-azapi-compeer-network-attachments/README.md): central ownership of both directions in two independent roots: **`platform-network-peering-prod`** and **`platform-network-peering-nonprod`**. Production is fixed to prod. Non-production allowlists actual environments (initially dev/test/uat/sandbox; sbx is an explicitly approved alternative), retaining each producer label. Its environments share release, approval and permission boundaries. Use the [copy-once independent-root template](../templates/network-attachments/README.md) for shared platform or other approved environments; create only needed roots. Existing single-pair and identity states remain untouched until a reviewed handoff.

The two roots resolve hub/spoke VNet IDs from their explicitly approved public producer workspaces during plan; their committed tfvars no longer duplicates those IDs. Explicit IDs remain optional checked pins. This does not discover or authorize additional workspaces, change VNet ownership or remove CIDR/contract checks. Any producer rebuild/new ID still requires renewed network approval and full plan review; see the [workspace-output reference](../workspaces/platform-network-peering-nonprod/README.md#read-vnet-ids-from-workspace-outputs).

## How It Works In Plain Language

**The application workspace builds its network. The central peering workspace reads that network's published details, checks them, and creates the two connections to the hub.** It does not build or take ownership of either VNet.

### The Main Pieces

| Term | Simple Meaning |
| --- | --- |
| HCP Terraform | The service hosting the producer and peering workspaces and their runs/outputs. |
| Deployment root | The environment folder containing `main.tf`, `terraform.tfvars`, provider configuration and its backend/workspace binding. Engineers configure attachments here. |
| tfvars | The root's input values: which workspaces to read, which connections are approved and how they should be configured. |
| Central peering workspace | The platform-owned HCP workspace/state that runs this root and owns its peering resources. Production and non-production have separate roots/states. |
| State | Terraform's record of the resources a workspace manages. Reading another workspace's output does not transfer that resource into this record as a managed resource. |
| Producer workspace | The existing workspace that owns a hub or spoke VNet. It publishes outputs that other configurations can read. Its name does not have to contain "spoke". |
| Output | A value published by a producer, such as its VNet resource ID. It comes from the producer's last applied state, not an unapproved future plan. |
| Attachment | One reviewed map entry connecting one existing VNet to the hub. `pltinapp_dev` is an example stable Terraform key, not a VNet ID. |
| Attachment pattern | The reusable `terraform-azapi-compeer-network-attachments` module. It reads outputs, checks the inventory and creates both peering directions and any requested DNS VNet links. |
| AzAPI provider | The Terraform plugin that sends requests to Azure's resource-management API. Full resource IDs tell it which subscription and VNet each request targets. |
| Contract | A published object describing the VNet and its attachment intent: IDs, ownership, naming, gateway settings and DNS intent. It is a data interface, not an Azure permission grant. |
| `contract-and-azure` | An explicit v2 metadata-validation mode: read environment/naming from the existing producer contract, and tenant/subscription details from Azure. |

```text
Network-approved root terraform.tfvars
  hub.workspace --------------------> Hub workspace's published outputs
  attachments.<key>.producer.workspace -> Spoke workspace's published outputs
                  |                               |
                  +-------- resolved VNet IDs -----+
                                   |
                    Attachment pattern checks:
                    inventory + contracts + Azure
                                   |
                       Reviewed, gated apply
                                   |
                  Hub-to-spoke AND spoke-to-hub
                    + requested DNS VNet links
```

The HCP output read is authorized access to selected non-sensitive outputs, not a download of the entire producer state. "Public output" here does not mean publicly accessible on the Internet. [HashiCorp: `tfe_outputs`](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/outputs).

### One Pilot Attachment From Start To Finish

This is a **root tfvars fragment explaining the reviewed pilot**, not a complete deployment configuration. Keep your root's approved tenant, authentication, adoption controls and external IPAM inputs as well. The workspace names below came from that pilot; another application must select its own actual VNet-owner workspace.

```hcl
hub = {
  organization     = "Compeer-Financial-Services"
  workspace        = "platform-compeer-connectivity"
  contract_version = "0.1.0"
  address_space    = ["10.102.0.0/21"]
  gateway_ready    = false
}

attachments = {
  pltinapp_dev = {
    attachment_kind = "workload"
    environment     = "dev"
    producer = {
      organization     = "Compeer-Financial-Services"
      workspace        = "platform-compeer-identity"
      contract_version = "2.0.0"
    }
    producer_context_source = "contract-and-azure"
    naming_context = {
      region      = "centralus"
      environment = "dev"
      domain      = "internal-apps"
      appcode     = "pltinapp"
    }
    address_space           = ["10.102.64.0/27"]
    approval_reference      = "REPLACE_WITH_APPROVED_CHANGE"
    ipam_reference          = "REPLACE_WITH_APPROVED_IPAM_RECORD"
    allow_forwarded_traffic = true
    gateway_transit         = false
    peering_names = {
      hub_to_spoke = "peer-hub-to-workload-cus-dev-int-pltinapp-vnet"
      spoke_to_hub = "peer-workload-cus-dev-int-pltinapp-vnet-to-hub"
    }
    private_dns_zone_ids = {} # Only when the producer requests no attachment-owned DNS links.
  }
}
```

**1. The root selects existing workspaces, not copied VNet IDs.** `hub.workspace` identifies the hub owner. `attachments.pltinapp_dev.producer.workspace` identifies this spoke's owner. The pilot used `platform-compeer-identity` because it published the pilot VNet outputs; that name is not a rule for other applications. Select by actual ownership and published contract, not by guessing from a workspace name.

**2. The root calls the attachment pattern once with the inventory map.** Inside the pattern, `data.tfe_outputs.hub` reads the selected hub outputs. `data.tfe_outputs.spoke` uses `for_each` (a loop over the approved entries) to read the selected producer for every attachment key. The reusable code does not contain a hardcoded pilot workspace name, subscription or VNet ID. Terraform data-source expressions belong in `.tf` files, not in tfvars.

**3. The pattern resolves the hub and spoke IDs.** Without optional explicit pins, the hub ID comes from `hub_virtual_network_id`. The spoke ID comes from `spoke_virtual_network_id`; a supported producer can instead expose it inside its attachment contract. V2 supports `attachment_contract` or the existing `spoke.attachment_contract` wrapper; generic v3 uses `network_attachment_contract`. If both a top-level spoke ID and a contract ID exist, they must agree. A supplied explicit ID is also checked, not allowed to override the contract silently.

For the pilot, this resolved `platform-cus-prod-hub-vnet` and `pltinapp-cus-dev-spoke-vnet`. The word `prod` in the shared hub's name does not relabel the attached pilot: its environment stays `dev`, in the non-production attachment state.

The same lookup is repeated for every approved entry; locals hold the result, not a copied literal:

```text
hub.workspace
  -> data.tfe_outputs.hub[0].nonsensitive_values.hub_virtual_network_id
  -> local.hub_virtual_network_id

attachments["pltinapp_dev"].producer.workspace
  -> data.tfe_outputs.spoke["pltinapp_dev"].nonsensitive_values
  -> spoke_virtual_network_id (or supported contract fallback)
  -> local.spoke_virtual_network_ids["pltinapp_dev"]
```

**4. `contract-and-azure` supplies the missing context without editing the pilot repository.** The existing v2 producer did not publish a separate `context` output. This mode reads the following evidence instead:

| Question | Where The Pattern Gets The Answer | What It Checks |
| --- | --- | --- |
| Which VNet is this? | Selected workspace's public VNet ID and attachment contract | IDs agree; the named VNet exists in Azure |
| Which environment/naming does the producer declare? | `attachment_contract.naming_context` | Exact match with the reviewed root environment/naming, including appcode |
| Which subscription and tenant own it? | Azure GET of the subscription identified by the resolved VNet ID | Returned `subscriptionId` matches that ID and `tenantId` matches the approved tenant; also check the hub subscription |
| Which address space is actually deployed? | Azure GET of the hub and spoke VNets | Live prefixes match the reviewed CIDRs (IP address ranges); checked ranges do not overlap |
| Who should create the peerings and links? | Existing attachment contract | Central attachment ownership, matching hub/gateway/DNS intent and supported contract version |

The mode does **not** search Azure for a matching VNet name or stop using workspace outputs. Workspace outputs identify the VNet; Azure verifies live facts. It does not copy the expected tenant/environment from tfvars to make a check pass. If a producer already publishes context, contradictory context is still rejected. [Microsoft: subscription metadata GET](https://learn.microsoft.com/en-us/rest/api/resources/subscriptions/get?view=rest-resources-2022-12-01).

**5. Preconditions stop mismatched or incomplete requests.** The inventory, producer and IPAM guards must pass before peering creation. They check approved environments, duplicate attachments, naming, versions, hub/spoke IDs, tenant/subscription, CIDRs, DNS intent and gateway readiness. External overlap detection is only as complete as the supplied `reserved_address_spaces`. Approval/IPAM references record evidence; Terraform does not verify the underlying ticket or reserve addresses. Never comment out a guard to obtain a green plan. Diagnostic messages reveal attachment keys and failed check labels, not the compared values.

**6. An approved apply creates the connections, not the VNets.** The pattern creates all hub-to-spoke resources first, then the reverse resources, then requested DNS VNet links. AzAPI uses the full resolved resource IDs to target the correct subscriptions with one provider configuration. `execution_subscription_id` is the provider's starting context, not a restriction that puts every peering in that subscription. The identity must still have scoped rights on the actual targets.

| Peering Resource | Created Under (`parent_id`) | Points To (`remoteVirtualNetwork.id`) |
| --- | --- | --- |
| `hub_to_spoke["pltinapp_dev"]` | Resolved hub VNet ID | Resolved pilot spoke VNet ID |
| `spoke_to_hub["pltinapp_dev"]` | Resolved pilot spoke VNet ID | Resolved hub VNet ID |

For the pilot with no DNS links, the plan had **six additions: two Azure peerings and four Terraform-only contract records**. That is not six Azure networking resources. Once applied, the attachment workspace publishes both peering IDs, resolved VNet IDs, peering names, observed states and any DNS-link IDs in its own `attachments` output.

### What Engineers Still Supply

| Explicitly Reviewed In The Root | Read Automatically By The Pattern |
| --- | --- |
| Hub organization/workspace and contract version | Hub VNet ID and published address space |
| Each spoke's organization/workspace and contract version | Spoke VNet ID and published attachment contract |
| Stable key, environment, v2 naming context, approved CIDRs | Actual VNet address spaces from Azure |
| Context-source choice, approval/IPAM references, forwarding/transit flags and optional explicit resource names | In `contract-and-azure`, actual tenant/subscription metadata |
| Exact DNS zone IDs/link-name overrides when attachment-owned links are requested | IDs/status of managed peerings and links after apply/refresh |

The CIDRs intentionally remain reviewed inputs: automatically reading an ID should not automatically approve a changed address allocation. Workspace selection is also an intentional dependency, not zero coupling. Producers must exist, have applied their published outputs, and permit the required HCP output reads. Missing outputs/permissions fail closed.

`contract-and-azure` is a configuration option, **not another module, provider or workspace**. Existing callers default to `producer_context_source="workspace"`, which requires published `context`/`spoke.context`. The alternative is v2-only; generic platform/workload v3 retains context inside its own contract. Hub `0.1.0`, workload attachment `2.0.0`, and the root's general `1.0.0` outputs describe different interfaces; none is the pattern package release version. Deploy with the approved pattern release/source configured in the root, not by changing those contract numbers to a module version.

### Onboarding And Ownership

To add another spoke, deploy its VNet through its existing owner, publish/apply the supported outputs, add one reviewed entry under the appropriate root's `attachments`, and arrange its scoped permissions. Normally there is no new peering workspace, provider alias or per-application pattern change. Add only environments that actually exist; the nonprod inventory can hold dev/test/uat/sandbox entries together while prod stays separate. Separate boundaries remain available for justified platform/security/lifecycle exceptions.

| State | Managed Resources It Keeps |
| --- | --- |
| Core connectivity | Hub VNet, its subnets/routes and other foundation resources |
| Application/platform producer | Its own spoke VNet, subnets/routes and application foundation resources |
| Central attachment | Both peering child resources and only the approved DNS VNet links |

Reading a VNet ID does not share management of that VNet across states. The attachment state stores references and child resources, not a second managed VNet. The workload pipeline does not need hub peering write permission; the central identity holds the approved attachment permissions.

Keep stable map keys and existing resource names. Renaming/removing an attachment key or changing a resolved VNet ID can replace/delete peerings and links. A rebuilt producer VNet is therefore a new network approval and plan review, not an automatic safe reconnection. Keep optional exact-ID pins where security requires an independent assertion. Never apply a partial runtime inventory against an existing batch state to target one app: omitted entries can be planned for removal.

### Permissions, DNS And Safe Operation

HCP output-read access and Azure permissions are separate: the TFE provider reads only approved workspace outputs; the Azure OIDC identity reads live resources and manages approved peering/link children. `contract-and-azure` additionally needs metadata-only `Microsoft.Resources/subscriptions/read` on the hub and applicable spoke subscriptions. A workspace name or published output grants no Azure access. See the [permission matrix](#permission-review); do not replace exact network rights with broad subscription Contributor/Owner.

Peering alone does not configure DNS or force traffic through the firewall. Empty `private_dns_zone_ids` means no attachment-owned VNet links, and is allowed only when producer intent agrees. Private-endpoint DNS records/zone groups remain with their designated endpoint/DNS owner or approved policy process, not this attachment pattern. The approved resolver/forwarder path must work independently; a spoke does not inherit central private-zone resolution just because it is peered. Routes, NSGs and Palo Alto rules keep their existing owners. [Microsoft: peering settings](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-manage-peering), [private endpoint DNS](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns-integration).

Finally, a provider-process `locks` setting coordinates only this run. The protected shared-hub gate coordinates different workspaces writing the same hub. The gate/ownership booleans are attestations, not mechanisms that configure Azure locks or pipeline approvals. After a reviewed apply, verify both directions are Connected and test actual DNS, inspected traffic and rejected traffic; a successful plan or apply is not end-to-end acceptance. The following checklist and runbook explain those controls.

## Adoption Checklist

1. Confirm the actual application/platform environment boundaries and approve the shared-hub RBAC residual risk. Record one owner per child resource and complete external IPAM ranges. Existing workloads may retain producer-v2; generic platform/workload VNet owners publish producer-v3. Provision VNets, routes, firewall/DNS path and public outputs through their existing owners first. Never require absent app environments or relabel a platform VNet to fit a consumer.
2. Publish/pin the tested new batch pattern and its naming dependency for Compeer deployment. Set each HCP root's independent working directory, state, exact release, main-branch trigger path, tenant and execution subscription. New roots/examples are disabled and contain placeholders. Never repoint an applied old workspace here.
3. Grant exact plan/apply OIDC subjects and least-privilege resource-scoped roles. Configure the injected credential file mapping shown in each root. Grant narrow HCP public-output reads, separately from Azure authentication. Test allowed/denied operations with the actual identities.
4. Configure the protected common-hub gate below **before** setting adoption controls true. Run local/mock CI, review the complete environment plan, and pilot a small approved attachment before adding the estate. Test refresh/no-op, a harmless flag change, partial-apply recovery, import and teardown in an isolated approved pilot. Local mocks do not certify those ARM behaviors.
5. Verify both live peerings Connected/Succeeded and correct DNS links, then test actual private endpoint resolution, representative Palo Alto-inspected flows, symmetric return routes and rejected flows. Record evidence and change/operations owners. A successful apply is not application connectivity acceptance.

## Shared Hub Gate

The repository includes [an ADO template](../../../../../.azuredevops/templates/network-attachments.yml) and [HCP run controller](run_under_hub_gate.py). These are provided tooling, not a claim that Compeer's external controls are configured.

- Create the exact protected ADO Environment `compeer-shared-hub-network-writes`; its administrator configures **Exclusive Lock**, sequential behavior, network/security approvals, allowed main-branch pipelines and protected template/inventory reviewers. Microsoft configures checks outside YAML; `lockBehavior: sequential` alone does not create the check.
- Maintain a reviewed copy of [hub-gate.json.example](hub-gate.json.example) with actual organization/repository identifier, HCP workspace names and directories. Include **every existing** writer to that hub: whichever application/platform attachment roots are actually used, core connectivity, legacy identity and exceptions. The controller accepts approved workspace names dynamically from this list; the active default is prod/nonprod, not a workspace per application or non-production stage. Do not leave nonexistent example workspaces in the live gate list or omit an actual writer.
- In HCP disable auto-apply for all these writers, require plan review/mandatory policy, and restrict direct non-speculative queue/apply paths to the protected network process. VCS may generate speculative plans, but must not independently create/confirm mutating runs outside the gate. Arrange configuration-version creation without an automatically queued unfinished run; reconcile any pre-existing queued/planned run under change control before invoking the controller. A run trigger is not a mutex. Validate the actual HCP permissions/run-task controls for the organization's tier; YAML and a Terraform boolean cannot prevent a privileged UI/API bypass.
- Invoke the template from the reviewed main-branch pipeline with `workspace`, `configurationVersion` and `gateInventory`. Store `HCP_NETWORK_GATE_TOKEN` in the protected secret store with only required workspace/output/run permissions. The agent needs Python 3; Azure credentials remain in HCP's environment-specific OIDC context.
- Inside the protected deployment job, the controller checks every listed writer for unfinished runs, rejects auto-apply, checks the selected working directory/current non-speculative configuration and exact main-branch commit/repository, then queues a fresh non-auto-apply, non-destroy run. Network reviewers inspect and confirm its full plan in HCP while the gate job waits. The controller never overrides policy or applies automatically.
- AzAPI's common `locks` key serializes all peerings **inside one provider process**. It is not an Azure management lock. The external gate serializes separate workspaces/agents. Core writers must also serialize their own hub networking mutations; a per-pair dependency does not serialize a batch.
- On timeout/agent loss, an HCP run can remain active. The next gated controller refuses to queue another hub writer until that run is reconciled. Do not force-cancel or release an incident freeze blindly; inspect Azure's in-flight operations/partial state. Complete planned route/Panorama coordination and live acceptance as part of the change. An external permission or queue path that bypasses this process remains a deployment blocker.

`COMPEER_HUB_GATE_HELD=true` is a job assertion, not a security boundary. Only the protected ADO resource, restrictive HCP access and coverage of **all** hub writers establish the cross-workspace gate. If Compeer cannot enforce those controls, do not enable independent mutating hub pipelines; first establish a single controlled deployment queue or an equivalent enforced HCP run-task coordinator.

## Permission Review

Security owns the final tested role definitions and assignments. Suggested operation/scope matrix, **not automatic role grants**:

| Principal / Resource Scope | Required Operations To Review |
| --- | --- |
| Apply: exact hub and approved spoke VNets | `Microsoft.Network/virtualNetworks/read`, `virtualNetworkPeerings/read`, `virtualNetworkPeerings/write`, `virtualNetworkPeerings/delete`, `peer/action` under `Microsoft.Network/virtualNetworks` |
| Apply: exact approved central zones | `Microsoft.Network/privateDnsZones/read`, `virtualNetworkLinks/read`, `virtualNetworkLinks/write`, `virtualNetworkLinks/delete`, `join/action` under `Microsoft.Network/privateDnsZones` where linked authorization requires it |
| Apply: referenced VNets for DNS linking | Review/test `Microsoft.Network/virtualNetworks/join/action` alongside VNet read and linked-resource permissions |
| Plan: same approved discovery scopes | Required parent/peering/DNS-link reads; no lifecycle writes or role assignment permission |
| Plan and apply: approved hub/spoke subscriptions, only for `producer_context_source="contract-and-azure"` | `Microsoft.Resources/subscriptions/read` for subscription metadata (tenant/subscription identity). A metadata-only custom role at each approved subscription; not broad resource Reader or lifecycle rights |
| Workload endpoint identity, separately | Approved central-zone read/join for endpoint DNS zone groups, without hub attachment write rights |

Expand abbreviated operation names under the shown resource namespace when authoring a role; check [Microsoft's network operation list](https://learn.microsoft.com/en-us/azure/role-based-access-control/permissions/networking) and [subscription metadata operation](https://learn.microsoft.com/en-us/azure/role-based-access-control/permissions/management-and-governance#microsoftresources). Validate ARM-required discovery rights in the pilot, rather than granting broad Contributor for convenience. Peering/DNS lifecycle assignment scopes remain exact resource IDs. The optional v2 contract/Azure context source additionally reads the hub and applicable spoke subscriptions; supply/test metadata-only authorization at those subscriptions. Default workspace context requires no new subscription lookup. Authorization/onboarding manages grants; attachment runs cannot elevate themselves.

Hub-scoped lifecycle permissions cover **all child peerings**, not just this environment's map entries. Environment identities reduce credential/state coupling but do not enforce per-child isolation on a shared hub. Cross-environment inventory uniqueness and current IPAM are network review responsibilities in addition to the batch guards. Gate inventory coverage must be reviewed when adding any new hub writer.

## Testing And Live Acceptance

```bash
bash implementations/platform-lz/network-attachments/test.sh
```

This runs batch tests (v2 and v3), the two roots including mock application of their committed tfvars inventories, the generic platform template, name-only/canonical naming parity, retained single-pair regressions and operating-control/ownership unit tests. These test fixtures do not require deployment of every example root. Providers and producer outputs are mocked; no Azure write, HCP queue or live role change occurs.

After an approved pilot apply, use a read-authorized identity:

```bash
# From the correct attached environment root:
terraform output -json attachments > /tmp/approved-attachments.json
python3 ../../network-attachments/check_live.py /tmp/approved-attachments.json
```

The checker performs GETs only and requires both peerings Connected/Succeeded with correct remote IDs, plus exact spoke DNS links with registration off. Run actual DNS/endpoint/network-security tests from a spoke test host separately; these cannot be proved by the control-plane checker. Re-check on a scheduled basis for stale Initiated/Disconnected or out-of-inventory peerings using the approved estate inventory; this script checks declared members, not discovery of unauthorized ones.

## Consolidated Non-Production Adoption

The unapplied np1/np2/np3 example roots were consolidated into `platform-network-peering-nonprod`. Its new-LZ default allowlist is dev/test/uat/sandbox, not the old np labels. sbx requires exact producer support and explicit approval; it is never normalized to sandbox. Configure actual VNet inventory in Git, not runtime-selected subsets. Complete examples in both roots specify `peer-<vnet>-to-hub` and `peer-hub-to-<vnet>`; they do not migrate the legacy identity pair. Existing automatic names in the reusable pattern are unchanged for compatibility. Preserve exact live names on any import.

If any old example root was applied externally, do not repoint its backend or enable duplicates. Use the handoff below to transfer only approved children into nonprod, preserve stable keys/names and review source/destination full plans. Update the gate inventory, OIDC subjects, working-directory bindings and triggers through their owners. No automatic state transfer occurs.

## Existing State Handoff

Freeze both old/new owners and other hub writers. Back up states and record the exact Azure IDs, names, flags and DNS settings. Preserve approved existing names in the new inventory. Release only peerings/designated DNS links from the old backend **without destroying them**, import those child IDs to the new AzAPI resources, and compare both complete plans before unfreezing. New target addresses are `module.attachments[0].azapi_resource.hub_to_spoke["<key>"]`, reciprocal `spoke_to_hub["<key>"]`, and `dns_link["<key>/<zone-key>"]`.

Use an approved per-resource import/handoff plan with the pinned provider, including API version where required. A Terraform `moved` block does not cross backends; AzureRM-to-AzAPI is also a provider/resource-type handoff, not a silent address rename. Never import VNets, routes or zones into this state. If interrupted, keep the freeze, reconcile the one designated owner and Azure objects, and re-plan; do not restore whole snapshots into active backends or destroy/rebuild the hub. Retire peerings before moving/deleting a VNet and coordinate stale route/Panorama cleanup with their existing owners.
