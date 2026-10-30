# Compeer Network Attachment Standard

Decision updated: 2026-10-30. Scope: Azure VNet hub/spoke attachments, their Terraform state boundaries, authorization and operating controls. This supersedes the earlier default of one attachment workspace per application. It does not enable subscription vending or introduce Phase 3 services.

**Default: one platform-owned attachment workspace per actual environment/platform lifecycle and hub/network security boundary.** Each owns both peering directions and approved DNS links for multiple declared platform/workload VNets. Hub and attached VNets remain exclusively in their foundation states. np1/np2/np3/prod are examples, not required names, counts or an application environment matrix.

**Implementation status:** [the AzAPI batch pattern](../../patterns/terraform-azapi-compeer-network-attachments/README.md), four example roots and a [copy-once generic root template](templates/network-attachments/README.md) support workload-v2 and generic platform/workload-v3 contracts, approved custom environment labels, full subscription IDs and strict public-producer/live-CIDR checks. [Gate tooling and adoption](network-attachments/README.md) are included. External gate controls, OIDC/RBAC, registry publication and live pilot/migration remain required, not configured tenant settings. Existing single-pair APIs/addresses remain unchanged; never silently repoint deployed states.

## Workspace Boundary

| Boundary | Standard |
| --- | --- |
| Deployment grouping | One environment + one approved hub/network boundary + one owning network team. Use a separate root directory, state, independently pinned release and main-branch trigger path for each group. |
| Initial examples | np1/np2/np3/prod roots are optional examples. Create only actual needed boundaries; copy the generic template for shared platform, dev, perf, dr or another approved label. They are not runtime selectors. |
| Application environment counts | One, two, three or more actual environments are supported independently. Each root lists only its real VNet instances; there is no mandatory Cartesian product and no silent membership filtering. |
| Platform VNets | Use generic producer-v3 with `attachment_kind=platform` and the actual environment. No fake appcode/domain is required. Separate platform permissions/lifecycle when justified; never relabel prod as shared or duplicate an existing identity pair. |
| Multiple hubs or security boundaries | Add a meaningful hub/region/boundary suffix and separate state where permissions, approvals, lifecycle or risk differ. Four workspaces are an initial assumption, not an enterprise-wide limit. |
| Shared physical hub | Environment workspaces may target the same hub VNet. They still require a common hub deployment gate; environment separation does not remove that shared dependency. |
| Dedicated exceptions | Permit per-spoke attachment workspaces for regulatory separation, separate network ownership, independent release/recovery requirements or unacceptable aggregate permission/plan scope. Record the justification and resource owner. |

Twenty independently deployed application spokes in each of four environments can use four attachment workspaces instead of eighty, assuming one compatible hub/network boundary per environment. Each workspace still refreshes/plans its entire inventory. Workspace/identity overhead falls, but aggregate state, permissions and recovery impact grow. Split based on measured plan time, queue contention, ownership and risk, not an arbitrary spoke count. Do not consolidate into one global multi-environment state.

## Exclusive Resource Ownership

| Azure resource | Sole Terraform or operational owner |
| --- | --- |
| Hub VNet, hub subnets, route tables and all currently inline hub routes | Existing core connectivity state |
| Spoke VNet, spoke subnets, route tables, routes and associations | Its existing spoke/foundation state |
| Both directional peerings for each approved new attachment | Its assigned environment/hub attachment state |
| Central private DNS zones and existing hub DNS links | Existing connectivity/DNS state |
| Approved spoke DNS VNet links | Assigned attachment state, unless an explicitly retained DNS owner already manages them |
| Private endpoints and their DNS zone groups | Workload/private-endpoint state; zone-group-managed records must not also be managed as separate records |
| Palo Alto guest routes, security policy and NAT | Network team through approved Panorama change control |

A VNet resource ID must have one managed resource binding across all backends. Consumers may read the ID and manage distinct peering resources referencing it; this does not make them VNet owners. Never create/import the hub or spoke VNet into attachment state, or manage its address space, tags or subnets there. Reading outputs is a cross-state dependency, not duplicate resource ownership. If a security policy also prohibits managing child resources from another state, this model needs an explicit exception or a different design.

The existing identity attachment is a **legacy platform-tier exception**: connectivity derives its hub-side `additional_vnet_peerings.identity`, and directory-services derives the reciprocal `hub_connection`. Keep those resources at their existing addresses until an approved handoff transfers both to one designated attachment state. Do not deploy a second copy or silently disable a live half-peering.

## Approved Inventory And Contract

Maintain a network-approved Git inventory as the authorization source of truth. The new batch pattern's typed `attachments` map, keyed by immutable logical attachment keys, represents the environment's approved attachments. Do not use list indices, observed output order or display names as resource identity. This input belongs to the new environment roots, not the retained single-pair root.

Each entry records the expected tenant/environment, hub and spoke VNet IDs, subscription IDs, producer organization/workspace, supported contract version, IPAM reservation/CIDRs, approved DNS zone IDs/link intent, gateway/forwarding settings, existing-name overrides where needed, and approval/ownership reference. The root fixes the environment and hub boundary rather than trusting those values from application outputs.

Read only versioned non-sensitive producer outputs. Cross-check them against the approved inventory and live VNet address spaces before apply; fail closed on mismatched IDs, subscriptions, environment, CIDRs, DNS zones, unsupported versions, duplicate VNet pairs or competing owners. Application output changes are requests, not permission to attach a new VNet or enable gateway transit. A VNet rebuild/new ID requires renewed approval. Never use unrestricted workspace discovery, sensitive-output fallback or broad state-sharing to authorize membership.

Adding an attachment is an inventory PR, not another workspace or deployer identity. Adding a subscription still requires scoped RBAC and producer output access; the new full-ID AzAPI pattern does not require another provider alias. Do not promise that authorization/onboarding is tfvars-only.

## Cross Subscription Implementation

AzureRM provider configurations select a subscription, and Terraform module provider references are static. A single `for_each` cannot select `azurerm.spoke[each.value.subscription_key]`, create provider aliases dynamically, or switch one provider's subscription per attachment. Provider aliases do not create separate identities automatically.

For Compeer's approximately 35-40 workload subscriptions and one shared hub, the batch pattern uses one AzAPI provider and full parent VNet/zone IDs for both directions and approved links. This avoids alias/module growth as subscriptions are onboarded. Provider context is not authorization: exact target grants remain required. Single tenant/IPv4 only. Existing workload contract v2 retains vault/blob DNS guards; generic v3 supports platform/workload classification and other exact approved zones. Both match the independently reviewed inventory and actual environment; v3 also checks producer CIDRs. Name-only child naming uses existing VNet names, not workload metadata or an environment catalogue.

Publish the tested batch composition with independently pinned HCP releases before deployment. The repository's relative module sources are monorepo development composition, not independent registry pins. Preserve the single-pair API for existing callers; use reviewed provider/resource-type and backend imports for adoption rather than rewriting live state accidentally.

The new pattern's mock/composition tests cover parity of reciprocal flags, naming, contracts and resource scope; actual OIDC, ARM import/drift, recovery and cross-agent gate enforcement require the live pilot. Azure Virtual Network Manager remains a future option for genuinely large policy-driven estates; it changes ownership and requires routing/security/cost/migration review. It is not enabled here. Never let AVNM and Terraform both own the same connections or enable direct spoke connectivity that bypasses inspection. No AVNM management-service charge is introduced; Azure peering/data-transfer and HCP costs still apply.

## OIDC And Permission Review

Use a distinct platform attachment apply principal per environment/hub security boundary, not per application and not the broadly privileged core-connectivity or application principal. Prefer a separate read-only plan principal. There is no fixed requirement for exactly four identities: four apply principals plus four plan principals is an illustrative four-boundary model; approved exceptions need their own boundaries.

Federated credentials must match the exact approved HCP issuer, organization, project, workspace and plan/apply phase, with the approved token audience (normally `api://AzureADTokenExchange`). Do not use wildcard project/workspace trust to reduce identity setup. Configure `TFC_AZURE_PROVIDER_AUTH=true` and the approved `TFC_AZURE_PLAN_CLIENT_ID` / `TFC_AZURE_APPLY_CLIENT_ID` as HCP environment-category variables. Set tenant and provider subscription inputs as Terraform-category variables. Validate the default/tagged dynamic-credential mapping for every provider alias; merely defining aliases or setting a workspace client ID is not live proof of successful authentication. Keep secrets/tokens out of inventory/tfvars. HCP output-read authentication remains separate from Azure OIDC.

Security must approve an operation/scope matrix before granting permissions. The attachment role considers VNet read, peering read/write/delete and linked-VNet `Microsoft.Network/virtualNetworks/peer/action` on the approved hub and spoke VNets. DNS permissions cover required reads and VNet-link lifecycle/join operations on the approved existing zones and referenced VNets. Test actual linked-resource authorization; do not reduce the role to write alone. The plan principal needs the required discovery/refresh reads, not apply writes.

Assign narrowly at exact approved resources; do not give subscription/MG-wide Owner, Network Contributor, role-assignment write, VNet parent write/delete, route-table modification or application data access merely for attachment. An environment principal will hold grants for all approved spoke VNets in that boundary. A role assigned on a shared hub VNet can affect **all peerings under that VNet**, including other environments: environment-specific principals alone cannot enforce per-child isolation there. Accept that residual risk explicitly, or use independently scoped hubs and/or a validated finer-grained authorization design. PR/plan controls supplement RBAC; they do not shrink its effective scope.

Authorization/onboarding owners provision and review RBAC grants and exact federation subjects separately; attachment runs must not grant themselves access. Review additions/removals, inherited rights, approved DNS zones, plan/apply separation, provider registration readiness and negative tests against unapproved spokes. A workload endpoint identity may still need approved central-zone read/join rights for its DNS zone groups, but no attachment or hub-write rights.

## Routes DNS And Network Acceptance

Keep hub routes with the current core connectivity owner, and spoke routes with each spoke owner. The current route-table helper configures routes inline: do not introduce standalone `azurerm_route` resources against those tables from attachment states. A future routing workspace must migrate complete ownership deliberately. Hub-route changes required for onboarding still require a connectivity plan; separating attachments does not guarantee zero core changes.

Approve required forward/return routes, specific inspected prefixes, NSGs, NVA/ILB next hops, hybrid propagation and Panorama rules/NAT exceptions. A default `0.0.0.0/0` route alone does not prove inspection when more-specific routes exist. Gateway transit defaults off; a request must match explicit central approval, actual gateway/Route Server readiness and the approved inspection architecture. Do not assume a Route Server is deployed or use its IP as a firewall next hop.

Manage only the approved DNS links needed by the actual resolution design, with one owner per link. Link updates need not recreate peerings. Private endpoint zone groups, VNet links and custom/hybrid DNS forwarding are distinct; verify real resolution through Compeer's configured DNS path rather than assuming a link alone is sufficient.

## Deployment And Recovery Controls

1. Approve the inventory, IPAM overlap/containment checks, contracts, exact environment/provider groups and route/firewall/DNS changes. Protect inventory, HCP configuration, module pins and pipeline code with network/security reviewers.
2. Run formatting, validation, mock positive/negative contract tests, security scans and a full environment plan. Reject unrelated replacements/deletes, duplicate pair/link ownership or membership outside the approved inventory. Stable keys prevent identity churn, not refresh of the other attachments.
3. Acquire a shared deployment gate keyed to the actual hub VNet ID before the authoritative plan/apply sequence. Coordinate relevant core hub and dedicated-exception runs through the same gate. Separate environment workspaces targeting one hub do not share HCP state locks. Configure HCP so direct VCS auto-applies or manual apply paths cannot bypass the gate; a run trigger alone is not a cross-workspace mutex.
4. Serialize all peering mutations within the batch as well as across workspaces. The new pattern gives all peerings one common AzAPI provider-process `locks` key and orders hub halves before spoke halves. These are not Azure management locks and do not span workspaces. Retained AzureRM/core writers need their own tested internal serialization (for example bounded `-parallelism=1`). The protected external hub gate coordinates runs; a per-pair `depends_on` or HCP state lock alone is insufficient. Re-plan after upstream/routing changes; use bounded retries only for verified transient conflicts.
5. Coordinate approved hub routes, spoke UDRs and Panorama changes through their existing owners. Create/update both peering directions and required links under the controlled sequence. The pair is not atomic; preserve state after partial failure, inspect the existing half, re-plan and reconcile rather than deleting the hub or rebuilding all spokes.
6. Accept only after both sides report Connected, DNS/PE resolution works, representative approved flows traverse Palo Alto with symmetric return paths, forbidden flows remain blocked and required logs/approvals are recorded. Test credentials and denied operations live; mock success is not this evidence. Release the gate only after completion or a documented controlled failure handoff.
7. Retire an attachment through an approved inventory PR and reviewed plan; remove its peerings before moving/deleting the VNet. Coordinate dependent links, stale routes and Panorama cleanup with their owners. A map-key removal is destructive and needs approval; routine onboarding must not authorize teardown implicitly.

## Release And Existing State Adoption

Before the environment model is production-enabled, require: the tested/pinned AzAPI batch and typed contract; exact OIDC/RBAC evidence; enforced shared-hub and internal-run serialization; real DNS/routing/firewall acceptance; and partial-apply/retirement recovery procedures. Publish verified HCP releases and keep each environment root's release/trigger path independent. No placeholder registry version is an approved pin.

For existing per-spoke or split-owner attachments, freeze source/destination and other conflicting hub applies, inventory exact resource IDs/addresses/settings, back up states, and prepare the destination preserving names. Transfer **only peerings and designated DNS links**, never VNets/routes. Release old state bindings without destroying Azure resources, import into the new owner under the freeze, review both full plans and verify connectivity. `moved` blocks alone cannot transfer resources between backends. Record interruption recovery and rollback ownership; never leave two active state owners or restore whole state snapshots blindly.

This update adds disabled environment roots, a tested batch implementation and gate tooling, but performs no live apply, RBAC/federation grant, external gate configuration, state transfer or legacy identity migration. Existing single-pair module addresses and deployed inputs remain unchanged.

## Design Basis

- [Microsoft peering requirements and permissions](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-manage-peering): reciprocal configuration and lifecycle requirements, not an HCP workspace-count mandate.
- [Microsoft networking RBAC operations](https://learn.microsoft.com/en-us/azure/role-based-access-control/permissions/networking): peering, remote peer and DNS operation definitions.
- [HashiCorp workspace practices](https://developer.hashicorp.com/terraform/enterprise/workspaces/best-practices): group by lifecycle, privileges and operational impact.
- [Terraform providers within modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers): static provider association and provider configuration lifetime.
- [HCP Azure dynamic credentials](https://developer.hashicorp.com/terraform/cloud-docs/dynamic-provider-credentials/azure-configuration): exact federation subjects, phase-specific clients and alias authentication.
- [AzureRM 4.81 peering concurrency](https://github.com/hashicorp/terraform-provider-azurerm/blob/v4.81.0/website/docs/r/virtual_network_peering.html.markdown#note) and [route ownership](https://github.com/hashicorp/terraform-provider-azurerm/blob/v4.81.0/website/docs/r/route_table.html.markdown): serialize mutations; do not mix inline and standalone routes.
- [Microsoft route selection](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview#how-azure-selects-routes-for-traffic-routing): validate effective routes, not a default route alone.
- [Azure Virtual Network Manager connectivity](https://learn.microsoft.com/en-us/azure/virtual-network-manager/concept-connectivity-configuration): future alternative requiring its own ownership/migration decision.

Environment/hub grouping is Compeer's engineering operating-model choice, informed by this guidance. Microsoft does not prescribe four workspaces or this exact Terraform state layout.
