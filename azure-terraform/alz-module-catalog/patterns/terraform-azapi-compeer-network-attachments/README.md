# Compeer Network Attachments

Platform-owned, multi-subscription hub/spoke attachment pattern. **Option A: both peering directions in one approved lifecycle + hub-boundary attachment state.** Uses AzAPI full parent resource IDs rather than an AzureRM provider alias for every workload subscription. The existing AzureRM single-pair patterns and their resource addresses are unchanged.

## Why This Fits Compeer

For Compeer's stated 50-60 applications, approximately 35-40 workload subscriptions and one shared hub, use two independent attachment roots: **`platform-network-peering-prod` and `platform-network-peering-nonprod`**. Production accepts only `prod`; non-production explicitly allowlists real environments such as `np1`, `np2` and `np3`. Those environments share permissions, pattern release and change approval in the non-production state. Split further only when lifecycle, ownership or risk requires it. Each root manages multiple stable-key attachments; a new application normally requires an inventory PR and scoped RBAC, not another workspace, provider alias or deployer identity.

This retains network-team control of both directions and matching gateway settings, keeps workload pipelines out of hub peering writes, avoids an AVNM management-service charge, and separates attachment changes from core hub foundation changes. Normal Azure peering/data-transfer and HCP operating costs still apply. This is Compeer's recommended operating model, **not a Microsoft mandate or universally superior design**. Split a boundary further for different network ownership, regulation, lifecycle or measured plan/recovery risk. Do not combine production and non-production in one state.

Tradeoffs: an environment plan covers every attachment in that state, and its identity has aggregate access to those approved VNets. A peering role scoped to the shared hub can affect other environments' peerings under that hub. OIDC separation and PR approval do not eliminate that RBAC risk. Security must explicitly accept it; otherwise use stronger hub/authorization boundaries or reconsider split ownership.

## Environment And Platform Flexibility

The same pattern supports hub-to-**platform** VNet and hub-to-**workload** VNet attachments. Approved environment labels are lowercase slugs up to 32 characters, including `shared`, `dev`, `perf`, `dr` or other approved names. No appcode, domain or workload naming context is required for the generic contract. Attachment names derive from the actual existing VNet names using the naming package's name-only helper; broader VNet-producer naming/governance standards are not weakened.

| Application | Environments That Exist | Attachment Membership |
| --- | --- | --- |
| accounts | prod only | prod root only |
| claims | dev, prod | dev and prod roots |
| loans | dev, perf, prod | dev, perf and prod roots |
| shared platform service | shared | approved shared platform root |

There is no mandatory four-environment matrix and no automatic Cartesian product. Each root owns only its declared VNet instances. The non-production root can contain several real environments; every entry retains its own actual environment and must match its producer and the approved allowlist. Use the [copy-once root template](../../implementations/platform-lz/templates/network-attachments/README.md) for another approved boundary, with its own committed values, backend, trigger, release pin and OIDC scope. Do not switch one backend between disjoint environment inventories using runtime tfvars, silently filter mismatched producers, or mislabel a prod VNet as nonprod/shared. Keep platform/workload permissions separate when their lifecycle or security ownership differs. This remains approved hub attachment, not unrestricted spoke-to-spoke mesh networking.

## Ownership

| Created Here | Required Existing Resources / Other Owners |
| --- | --- |
| Hub-to-spoke peering, one per approved attachment | Hub VNet/subnets: core connectivity state |
| Spoke-to-hub peering, one per approved attachment | Attached VNet/subnets: its platform or workload foundation state |
| Exact approved spoke DNS VNet links | Central private DNS zones and existing hub links: connectivity/DNS owner |
| Terraform contract guards only | Hub routes, spoke routes/associations, gateways, firewall/Panorama rules, private endpoints and DNS zone groups retain their existing owners |

**No VNet is shared between managed states.** This state reads VNet IDs/CIDRs and manages separate child resources. It never creates, imports or updates the parent VNets, tags, subnets or route tables. Current inline hub routes must not also be managed as standalone route resources here. Existing identity half-peerings remain a documented legacy exception until a reviewed handoff; never deploy a duplicate pair/link.

## Operation

1. Network reviewers approve the Git inventory: immutable attachment key, platform/workload classification, exact VNet ID/CIDRs, producer workspace/version, IPAM/change references, DNS zones and gateway/forwarding intent. Workload-v2 also supplies its existing naming context. HCP outputs are cross-checks, not authorization to expand that inventory.
2. Read only `tfe_outputs.nonsensitive_values`. The hub publishes contract `0.1.0`, its VNet ID and address spaces. Existing workloads may keep public `attachment_contract` v2.0.0 plus context (directly or under `spoke`). Generic platform/workload owners publish `network_attachment_contract` v3.0.0 with context, CIDRs and DNS intent through the [output-only producer adapter](producer/README.md).
3. Fail closed on mismatched tenant/environment/IDs/context/versions/DNS intent or live CIDRs. Check overlap within the batch, against the hub and against the supplied external IPAM ranges. Empty inventories make no producer or Azure reads and create no attachments.
4. Create all approved hub halves, then spoke halves, then DNS links. Transit defaults off; enabling it requires matching producer intent and explicit hub gateway readiness. Forwarded traffic is an independent paired setting. Peerings are not an atomic transaction.
5. Both peering resources use the same AzAPI provider-process `locks` key. This serializes their mutations within that provider process, including across map entries. These are **not Azure management/resource locks** and do not coordinate different HCP runs. DNS mutations are similarly serialized per zone within this process.
6. All workspaces writing the shared hub use one protected external deployment gate, including core/legacy exceptions. Preserve state and re-plan after a partial failure. Accept the network only after live reciprocal Connected status, DNS and inspected/forbidden flow tests.

Workload-v2 retains its strict **Key Vault and Blob DNS** contract. Generic-v3 permits other exact, approved existing private zones, such as Azure Files, only when Git inventory and the producer agree. It does not create zones, auto-register machines or discover arbitrary membership. IPv4/single-tenant only; no AVNM, subscription vending, compute, budgets or Azure management locks are introduced.

## Inputs

| Input | Type / Default | Meaning |
| --- | --- | --- |
| `tenant_id` | UUID string, required | Approved tenant, checked against authenticated provider and producer context |
| `environment` | approved slug, required | Fixed state boundary, e.g. `prod`, `nonprod`, `shared`; not a runtime selector |
| `allowed_environments` | set(string), `null` | Explicit actual producer labels permitted in this boundary; null preserves the old exact `environment` check |
| `hub` | object, required | `virtual_network_id`, `address_space`, producer `organization`/`workspace`; `contract_version="0.1.0"`, `gateway_ready=false` |
| `attachments` | typed map(object), `{}` | Network-approved members, keyed by immutable identity |
| `reserved_address_spaces` | set(IPv4 CIDR), `[]` | Complete relevant IPAM inventory outside this batch/hub; include on-premises, partners and other environments |

Each attachment requires `spoke_virtual_network_id` (the attached platform/workload VNet), `address_space`, `producer={organization,workspace,contract_version}`, `approval_reference` and `ipam_reference`. The existing `spoke_*` field/resource addresses are preserved for compatibility; they do not restrict the VNet to an application workload.

| Producer Contract | Classification / Metadata | Public Output |
| --- | --- | --- |
| v2.0.0 (default, unchanged) | `attachment_kind=workload`; required `naming_context={region,environment,domain,appcode}` | Existing `attachment_contract` plus context |
| v3.0.0 (generic) | Explicit matching `attachment_kind=platform` or `workload`; omit `naming_context` | `network_attachment_contract` from the VNet owner, including context and address spaces |

| Optional Attachment Field | Default | Use |
| --- | --- | --- |
| `environment` | v2 naming context, otherwise boundary | Actual environment expected from this producer; declare explicitly for grouped v3 entries. Never relabel it `nonprod` |
| `attachment_kind` | `workload` | `platform` or `workload`, independently cross-checked with the v3 producer; platform requires v3 |
| `gateway_transit` | `false` | Hub offers transit; spoke consumes it. No hub remote gateway or spoke transit offering |
| `allow_forwarded_traffic` | `true` | Approved hub NVA forwarding in both directions; routes/NSGs/firewall still govern flows |
| `private_dns_zone_ids` | `{}` | Exact central zone IDs matching producer intent; v2 keys are vault/blob, v3 supports other approved keys; no registration |
| `peering_names` | `null` | Explicit approved `hub_to_spoke`/`spoke_to_hub` names for new connections or preserving live names. The two roots use `peer-hub-to-<vnet>`/`peer-<vnet>-to-hub`; omitted names retain the existing canonical naming helper |
| `private_dns_link_names` | `{}` | Approved existing link-name overrides by zone key |
| `tags` | `{}` | Reviewed tags on owned DNS links; peering resources do not support tags |

Outputs: `contract_version="1.0.0"`, and `attachments`, keyed identically to the inventory, containing both child IDs, resolved names, classification/actual producer environment, hub/attached VNet references, observed peering states and DNS link IDs. Existing fields are retained. Observed state in the first-created half may be stale until refresh; it is not network acceptance.

## Examples And Roots

- [Production-shaped inventory](examples/production-batch.tfvars.example): two applications in different subscriptions, vault/blob links, no-zone variant, optional preservation of existing names, IPAM and adoption controls. Deliberately disabled with documentation placeholders, not Compeer-approved production values.
- Independent [production root](../../implementations/platform-lz/workspaces/platform-network-peering-prod/README.md) and [consolidated non-production root](../../implementations/platform-lz/workspaces/platform-network-peering-nonprod/README.md). Their committed `terraform.tfvars` contain complete disabled inventories with both explicit peering names, flags and DNS intent.
- [Shared platform VNet](examples/shared-platform.tfvars.example), [platform producer wiring](examples/platform-producer.tf.example), [different app environment counts](examples/application-environments/README.md) and [generic independent-root template](../../implementations/platform-lz/templates/network-attachments/README.md). Create only the needed boundary roots.
- [Shared-hub gate tooling and adoption runbook](../../implementations/platform-lz/network-attachments/README.md).

The two roots allow a populated pre-adoption inventory while `enabled=false`; no child resources or producer/Azure reads are created. Tests also exercise those actual inventories with mocked APIs. Each root adds provider `execution_subscription_id`, HCP dynamic-credential file mapping and explicit `deployment_controls` adoption approvals. An empty enabled inventory is valid after retiring its last attachment. **Do not set `enabled=false` to pause a live state**: that plans removal. Stop/lock runs operationally instead. Removing a map key, changing a VNet ID or renaming a key is a lifecycle change needing separate teardown/replacement review.

Repository roots use local sources for development/testing. This new pattern has **not** been published to Compeer's private registry. Before production deployment, package/publish the verified pattern and naming dependency, then replace each root's source with its actual HCP source and independently approved exact release version. Do not invent a registry version or use a mutable feature branch for deployment. Provider roots pin AzAPI `2.4.0`, TFE `0.82.0`, Terraform `>=1.11.4,<2.0.0`; retain/review the generated dependency lock files.

The new name-only helper is `modules/terraform-azurerm-compeer-naming/modules/network-attachments`; older published naming versions do not contain it. Publish an approved naming release with this helper and wire its verified registry submodule source/version before publishing the standalone batch package. Include the `producer` submodule in that package. Exporting only the pattern folder while leaving external relative naming paths unresolved will not initialize.

## OIDC And Least Privilege

One platform apply principal per environment/hub boundary, preferably a distinct read-only plan principal. Configure exact HCP organization/project/workspace/run-phase federation subjects; use the approved issuer/audience. HCP environment-category variables: `TFC_AZURE_PROVIDER_AUTH=true`, `TFC_AZURE_PLAN_CLIENT_ID`, `TFC_AZURE_APPLY_CLIENT_ID`. Terraform-category inputs: actual `tenant_id`, `execution_subscription_id` and approved inventory. HCP injects `tfc_azure_dynamic_credentials`; the root maps its default client/token file paths to AzAPI. Keep `allow_local_cli_auth=false` in HCP. Local CLI auth is an explicit test exception, not a production credential model.

The execution subscription is provider context only; full parent IDs select each target subscription. The same principal still requires grants on every approved target. Avoid Owner, broad Network Contributor, self-granted RBAC, parent VNet writes, route writes or application data access. See the [operation/scope matrix](../../implementations/platform-lz/network-attachments/README.md#permission-review). Assignment creation belongs to platform authorization/onboarding, not this pattern. Provider registration is performed by the existing platform owner, not by attachment runs.

Grant the output-read identity access to only approved public producer outputs. `tfe_outputs` uses the HCP outputs API; do not enable broad state download/sharing as a substitute for correct output permissions. Spoke private endpoint zone groups still need their own approved DNS-zone read/join permissions independently of these VNet links.

## Testing And Adoption

```bash
terraform init -backend=false
terraform validate
terraform test
# All new roots + retained single-pair regressions + operating-control tests:
bash ../../implementations/platform-lz/network-attachments/test.sh
```

Tests use real child configuration with mocked providers/producer outputs; no Azure or HCP deployment occurs. Coverage includes multi-subscription composition, existing workload-v2 compatibility, generic platform-v3, mixed non-production environments with strict producer matching, explicit reciprocal names, production exclusion, custom environment labels, one/two/three-environment app membership, canonical naming parity, strict mismatched-kind/environment rejection, approved transit, DNS variants, empty defaults, producer/live drift, IPAM overlap and operating controls. Mocks do not prove real authorization, ARM import/drift behavior, concurrency across agents, gateway readiness, DNS or Palo Alto flows. Complete the live pilot and recovery/migration checks in the runbook before broad rollout.

Existing states: freeze both owners and hub writers, record child IDs/settings, back up states, preserve exact names, release **only** the approved peering/DNS bindings without destroy, and import those IDs into the new backend. Review old/new full plans under the freeze before enabling runs. `moved` blocks cannot transfer resources between backends or silently change AzureRM resources into AzAPI resources. Never move VNets/routes, leave two active owners or perform an unreviewed mass replacement. New roots are disabled; this change performs no live migration.

## Design Basis

- [Microsoft peering lifecycle and permissions](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-manage-peering).
- [Microsoft AzAPI peering resource schema](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/2024-05-01/virtualnetworks/virtualnetworkpeerings): full parent VNet ID and reciprocal properties.
- [AzAPI 2.4 resource/mutex contract](https://github.com/Azure/terraform-provider-azapi/blob/v2.4.0/docs/resources/resource.md) and [OIDC/provider file-path inputs](https://github.com/Azure/terraform-provider-azapi/blob/v2.4.0/docs/index.md).
- [HashiCorp provider association rules](https://developer.hashicorp.com/terraform/language/modules/develop/providers): provider bindings are static; do not attempt dynamic AzureRM aliases in `for_each`.
- [HCP dynamic Azure credentials](https://developer.hashicorp.com/terraform/cloud-docs/dynamic-provider-credentials/azure-configuration) and [Microsoft exclusive deployment gates](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/approvals?view=azure-devops).
