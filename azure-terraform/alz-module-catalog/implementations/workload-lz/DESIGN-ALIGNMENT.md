# Step 11 Design Alignment

Review date: 2026-10-17. This records code alignment, not deployed Azure
compliance, client approval or Step 12 sign-off. Source Office files were read
without modification from the supplied azure-cloud directory.

## Sources And Precedence

- Azure Landing Zone Architecture & Design Document v13 - naming update.docx:
  sections 6, 7, 8.2-8.5, 9.1-9.3, 10.6, 11, 12.6-12.7, 13, 14 and Appendix F
  (section 18.9).
- Azure_LZ_MVP_Component_List_v4.xlsx: Component List and Phase 1 Deployment
  Order. Use the explicit deployment sequence for Step 11; do not silently
  treat target-state/Phase 2 services as approved Phase 1 deployments.
- Azure_LZ_Phase1_Resource_Placement.xlsx: Resource Placement (Refined), not
  Resource Placement (Older vers).
- Azure Resource Deployment in New Landing Zone_v2.docx: detailed network
  routing/NSG requirements. This contains newer operational decisions such as
  no Bastion and custom-data firewall bootstrap; neither is a spoke resource.
- Platform_Output_Contracts_IAC-10_v0.1.docx: consumer/publisher intent. The
  adapter uses existing approved catalog contract names/version 0.1.0 rather
  than changing deployed platform output APIs to the draft's prefixed names.
  The spoke now republishes resource-group IDs, approved LAW ID and the
  governance mandatory_tag_keys list to application roots. Each environment root
  reads only nonsensitive_values from governance and fails if its key list is
  empty or required workload metadata is missing; it never grants an application
  root access to full platform state.

Later explicit user decisions take precedence: no workload locks, placeholders
and disabled deployment examples, mixed compute kept separate, and subscription
onboarding/vending retained by platform-governance. No unrelated platform
resource is moved between subscriptions by this change.

The later 2026-10-19 ownership decision selects a separate platform-owned
attachment state, rather than embedded spoke peering. The blueprint publishes
intent and creates no attachment resources or hub provider. This changes state
ownership, not Azure resource placement. Follow ATTACHMENT.md before upgrading
an existing state that still owns peerings or zone links.

## Phase 1 Placement And Step 11 Coverage

| Source | Required outcome | Code implementation |
| --- | --- | --- |
| Deployment Order rows 97-99; Component List WKL-01, NET-23/24 | One reusable blueprint, same module with separate prod/nonprod inputs | patterns/terraform-azurerm-compeer-spoke-landing-zone; two disabled workspace roots with direct independent release pins; see ISOLATION.md |
| Refined Placement rows 38/41; Appendix F | <app>-cus-<env>-network-rg and <app>-cus-<env>-spoke-vnet in the workload subscription | Canonical naming module; new blueprint opts out of legacy domain-prefixed RG names |
| Refined Placement rows 39/42; WKL-07, IAM-06; design 9.1 | Workload vault, private endpoint and UAMI in each workload subscription's security RG | Dedicated vault by default; user-approved 2026-10-20 opt-out for secretless workloads. Enabled vaults retain private-only RBAC, purge protection, scoped Secrets User and required central AuditEvent diagnostics; see CAPABILITIES.md |
| Refined Placement row 40; design 10.6 | <app>-cus-<env>-app-rg reserved for the internal pilot | Logical output/access key application remains stable; Azure purpose is app; compute stays application-owned |
| Deployment Order row 100; NET-22 | Both peering directions, forwarded traffic and correct ownership | Separate platform-owned attachment state composes the reusable hub-spoke-peering pattern from the spoke's versioned contract; no hub provider or attachment resources in blueprint |
| Deployment Order rows 101-103; NET-29/IAM-06 | Parent-owned endpoints, existing central DNS, scoped identity | Vault owns endpoint/zone group; optional Blob parent uses its own group; no duplicate DNS zone or unrestricted identity roles |
| Design 8.2/8.5; Deployment Order rows 66-67; detailed network document | Spoke inspection via Palo Alto NVA, not direct gateway bypass; Sunstream isolation | Default plus exact hub/approved remote-prefix UDRs; BGP propagation disabled; reserved baseline routes; Sunstream priority-100 denies |
| OBS-01/02, GOV-07; design 13 | Reuse centralized logging and policy owners | Existing approved LAW ID; direct vault/optional Blob diagnostics; platform-policy owns compatible DINE, Defender and VNet flow logs |

The two platform endpoint rows 24-25 are explicitly **On Hold** in the refined
sheet. They concern the PLATFORM vault/storage endpoints attached to the hub,
not the workload vault endpoints in rows 39/42. Accordingly the spoke still
creates its required private vault endpoint and creates no platform endpoint.
Hub/spoke/DNS aliases in the central attachment workspace govern both peerings
and existing-zone VNet links. Workload resources remain on the workload provider;
private-endpoint DNS zone groups stay parent-owned.

## Commented-Out Or Unprovisioned Capabilities

Both workspace terraform.tfvars files keep enabled=false and comment the
following activation examples. Reusable tested implementations remain available
behind explicit opt-ins, rather than deleting working capabilities.

| Capability | Hold / ownership decision |
| --- | --- |
| Application Insights, telemetry publishing role | OBS-09, Component List row 124, is Phase 2. monitoring.enabled defaults false. No telemetry component or role is created while held. |
| Workload failure alerts and their action group | OBS-04, row 81, is Phase 2. monitoring.alerts_enabled defaults false; requires enabled telemetry and approved recipients. No unused operations RG/action group is created in the Phase 1 default. |
| Subscription budget | GOV-13 row 14 says Phase 2, while Refined Placement note row 52 calls for a subscription baseline budget at creation. User decision for this package: remove budget code, inputs and outputs. Phase 2 ownership remains with governance; no spoke opt-in exists. |
| Workload Blob/data services | WKL-05 row 105 is Phase 2. storage_accounts defaults empty; its example is commented out pending an actual workload need and existing central Blob DNS zone. If approved, production uses ZRS/30-day recovery, nonprod LRS/7-day recovery; security remains equal. |
| VM backup enrollment | No compute is deployed here. backup defaults null, with a commented example pending real VM IDs and an approved same-subscription RSV/policy. Platform vaults are not recreated in every spoke. |
| Workload locks | Deliberately absent per user decision. No lock resource or enable switch is reintroduced. |
| AKS/containers, APIM, databases, AVD, public ingress, Cloudflare connectors, secondary region/ASR | Separate workload/Phase 2 capabilities; no resource blocks are introduced into this foundation. No new Bastion, firewall, DNS servers, gateways, LAW or Sentinel instance is created. |
| Subscription creation, placement and self-service vending | Governance/CSP owner; no subscription or MG mutation from the spoke. Vending remains held under that owner until CSP approval. |

Production/non-production profiles remain distinct for approved optional
resilience, telemetry and alerts. Both retain identical private vault, RBAC,
encryption, NSG/UDR and central security-diagnostic controls.

The 2026-10-19 reuse refinement does not release these holds or move resources:
management's existing primary action group can be referenced via its public
output; a new application group requires explicit creation and recipients.
Approved existing application/environment Application Insights components can
also be referenced without managing their settings or identity grants. Creating
a new component or delegating a scoped publishing grant is explicit. Central
LAW, hub/DNS, policy and backup-vault ownership remain unchanged. Dedicated
workload vault/UAMI requirements are not replaced by shared platform security
resources. See [REUSE.md](REUSE.md) for configuration and state-handoff cautions.

## Conflicts And Go-Live Gates

1. **R3.4 overrides a simplistic phase checklist.** Component rows OBS-04,
   OBS-06 and OBS-09 defer services that design sections 9.2, 12.7 and 13 also
   describe within mandatory observability. Holding a module does not authorize
   an unmonitored production workload. Security/Cloud Operations must approve
   actual required sources, pipeline health alerts, endpoint telemetry and
   ingestion evidence, or a formal time-bound exception, before Step 12 go-live.
   These controls are not silently replaced by this application's failed-request
   alert. SCCM/SolarWinds reachability also needs approved NSG/NVA rules and
   application/operations-owned agents (OBS-10/PLT-09).
2. **Workspace topology is unresolved in the sources.** The v13 text says per
   environment; OBS-01 and the refined sheet describe a central workspace. This
   implementation reuses the selected approved management output. It does not
   create extra workspaces/Sentinel instances or claim the topology decision is
   signed off. An approved environment-specific LAW can be supplied through
   platform_inputs.log_analytics_workspace_id without redesigning the spoke.
3. **Backup placement is not a cross-subscription assumption.** Design 9.3 says
   centralized regional RSV; the refined sheet splits platform backup vaults by
   VM-owning subscription. Workload VM enrollment requires an approved vault in
   that VM's subscription, or a separately designed supported backup solution.
4. **Routing is end to end.** Supply the exact identity/on-prem/other-spoke
   inspection_address_prefixes and complete reserved_address_spaces from IPAM.
   Hub and Sunstream route prefixes are automatic; Sunstream stays NSG-denied.
   A regional supernet is not an inspection list. The network owner must also
   add the spoke's return routes to relevant hub tables, approve Palo Alto
   policies/SNAT and prove symmetry. The spoke cannot mutate independently
   owned hub route tables. No claim of live inspection follows from mock tests.
5. **Onboarding and access remain prerequisites.** CSP/governance must confirm
   the subscription's correct environment MG and subscription baseline, policy
   convergence, separate prod/nonprod run identities, PIM and scoped DNS/hub
   permissions. HCP output-read access is not full-state sharing. Registry
   publishing/API compatibility is a release gate for the separately maintained
   HCP-pinned local copy. This repository uses the existing catalog modules,
   with the same blueprint behavior and tests. See README.md and TESTING.md.

## Existing-State Caution

These are new-deployment templates. Correcting domain-prefixed RGs to the
refined sheet's workload-prefixed names (and application-rg to app-rg) may
replace deployed RGs/resources. Do not apply a replacement plan to an existing
spoke without a reviewed migration. The naming module keeps legacy defaults
for other callers. If existing telemetry/alerts are already deployed, retain
their explicit enabled flags pending approval; switching them off plans removal,
not a nondestructive pause. Existing budgets require a separate reviewed state
handoff before adopting this budget-free package. Moved blocks preserve only the
remaining approved telemetry addresses. Review all plans in
HCP; no Azure apply, state migration or policy change was performed here.

Microsoft's [route-selection documentation](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview)
explains why a default route alone does not supersede a more-specific peering
route. Its [Private Link hub/spoke guidance](https://learn.microsoft.com/en-us/azure/architecture/networking/guide/private-link-hub-spoke-network)
supports workload-specific endpoints with centrally managed private DNS.
