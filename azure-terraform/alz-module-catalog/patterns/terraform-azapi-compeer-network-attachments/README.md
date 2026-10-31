# Compeer Network Attachments

Platform-owned Terraform pattern for attaching existing workload and platform VNets to an existing hub. Each approved attachment manages **both peering directions and its explicitly requested private DNS VNet links** in one attachment state.

The pattern uses AzAPI with full parent resource IDs to manage attachments across subscriptions without subscription-specific AzureRM provider aliases. It does not manage the parent VNets or replace their foundation states. Existing AzureRM patterns and resource addresses remain unchanged.

## Benefits Over The Legacy Pattern

**This is the recommended pattern for new Compeer attachments.** Its advantage is simpler multi-subscription onboarding and batch ownership, not a different or inherently more secure Azure peering service.

| Area | Existing AzureRM Composition | New AzAPI Attachment Pattern | Benefit For Compeer |
| --- | --- | --- | --- |
| Cross-subscription targets | Statically bound hub, spoke and DNS providers; additional subscription bindings may require more configuration | One AzAPI configuration targets full approved VNet and DNS-zone IDs | Avoids provider-alias growth as workload subscriptions are added |
| Onboarding | Wire each pair into the composition and its applicable provider configuration | Add a stable-key entry to the reviewed attachment inventory and provision its scoped permissions | Normally no new workspace, deployer identity or provider alias per application |
| Deployment interface | `network-peering` adapter -> `hub-spoke-peering` pattern -> base peering and DNS-link modules | One batch pattern -> AzAPI child resources, plus an internal naming helper | Fewer module interfaces and releases to coordinate |
| Validation | Pair-level settings and producer contracts | Inventory, producer and IPAM contracts, plus batch-wide duplicate and overlap checks | Checks relationships between attachments before deployment |
| Packaging | Composition depends on several modules | Naming helper is bundled and versioned with the attachment pattern | Simpler independent publishing and consumption |

The legacy modules can also manage multiple pairs in one workspace; they do **not** inherently require a workspace per spoke. The distinguishing constraint is Terraform's static provider binding across subscriptions. Batch validation could also be added to a legacy composition, but it is already built into this pattern.

Tradeoffs remain: the apply identity has aggregate permissions across approved targets, one plan covers all attachments in its state, and the team maintains ARM payloads and API versions. Process-local mutexes do not replace the shared-hub deployment gate. Existing working attachments need not migrate solely to standardize the provider.

This is Compeer's preferred Terraform-only approach without AVNM, **not a universal Microsoft requirement**. Both approaches create the same Azure peering and DNS-link resource types. The architectural benefit comes from the inventory, ownership and provider design, not simply from bypassing the base module.

## Why This Fits Compeer

For Compeer's stated 50-60 applications, approximately 35-40 workload subscriptions and one shared hub, use two independent attachment roots:

| Root | Permitted Producer Environments | State Boundary |
| --- | --- | --- |
| `platform-network-peering-prod` | `prod` | Production attachments |
| `platform-network-peering-nonprod` | `dev`, `test`, `uat`, `sandbox` | Approved non-production attachments sharing permissions, pattern release and change approval |

`sandbox` is canonical for the current workload-v2 naming/tagging stack. `sbx` is an explicitly approved alternative only with matching producer support, including generic-v3. Labels are never silently rewritten. Legacy `np1`/`np2`/`np3` remain supported by reusable patterns for existing landing zones, but are not new-root defaults.

This retains network-team control of both directions and matching gateway settings, keeps workload pipelines out of hub peering writes, and separates attachment changes from core hub foundation changes. No AVNM service is introduced; normal Azure peering/data-transfer and HCP operating costs still apply. Split a boundary further only for different network ownership, regulation, lifecycle or measured plan/recovery risk. Do not combine production and non-production in one state.

**Shared-hub permission boundary:** a peering role scoped to the hub VNet can affect other environments' peerings under that hub. Separate states, OIDC identities and PR approvals do not eliminate that RBAC exposure. Security must accept it; otherwise use stronger hub/authorization boundaries or reconsider split ownership.

## Environment And Platform Flexibility

The same pattern supports hub-to-**platform** and hub-to-**workload** attachments. Approved environment labels are lowercase slugs up to 32 characters. The generic contract does not require an appcode, domain or workload naming context; default attachment names derive from existing VNet names through the bundled helper. Producer naming/governance standards remain unchanged.

| Application | Environments That Exist | Attachment Membership |
| --- | --- | --- |
| accounts | prod only | prod root only |
| claims | dev, prod | dev entry in nonprod; prod entry in prod |
| loans | dev, test, prod | dev/test entries in nonprod; prod entry in prod |
| shared platform service | shared | explicitly approved platform boundary |

There is no mandatory environment matrix or automatic Cartesian product. Each root owns only its declared VNet instances, and every entry's actual environment must match its producer and the root's allowlist. Other labels, such as `perf`, `dr` or `shared`, require explicit boundary approval and configuration.

Use the [root template](../../implementations/platform-lz/templates/network-attachments/README.md) when a separate boundary is justified, with its own committed values, backend, trigger, release pin and OIDC scope. Never switch one backend between disjoint inventories using runtime tfvars or mislabel a production VNet. Keep platform/workload permissions separate when security ownership or lifecycle differs. This pattern provides approved hub attachments, not an unrestricted spoke-to-spoke mesh.

## Ownership

| Created Here | Required Existing Resources / Other Owners |
| --- | --- |
| Hub-to-spoke peering, one per approved attachment | Hub VNet/subnets: core connectivity state |
| Spoke-to-hub peering, one per approved attachment | Attached VNet/subnets: its platform or workload foundation state |
| Exact approved spoke DNS VNet links | Central private DNS zones and existing hub links: connectivity/DNS owner |
| Terraform contract guards only | Hub routes, spoke routes/associations, gateways, firewall/Panorama rules, private endpoints and DNS zone groups retain their existing owners |

**Each VNet has one managed state owner.** Attachment state reads VNet IDs/CIDRs and manages separate child resources. It never creates, imports or updates parent VNets, their tags, subnets or route tables. Do not duplicate inline hub routes as standalone resources here. Existing identity half-peerings remain a documented legacy exception until a reviewed handoff; never deploy a duplicate pair or DNS link.

## Operation

1. Network reviewers approve the Git inventory: immutable attachment key, classification, exact VNet ID/CIDRs, producer workspace/version, IPAM/change references, DNS zones and gateway/forwarding intent. Workload-v2 also supplies naming context. Producer outputs cross-check the inventory; they do not expand it. Azure RBAC authorizes the actual deployment.
2. Read only `tfe_outputs.nonsensitive_values`. The hub publishes contract `0.1.0`, its VNet ID and address spaces. Existing workloads may keep public `attachment_contract` v2.0.0 plus context (directly or under `spoke`). Generic platform/workload owners publish `network_attachment_contract` v3.0.0 with context, CIDRs and DNS intent through the [output-only producer adapter](producer/README.md).
3. Fail closed on mismatched tenant/environment/IDs/context/versions/DNS intent or live CIDRs. Check overlap within the batch, against the hub and against supplied external IPAM ranges. These are not automatic estate-wide checks: supply the relevant external ranges. Approval/IPAM references are evidence pointers, not live ticket or IPAM-system verification. Empty inventories make no producer or Azure reads and create no attachments.
4. Create all approved hub halves, then spoke halves, then DNS links. Transit defaults off; enabling it requires matching producer intent and explicit hub gateway readiness. Forwarded traffic is an independent paired setting. Peerings are not an atomic transaction.
5. Both peering resources use the same AzAPI provider-process `locks` key. This serializes their mutations within that provider process, including across map entries. These are **not Azure management/resource locks** and do not coordinate different HCP runs. DNS mutations are similarly serialized per zone within this process.
6. All workspaces writing the shared hub use one protected external deployment gate, including core/legacy exceptions. Preserve state and re-plan after a partial failure. Accept the network only after live reciprocal Connected status, DNS and inspected/forbidden flow tests.

Workload-v2 retains its strict **Key Vault and Blob DNS** contract. Generic-v3 permits other approved existing private zones, such as Azure Files, only when inventory and producer agree. This pattern is IPv4/single-tenant only. It does not create zones, auto-register machines, discover arbitrary membership, vend subscriptions, provision compute, create budgets or add Azure management locks.

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
| `private_dns_zone_ids` | `{}` | Exact central zone IDs matching producer intent; v2 keys are `key_vault` and `storage_blob`; v3 supports other approved keys. Empty means no links only when the producer also requests none |
| `peering_names` | `null` | Explicit approved `hub_to_spoke`/`spoke_to_hub` names for new connections or preserving live names. The two roots use `peer-hub-to-<vnet>`/`peer-<vnet>-to-hub`; omitted names retain the existing canonical naming helper |
| `private_dns_link_names` | `{}` | Optional approved link-name overrides by a key present in `private_dns_zone_ids`; omitted names default to `<spoke-vnet-name>-link` |
| `tags` | `{}` | Reviewed tags on owned DNS links; peering resources do not support tags |

## Outputs

`contract_version="1.0.0"` and `attachments`, keyed identically to the inventory. Each attachment exposes both peering IDs, resolved names, classification/actual producer environment, hub/attached VNet references, observed peering states and DNS link IDs. Existing fields are retained.

Observed state in the first-created half may be stale until refresh. Outputs do not replace live connectivity acceptance.

## Examples And Roots

- [Production-shaped inventory](examples/production-batch.tfvars.example): two applications in different subscriptions, vault/blob links, no-zone variant, optional preservation of existing names, IPAM and adoption controls. Deliberately disabled with documentation placeholders, not Compeer-approved production values.
- Independent [production root](../../implementations/platform-lz/workspaces/platform-network-peering-prod/README.md) and [consolidated non-production root](../../implementations/platform-lz/workspaces/platform-network-peering-nonprod/README.md). Their committed `terraform.tfvars` contain complete disabled inventories with both explicit peering names, flags and DNS intent.
- [Shared platform VNet](examples/shared-platform.tfvars.example), [platform producer wiring](examples/platform-producer.tf.example), [different app environment counts](examples/application-environments/README.md) and [generic independent-root template](../../implementations/platform-lz/templates/network-attachments/README.md). Create only the needed boundary roots.
- [Phase 2 external identity](../../implementations/platform-lz/workspaces/platform-identity-external/README.md#central-attachment-handoff): the real VNet owner can publish v3 metadata; its complete example entry belongs in the production batch inventory. Cross-root mock tests check producer/consumer compatibility without moving VNet ownership.
- [Shared-hub gate tooling and adoption runbook](../../implementations/platform-lz/network-attachments/README.md).

The two roots allow a populated pre-adoption inventory while `enabled=false`; no child resources or producer/Azure reads are created. Tests also exercise those actual inventories with mocked APIs. Each root adds provider `execution_subscription_id`, HCP dynamic-credential file mapping and explicit `deployment_controls` adoption approvals. An empty enabled inventory is valid after retiring its last attachment. **Do not set `enabled=false` to pause a live state**: that plans removal. Stop/lock runs operationally instead. Removing a map key, changing a VNet ID or renaming a key is a lifecycle change needing separate teardown/replacement review.

### Release And Packaging

Repository roots use local sources for development/testing. This pattern has **not** been published to Compeer's private registry. Before production deployment, publish the verified package and replace each root's source with the actual HCP source and independently approved exact version. Do not invent a registry release or deploy from a mutable feature branch.

| Dependency | Pattern Requirement | Implementation Roots |
| --- | --- | --- |
| Terraform | `>= 1.11.4, < 2.0.0` | Same supported range |
| AzAPI | `~> 2.4.0` | Exact `2.4.0` |
| TFE | `>= 0.80.0, < 1.0.0` | Exact `0.82.0` |

Retain and review generated dependency lock files.

Include `modules/attachment-names` and `producer` in the published package. The naming helper contains no providers or managed resources and requires no separate Compeer naming-module release. Its formulas preserve the canonical `vnet_peering_names` and `private_dns_link_names`. The helper's parity test references the central naming module and is **monorepo-only**; exclude or adapt that test for a standalone exported test suite. Production execution has no naming dependency outside this pattern.

## OIDC And Least Privilege

Use one platform apply principal per attachment boundary, preferably with a distinct read-only plan principal. Configure exact HCP organization/project/workspace/run-phase federation subjects and the approved issuer/audience.

| Workspace Setting | Category | Purpose |
| --- | --- | --- |
| `TFC_AZURE_PROVIDER_AUTH=true` | Environment | Enable HCP Azure dynamic credentials |
| `TFC_AZURE_PLAN_CLIENT_ID` | Environment | Approved plan identity |
| `TFC_AZURE_APPLY_CLIENT_ID` | Environment | Approved apply identity |
| `tenant_id`, `execution_subscription_id`, inventory and deployment controls | Terraform | Reviewed root inputs; use HCL for structured values |

HCP injects `tfc_azure_dynamic_credentials`; the root maps its default client/token file paths to AzAPI. Keep `allow_local_cli_auth=false` in HCP. Local CLI authentication is an explicit test exception, not the production credential model.

The execution subscription is provider context only; full parent IDs select each target subscription. The same principal still requires grants on every approved target. Avoid Owner, broad Network Contributor, self-granted RBAC, parent VNet writes, route writes or application data access. See the [operation/scope matrix](../../implementations/platform-lz/network-attachments/README.md#permission-review). Assignment creation belongs to platform authorization/onboarding, not this pattern. Provider registration is performed by the existing platform owner, not by attachment runs.

Grant the output-read identity access to only approved public producer outputs. `tfe_outputs` uses the HCP outputs API; do not enable broad state download/sharing as a substitute for correct output permissions. Spoke private endpoint zone groups still need their own approved DNS-zone read/join permissions independently of these VNet links.

## Testing

```bash
terraform init -backend=false
terraform validate
terraform test
# All new roots + retained single-pair regressions + operating-control tests:
bash ../../implementations/platform-lz/network-attachments/test.sh
```

Tests use real child configuration with mocked providers/producer outputs; no Azure or HCP deployment occurs. Coverage includes multi-subscription composition, v2/v3 compatibility, mixed/custom environments, application membership variants, reciprocal names, naming parity, transit and DNS variants, empty defaults, producer/live-CIDR mismatches, IPAM overlap and operating controls.

Mocks do not prove real authorization, ARM migration/drift behavior, cross-agent concurrency, gateway readiness, DNS or Palo Alto flows. Complete the live pilot and recovery checks in the runbook before broad rollout.

## Existing-State Adoption

Moving the pure naming helper inside this pattern does not itself require Azure resource imports or a provider migration. Preserve its outputs and confirm that the plan leaves existing resource names unchanged.

For existing AzureRM-managed attachments:

1. Decide whether migration is justified; working legacy states can remain in place.
2. Freeze the existing owners and shared-hub writers. Record child IDs/settings, back up states and preserve exact resource names.
3. For a **cross-backend handoff**, release only the approved peering/DNS bindings without destroying Azure resources, then import them into the target state under the freeze. `moved` blocks alone cannot transfer ownership between backends.
4. For a **same-state provider conversion**, AzAPI supports AzureRM-to-AzAPI state moves from version 2.1.0, including the pinned 2.4.0 release. A reviewed `moved` block may be appropriate; validate the exact source resource types, provider versions and resulting plan before applying.
5. Review full source/target plans before resuming writers. Require no unintended destroy/recreate actions and complete live connectivity acceptance.

Never move VNets/routes into attachment state, leave two active owners or perform an unreviewed mass replacement. The supplied roots are disabled examples; this code performs no live migration automatically. Follow the [adoption runbook](../../implementations/platform-lz/network-attachments/README.md) for the controlled handoff.

## Design Basis

- [Microsoft peering lifecycle and permissions](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-manage-peering).
- [Microsoft AzAPI peering resource schema](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/2024-05-01/virtualnetworks/virtualnetworkpeerings): full parent VNet ID and reciprocal properties.
- [AzAPI 2.4 resource/mutex contract](https://github.com/Azure/terraform-provider-azapi/blob/v2.4.0/docs/resources/resource.md) and [OIDC/provider file-path inputs](https://github.com/Azure/terraform-provider-azapi/blob/v2.4.0/docs/index.md).
- [HashiCorp provider association rules](https://developer.hashicorp.com/terraform/language/modules/develop/providers): provider bindings are static; do not attempt dynamic AzureRM aliases in `for_each`.
- [Microsoft AzureRM/AzAPI provider selection](https://learn.microsoft.com/en-us/azure/developer/terraform/provider-selection-azurerm-vs-azapi): AzAPI is not inherently superior; AzureRM remains the general default.
- [AzAPI state-move release history](https://github.com/Azure/terraform-provider-azapi/blob/v2.4.0/CHANGELOG.md) and [HashiCorp cross-type state moves](https://developer.hashicorp.com/terraform/plugin/framework/resources/state-move): provider-supported conversions differ from cross-backend ownership handoffs.
- [HCP dynamic Azure credentials](https://developer.hashicorp.com/terraform/cloud-docs/dynamic-provider-credentials/azure-configuration) and [Microsoft exclusive deployment gates](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/approvals?view=azure-devops).
