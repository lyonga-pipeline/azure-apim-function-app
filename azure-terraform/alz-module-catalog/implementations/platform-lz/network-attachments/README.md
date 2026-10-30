# Network Attachment Operations

Implementation of [Option A](../../../patterns/terraform-azapi-compeer-network-attachments/README.md): central ownership of both directions, grouped by approved environment/platform lifecycle and hub boundary. The four supplied roots are examples, not a mandatory deployment matrix or name restriction. Use the [copy-once independent-root template](../templates/network-attachments/README.md) for shared platform or other approved environments; create only needed roots. Existing single-pair and identity states remain untouched until a reviewed handoff.

## Adoption Checklist

1. Confirm the actual application/platform environment boundaries and approve the shared-hub RBAC residual risk. Record one owner per child resource and complete external IPAM ranges. Existing workloads may retain producer-v2; generic platform/workload VNet owners publish producer-v3. Provision VNets, routes, firewall/DNS path and public outputs through their existing owners first. Never require absent app environments or relabel a platform VNet to fit a consumer.
2. Publish/pin the tested new batch pattern and its naming dependency for Compeer deployment. Set each HCP root's independent working directory, state, exact release, main-branch trigger path, tenant and execution subscription. New roots/examples are disabled and contain placeholders. Never repoint an applied old workspace here.
3. Grant exact plan/apply OIDC subjects and least-privilege resource-scoped roles. Configure the injected credential file mapping shown in each root. Grant narrow HCP public-output reads, separately from Azure authentication. Test allowed/denied operations with the actual identities.
4. Configure the protected common-hub gate below **before** setting adoption controls true. Run local/mock CI, review the complete environment plan, and pilot a small approved attachment before adding the estate. Test refresh/no-op, a harmless flag change, partial-apply recovery, import and teardown in an isolated approved pilot. Local mocks do not certify those ARM behaviors.
5. Verify both live peerings Connected/Succeeded and correct DNS links, then test actual private endpoint resolution, representative Palo Alto-inspected flows, symmetric return routes and rejected flows. Record evidence and change/operations owners. A successful apply is not application connectivity acceptance.

## Shared Hub Gate

The repository includes [an ADO template](../../../../../.azuredevops/templates/network-attachments.yml) and [HCP run controller](run_under_hub_gate.py). These are provided tooling, not a claim that Compeer's external controls are configured.

- Create the exact protected ADO Environment `compeer-shared-hub-network-writes`; its administrator configures **Exclusive Lock**, sequential behavior, network/security approvals, allowed main-branch pipelines and protected template/inventory reviewers. Microsoft configures checks outside YAML; `lockBehavior: sequential` alone does not create the check.
- Maintain a reviewed copy of [hub-gate.json.example](hub-gate.json.example) with actual organization/repository identifier, HCP workspace names and directories. Include **every existing** writer to that hub: whichever application/platform attachment roots are actually used, core connectivity, legacy identity and exceptions. The controller accepts approved workspace names dynamically from this list; it does not require np1/np2/np3/prod or a workspace for each application. Do not leave nonexistent example workspaces in the live gate list or omit an actual writer.
- In HCP disable auto-apply for all these writers, require plan review/mandatory policy, and restrict direct non-speculative queue/apply paths to the protected network process. VCS may generate speculative plans, but must not independently create/confirm mutating runs outside the gate. Arrange configuration-version creation without an automatically queued unfinished run; reconcile any pre-existing queued/planned run under change control before invoking the controller. A run trigger is not a mutex. Validate the actual HCP permissions/run-task controls for the organization's tier; YAML and a Terraform boolean cannot prevent a privileged UI/API bypass.
- Invoke the template from the reviewed main-branch pipeline with `workspace`, `configurationVersion` and `gateInventory`. Store `HCP_NETWORK_GATE_TOKEN` in the protected secret store with only required workspace/output/run permissions. The agent needs Python 3; Azure credentials remain in HCP's environment-specific OIDC context.
- Inside the protected deployment job, the controller checks every listed writer for unfinished runs, rejects auto-apply, checks the selected working directory/current non-speculative configuration and exact main-branch commit/repository, then queues a fresh non-auto-apply, non-destroy run. Network reviewers inspect and confirm its full plan in HCP while the gate job waits. The controller never overrides policy or applies automatically.
- AzAPI's common `locks` key serializes all peerings **inside one provider process**. It is not an Azure management lock. The external gate serializes separate workspaces/agents. Core writers must also serialize their own hub networking mutations; a per-pair dependency does not serialize a batch.
- On timeout/agent loss, an HCP run can remain active. The next gated controller refuses to queue another hub writer until that run is reconciled. Do not force-cancel or release an incident freeze blindly; inspect Azure's in-flight operations/partial state. Complete planned route/Panorama coordination and live acceptance as part of the change. An external permission or queue path that bypasses this process remains a deployment blocker.

`COMPEER_HUB_GATE_HELD=true` is a job assertion, not a security boundary. Only the protected ADO resource, restrictive HCP access and coverage of **all** hub writers establish the cross-workspace gate. If Compeer cannot enforce those controls, do not enable four independent mutating hub pipelines; first establish a single controlled deployment queue or an equivalent enforced HCP run-task coordinator.

## Permission Review

Security owns the final tested role definitions and assignments. Suggested operation/scope matrix, **not automatic role grants**:

| Principal / Resource Scope | Required Operations To Review |
| --- | --- |
| Apply: exact hub and approved spoke VNets | `Microsoft.Network/virtualNetworks/read`, `virtualNetworkPeerings/read`, `virtualNetworkPeerings/write`, `virtualNetworkPeerings/delete`, `peer/action` under `Microsoft.Network/virtualNetworks` |
| Apply: exact approved central zones | `Microsoft.Network/privateDnsZones/read`, `virtualNetworkLinks/read`, `virtualNetworkLinks/write`, `virtualNetworkLinks/delete`, `join/action` under `Microsoft.Network/privateDnsZones` where linked authorization requires it |
| Apply: referenced VNets for DNS linking | Review/test `Microsoft.Network/virtualNetworks/join/action` alongside VNet read and linked-resource permissions |
| Plan: same approved discovery scopes | Required parent/peering/DNS-link reads; no lifecycle writes or role assignment permission |
| Workload endpoint identity, separately | Approved central-zone read/join for endpoint DNS zone groups, without hub attachment write rights |

Expand abbreviated operation names under the shown resource namespace when authoring a role; check [Microsoft's operation list](https://learn.microsoft.com/en-us/azure/role-based-access-control/permissions/networking). Validate any additional ARM-required discovery rights in the pilot, rather than granting broad Contributor for convenience. Assignment scopes are exact resource IDs; no subscription-wide role is required simply because target IDs span subscriptions. Authorization/onboarding manages grants; attachment runs cannot elevate themselves.

Hub-scoped lifecycle permissions cover **all child peerings**, not just this environment's map entries. Environment identities reduce credential/state coupling but do not enforce per-child isolation on a shared hub. Cross-environment inventory uniqueness and current IPAM are network review responsibilities in addition to the batch guards. Gate inventory coverage must be reviewed when adding any new hub writer.

## Testing And Live Acceptance

```bash
bash implementations/platform-lz/network-attachments/test.sh
```

This runs batch tests (v2 and v3), four example environment compositions, the generic platform template, name-only/canonical naming parity, retained single-pair regressions and operating-control/ownership unit tests. These test fixtures do not require deployment of every example root. Providers and producer outputs are mocked; no Azure write, HCP queue or live role change occurs.

After an approved pilot apply, use a read-authorized identity:

```bash
# From the correct attached environment root:
terraform output -json attachments > /tmp/approved-attachments.json
python3 ../../network-attachments/check_live.py /tmp/approved-attachments.json
```

The checker performs GETs only and requires both peerings Connected/Succeeded with correct remote IDs, plus exact spoke DNS links with registration off. Run actual DNS/endpoint/network-security tests from a spoke test host separately; these cannot be proved by the control-plane checker. Re-check on a scheduled basis for stale Initiated/Disconnected or out-of-inventory peerings using the approved estate inventory; this script checks declared members, not discovery of unauthorized ones.

## Existing State Handoff

Freeze both old/new owners and other hub writers. Back up states and record the exact Azure IDs, names, flags and DNS settings. Preserve approved existing names in the new inventory. Release only peerings/designated DNS links from the old backend **without destroying them**, import those child IDs to the new AzAPI resources, and compare both complete plans before unfreezing. New target addresses are `module.attachments[0].azapi_resource.hub_to_spoke["<key>"]`, reciprocal `spoke_to_hub["<key>"]`, and `dns_link["<key>/<zone-key>"]`.

Use an approved per-resource import/handoff plan with the pinned provider, including API version where required. A Terraform `moved` block does not cross backends; AzureRM-to-AzAPI is also a provider/resource-type handoff, not a silent address rename. Never import VNets, routes or zones into this state. If interrupted, keep the freeze, reconcile the one designated owner and Azure objects, and re-plan; do not restore whole snapshots into active backends or destroy/rebuild the hub. Retire peerings before moving/deleting a VNet and coordinate stale route/Panorama cleanup with their existing owners.
