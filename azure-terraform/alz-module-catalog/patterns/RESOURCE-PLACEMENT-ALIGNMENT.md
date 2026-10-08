# Platform Landing Zone Resource Placement Alignment

## Purpose

This review compares the architect's resource placement list dated 23 September 2026 with the current Terraform patterns and the deployable roots under `implementations/platform-lz/workspaces`.

The placement list is treated as the latest implementation direction, subject to the open decisions identified below. This document records the code changes required before the affected workspaces are applied. It does not replace the architecture and design document.

## Current Assessment

The catalogue contains reusable patterns for most resources in the placement list. It is not yet fully aligned for deployment because several enabled implementations still reflect the earlier architecture.

The most important gaps are:

1. Domain controllers are still modelled in hub subnets and the directory-services workspace reads those hub subnet IDs. The new placement requires a dedicated identity VNet peered to the hub.
2. Only two domain controller VMs are configured. The placement list requires four: two for the internal forest and two for `compeer.ext`.
3. Platform Key Vault/storage private endpoints remain on hold; management and identity-security no longer deploy them, but final network access posture still needs approval before those services are used.
4. Palo Alto Key Vault is still explicitly private and uses a hub private endpoint.
5. Several patterns use one resource group for an entire stack, while the placement list requires separate network, firewall, hybrid, security, monitoring, storage, identity, and backup resource groups.
6. Bastion, Sentinel, ExpressRoute, VPN, local network gateway, directory services, and workload spokes exist as capabilities but are disabled or incomplete in the implementation values.
7. The platform-policy private-only initiative is assigned at `compeer-enterprise-mg` and can conflict with approved public platform Key Vault/storage resources unless its exclusions are updated.

## Decision Conflicts To Resolve

The screenshots and the accompanying direction are not fully consistent. Resolve these before changing or applying the affected workspaces.

| Subject | Latest written direction | Placement-sheet direction | Required decision |
|---|---|---|---|
| DNS/DC subscription | Says the DNS/DC spoke should be in the connectivity subscription | Rows 33-36 and note 1 place the dedicated identity VNet, four DCs, and backup vault in the identity subscription | Recommend the placement-sheet model: identity subscription, because identity owns the service and lifecycle. Confirm formally. |
| Platform private endpoints | Says not to use private endpoints for platform Key Vault/storage | Rows for the platform Key Vault/storage private endpoints are `On Hold`, but note 3 says platform private endpoints remain in connectivity | Treat the explicit latest decision and `On Hold` rows as authoritative: do not deploy them. Update note 3 in the source sheet/design document. |
| Platform public access | Says Palo Alto needs a public Key Vault or storage account | Existing code generally assumes private-by-default or service-endpoint-only access | Confirm whether "public" means unrestricted public access or public endpoint with `default_action = "Deny"` and approved subnet/IP allowlists. The latter is recommended. |

## Placement Matrix

### Governance

| Placement requirement | Current code | Status | Required change |
|---|---|---|---|
| Core baseline, tagging, diagnostics DINE, and encryption policies at `compeer-enterprise-mg` | `platform-governance` owns the initial baseline; `platform-policy` owns additional assignments | Mostly aligned | Keep enterprise-wide assignments at the enterprise MG so descendants inherit them. Confirm that duplicate policy ownership does not exist across the two states. |
| Custom RBAC role definitions at enterprise scope | `platform-authorization` supports custom roles | Aligned by capability | Configure approved roles only after IAM approval. Keep role definitions and assignments out of the policy state. |
| Sandbox guardrail at `sandbox-mg` | Policy pattern supports MG-scoped assignments | Capability present | Add/confirm the sandbox assignment in implementation values before sandbox onboarding. |
| Deny-new-deployments at `decommissioned-mg` | Policy pattern supports MG-scoped assignments | Capability present | Add/confirm the decommissioned assignment and test exemptions before moving subscriptions. |

### Connectivity

| Placement requirement | Current code | Status | Required change |
|---|---|---|---|
| Hub VNet in connectivity subscription/network RG | `platform-connectivity` creates the hub VNet with address space `10.102.0.0/21` | Aligned conceptually | Confirm explicit RG name and set custom DNS only after DC promotion/health is complete. |
| Hub subnets: gateway, Route Server, SD-WAN LAN/WAN, Palo management/untrust/trust/partner, shared services, App Gateway, CFT agent | Documented subnet names/CIDRs are modeled in `platform-connectivity`; Bastion remains disabled/no subnet | Mostly aligned | Confirm whether private-endpoint and app-integration subnets remain required, since they are outside the latest hub subnet table but inside the approved `/21`. |
| Hub NSGs | NSGs exist only for Palo management, connectors, and domain controllers; firewall trust/untrust and shared services do not have explicit NSGs | Partial | Define the approved NSG matrix and associations. Remove the hub DC NSG after migration. Do not add NSGs to `GatewaySubnet`. |
| Route tables for gateway, shared services, SD-WAN, and firewall management | `to_firewall` plus SD-WAN LAN/WAN route tables exist and are attached through subnet `route_table_key` | Partial | Model additional distinct tables only where routing requirements differ. Confirm propagation and next-hop design; do not force gateway traffic through the firewall without network approval. |
| Hub-to-spoke peering | Separate network-peering pattern exists but its implementation is disabled | Capability only | Enable per spoke after hub and spoke outputs exist. Add the identity VNet as a first-class peering target. |
| Palo Alto VMs, NICs, internal load balancer and public IPs in firewall RG | Resources exist, but the Palo implementation defaults `resource_group_name` to the hub connectivity RG | Deviates | Add/use a dedicated firewall RG input and deploy Palo resources to `platform-cus-prod-firewall-rg`. Do not silently inherit the hub network RG. Replace placeholder SSH keys and confirm image/licensing before apply. |
| Palo bootstrap storage account | Implemented with public network access enabled, firewall default deny, and the management subnet allowed through a service endpoint | Largely aligned with revised direction | Confirm whether service-endpoint-restricted public access satisfies the architect. Keep it in the firewall RG and add policy exclusion by exact scope if required. |
| Palo bootstrap Key Vault | Currently private with a private endpoint in the hub | Deviates | Remove the private endpoint configuration. Change to an approved public endpoint posture, preferably firewall `Deny` plus explicit subnet/IP allowances. Confirm whether both bootstrap storage and Key Vault are required. |
| ExpressRoute circuit/gateway/connection | Pattern exists; all resources and readiness posture are disabled/unconfigured | Not deployable yet | Supply carrier circuit, peering, gateway, connection, BGP, authorization, and approved CIDR details. Split or explicitly name the hybrid RG as listed. |
| VPN gateway/public IPs and local network gateway/S2S | Pattern exists; disabled/unconfigured | Not deployable yet | Supply gateway SKU, active-active/BGP decision, public IPs, local gateway, PSK handling, connection and failover details. |
| VPN certificate Key Vault and managed identity | Key Vault scaffolding is enabled but private and created by hybrid pattern in its own RG | Deviates | Place the vault/identity in the approved security Key Vault RG/subscription boundary, or document the exception. Remove its private endpoint if the no-platform-PE decision applies. |
| Existing private DNS zones and hub links | Connectivity reuses existing zones and creates links | Aligned conceptually | Replace the placeholder `net-ncus-plfc-rg` with the confirmed existing subscription/RG and confirm cross-subscription permissions. Link both hub and identity VNet as required. |
| Azure Bastion and public IP | Capability exists but is disabled | Capability only | Enable it and place it in `platform-cus-prod-security-rg`. Current connectivity pattern's single RG model must be extended or Bastion moved to a dedicated security pattern/root. |
| Firewall Recovery Services vault | `platform-palo-alto` now owns `platform-cus-prod-backup-rg`, `platform-cus-prod-rsv`, a VM backup policy, and optional Palo VM backup enrollment | Aligned for placement | Confirm retention/immutability with architecture and run a restore test. If the network team decides Palo VMs are stateless/no-backup, remove the vault and enrollment together. |

### Management And Security

| Placement requirement | Current code | Status | Required change |
|---|---|---|---|
| Log Analytics in management subscription monitoring RG | Implemented in `platform-management` | Aligned conceptually | Set explicit name/RG and validate diagnostics destinations. |
| Microsoft Sentinel, connectors and break-glass alert | `platform-management` now enables a new Sentinel workspace on the new LZ Log Analytics workspace, enables the Defender for Cloud connector, routes subscription Activity Logs, and sets 90-day analytics / 1.5-year total retention for active security tables. Extra identity/governance rules and ServiceNow/SIR integration remain Security Operations-owned. | Aligned for platform baseline | Confirm the Security Operations distribution list for alert routing, then enable Entra diagnostics/connectors and extra analytics rules after SOC validates the connected tables. |
| Microsoft Defender for Cloud inheritance | `platform-policy` now assigns approved Defender plan auto-enablement at `compeer-enterprise-mg`; `platform-management` manages its own subscription pricing directly | Aligned for current baseline | Keep Servers P1 unless Security approves P2; add Defender CSPM only after licensing, ownership, and workflow are approved. |
| Platform diagnostics/artifact storage in management storage RG | Storage exists but currently shares the management pattern RG | Deviates | Support a dedicated storage RG or split storage ownership into a small platform-storage pattern/root. Set the approved public endpoint/network ACL posture. |
| Platform storage has no private endpoint | Management no longer has a PE deployment surface, which aligns with the on-hold placement decision | On hold | `public_network_access_enabled = false` leaves the account unreachable without a PE. Set the approved public endpoint posture or create a connectivity-owned PE after approval. Retain OAuth, key restrictions, TLS and network ACL controls. |
| Platform Key Vault in security subscription/Key Vault RG | `platform-identity-security` is now the sole platform Key Vault owner; the duplicate management vault surface was removed | Aligned for ownership | Confirm the workspace runs against `sub-security-prod-cus` and keep the explicit approved name/RG. |
| Platform Key Vault has no private endpoint | Identity-security no longer deploys the PE; private endpoint creation is reserved for a future connectivity-owned composition | On hold | Because the vault has public access disabled, data-plane use requires either an approved connectivity-owned PE or an approved public endpoint/network ACL posture. |
| Identity/management/firewall backup vault placement | The generic management vault has been removed; directory-services owns the identity/DC vault and `platform-palo-alto` owns the connectivity/firewall vault | Aligned for placement | Keep backup vaults with the subscriptions/RGs that own protected resources. Confirm policy retention and restore evidence for both vaults. |

### Identity And Directory Services

| Placement requirement | Current code | Status | Required change |
|---|---|---|---|
| Dedicated identity VNet, subnets, NSG and route table in identity subscription | No identity VNet pattern/root exists. DC subnets are in the hub | Missing | Add an identity-network deployment in the identity subscription. It should own the VNet, one or more approved DC subnets, NSGs, UDRs and outputs. Reuse the VNet base modules rather than embedding networking in the VM module. |
| Identity VNet peered to hub | Directory services only reads hub subnet outputs | Missing | Extend network peering to consume identity-network outputs and create both directions with approved gateway/transit settings. |
| Two internal-forest and two `compeer.ext` DCs | Two DCs are configured, one per subnet/domain assumption | Missing capacity | Configure four stable keys, approved static IPs and availability-zone placement. Confirm forest-to-subnet mapping with AD. |
| DC IP addresses match identity VNet CIDRs | Configured DC IPs are `10.0.10.10/11`; current hub subnets are `10.102.3.0/27` and `10.102.3.32/27` | Invalid | Obtain identity VNet CIDRs from IPAM and allocate all four addresses from those subnets. Terraform/provider validation will otherwise fail. |
| Directory-services consumes identity network | It consumes `platform-connectivity` outputs | Deviates | Replace the connectivity workspace dependency with an identity-network workspace dependency or explicit identity subnet IDs. Keep VM lifecycle separate from VNet lifecycle. |
| DNS service and forwarding | Current model expects DNS/AD team operational work and has hub `dns_servers = []` | Incomplete | Confirm AD-owned promotion and DNS configuration. After healthy promotion, point the identity VNet and required spokes/hub to approved DNS IPs. Document forwarding/conditional-forwarding and failure behavior. |
| Identity Recovery Services vault | Directory-services configures `platform-cus-prod-identity-rsv`, creates a DC VM backup policy, and enrols all four DCs by key | Aligned for placement | Confirm retention/immutability and test restore once the four DCs are deployed. |

### Workloads And Sandbox

| Placement requirement | Current code | Status | Required change |
|---|---|---|---|
| Workload spokes with subnets, NSGs, UDR and hub peering | Workload-spoke and peering patterns exist; sample implementation is disabled | Capability only | Instantiate per approved pilot subscription/environment and supply non-overlapping IPAM ranges. |
| Workload Key Vault/private endpoint/managed identities | Workload-spoke supports private-by-default Key Vault and private endpoints | Aligned by capability | Enable for the selected pilot and resolve private DNS zones/subnets. Keep the exception mechanism for workloads explicitly approved for public access. |
| Workload storage private endpoints | Supported by workload-spoke | Aligned by capability | Configure per storage service subresource and DNS zone; do not create unused endpoints. |
| Sandbox spokes | Generic workload-spoke can model them, but no four sandbox roots are configured | Not implemented | Create keyed workspace/root instances for ops, developer, data and architect only when subscriptions and CIDRs are approved. |

## Policy Changes Required

The revised public-access decision must be reconciled with policy before platform resources are applied.

1. `platform-policy` currently enables `private_only_connectivity` at `compeer-enterprise-mg` in Audit mode. Audit will not block deployment, but it will deliberately report approved platform resources as non-compliant unless exclusions are added.
2. Prefer narrow policy exclusions using assignment `not_scopes` for approved platform resource IDs or dedicated resource groups. Do not weaken the workload baseline globally.
3. Keep workload Key Vault/storage private-by-default. Apply any workload public exception through a documented policy exemption with owner, reason and expiration.
4. Update the policy README language that currently presents private endpoints as the universal platform posture.
5. Verify that the global-governance public-PaaS controls and platform-policy private-only initiative do not duplicate or contradict one another.
6. Keep approved Palo/Bastion public IP resource-group allowances synchronized with the final RG names in the placement list.

## Recommended Workspace Ownership

Preserve separate states to limit blast radius. The placement changes do not justify combining networking, identity VMs, monitoring, policy or authorization.

| Workspace | Recommended ownership |
|---|---|
| `platform-governance` | Management-group hierarchy and initial enterprise baseline |
| `platform-policy` | Additional policy assignments, exemptions and remediation |
| `platform-authorization` | Entra groups, custom roles and RBAC assignments |
| `platform-connectivity` | Hub VNet, hub subnets, NSGs, UDRs and existing private DNS links |
| `platform-palo-alto` | Palo VMs, NICs, load balancers, public IPs and bootstrap resources in firewall RG; firewall backup RG/RSV/protection when enabled |
| `platform-hybrid-connectivity` | ER/VPN gateways, circuits and connections in hybrid RG |
| `platform-identity-network` (new) | Identity VNet, DC subnets, NSGs and UDRs |
| `platform-network-peering` | Hub-to-identity and hub-to-workload peerings |
| `platform-directory-services` | Four DC VMs/NICs/disks, backup enrollment and AD operational contract |
| `platform-management` | Log Analytics, Sentinel, action groups, management diagnostics and Defender posture |
| `platform-identity-security` | Authoritative platform Key Vault and managed identities in security subscription |
| `platform-workload-spoke` | One workload/sandbox spoke instance per deployment boundary |

Separate resource groups do not always require separate workspaces. Patterns should accept resource-group names/IDs per resource family where lifecycle remains shared. Create a separate workspace only when ownership, permissions, deployment order or failure domain is materially different.

## Implementation Sequence

1. Obtain formal decisions for the three conflicts above, final subscription IDs, RG names, CIDRs and access posture.
2. Update policy exclusions before deploying approved public platform Key Vault/storage resources.
3. Refactor connectivity to remove DC subnets and add the identity-network root/pattern.
4. Deploy hub and identity networks, then peer them and link required private DNS zones.
5. Update directory services to consume identity subnet outputs; configure four DCs and identity-owned backup.
6. Correct Palo and hybrid resource-group placement and remove platform Key Vault private endpoints.
7. Split/configure management monitoring and storage RG placement; keep Sentinel enabled for the new LZ baseline and promote additional connectors/rules only after SOC approvals.
8. Enable Bastion, ER/VPN and other currently disabled components only when their external inputs and readiness gates are approved.
9. Deploy the pilot workload spoke with private Key Vault/storage endpoints and validate DNS resolution from the spoke.
10. Run plan-by-workspace and verify every planned resource's subscription, resource group, name, network exposure, policy compliance and dependency output before apply.

## Deployment Blockers

Do not apply the affected production workspaces until these blockers are cleared:

- Identity VNet CIDRs and four DC IPs are approved.
- The identity-versus-connectivity subscription decision for DNS/DCs is signed off.
- Platform Key Vault/storage public endpoint controls and policy exclusions are approved.
- Resource-group ownership is corrected or explicitly accepted as a design exception.
- Palo Alto placeholder SSH public keys and Panorama/bootstrap values are replaced.
- Existing private DNS zone subscription/RG values are confirmed.
- ExpressRoute/VPN provider, BGP, routing, PSK and failover details are approved.
- Security Operations distribution list, ServiceNow/SIR integration path, and any extra Sentinel analytics rules are approved.
- Backup requirements for Palo VMs and domain controllers are reconciled and restore tests are defined.
