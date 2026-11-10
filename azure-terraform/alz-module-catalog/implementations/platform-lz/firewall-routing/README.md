# Deferred Firewall Routing Cutover

PHASE 2 ROUTING FOLLOW-UP: prepare Dan's static Hub routes, verify the Palo Alto forwarding path, then cut Internal Identity over from temporary gateway propagation to reviewed static routes. This is **not** a peering migration, firewall rebuild, new workspace or automatic production cutover.

## Scope And Source

Reference: **Azure Resource Deployment in New Landing Zone_v2 (1)**, sections **Hub Route Tables** and **Identity Domain Controller VNET (Internal)**, plus Dan's November 9 follow-up. The document describes desired configuration; it is not evidence that a particular deployed route is missing. Reconcile against Azure and the existing Terraform owner before enabling anything.

| Existing Owner | Files To Update | What Changes |
| --- | --- | --- |
| Hub connectivity | [main.tf](../workspaces/platform-connectivity/main.tf), [firewall_routing.tf](../workspaces/platform-connectivity/firewall_routing.tf), [example](../workspaces/platform-connectivity/firewall-routing.tfvars.example), `tests/`, `routing-example-tests/` | Complete the nine unambiguous hub route sets and their subnet associations through the existing inline route-table modules |
| Internal Identity | [main.tf](../workspaces/platform-directory-services/main.tf), [firewall_routing.tf](../workspaces/platform-directory-services/firewall_routing.tf), [example](../workspaces/platform-directory-services/firewall-routing.tfvars.example), `tests/`, `routing-example-tests/` | Existing selected table keys receive default/hub/approved remote routes through the verified Trust ILB and `bgp_route_propagation_enabled=false` together |
| Pilot application | Its existing spoke deployment root, not central peering | Verify `egress_next_hop_ip`, hub prefixes, other inspected prefixes and BGP-off on every applicable subnet; examples below |
| Palo Alto/network team | Existing Panorama/firewall and hybrid-routing owners | Health/HA forwarding, policies, symmetric return routes and live flow acceptance; not configured by these Terraform overlays |

All new sections are visibly marked **PHASE 2 ROUTING FOLLOW-UP**. Both roots default `firewall_routing.enabled=false`: existing routes, names, subnet keys, addresses, BGP settings, VM configuration and peerings remain unchanged until a reviewed cutover is enabled. No new peering resources or `azurerm_route` resources are introduced.

The full overlay objects are now merged into the actual [connectivity tfvars](../workspaces/platform-connectivity/terraform.tfvars) and [Identity tfvars](../workspaces/platform-directory-services/terraform.tfvars), not only the portable examples. Both remain disabled, with unresolved deployment details/approvals visibly marked. Existing base configuration is unchanged, including the older, disabled Identity sample; merging the overlay does not make that sample a verified representation of Compeer's deployed VNet/DCs.

For the **existing Compeer Hub shown in the supplied plan**, use [compeer-existing-hub.tfvars.example](../workspaces/platform-connectivity/compeer-existing-hub.tfvars.example) instead of copying this repository's older Hub bindings unchanged. It preserves the ten existing table keys, binds the Cloudflare role to `cftagent` (not `to_firewall`), omits binding names for existing generated names and explicitly lists the inherited `appgw.default` route for reviewed removal. Merge only its `firewall_routing` object into the actual owner; its flags remain false until the cutover facts are confirmed.

This is root composition using the existing patterns' `hub_vnet`, `route_tables` and association interfaces; no shared/base resource-module change is required. When porting into Compeer, retain its existing approved HCP module source/version, provider configuration and backend. Adapt only the clearly marked input wiring to the real module call. Do not overwrite the deployed root with this repository's sample `main.tf`/tfvars wholesale.

**Use the deployed owner, even if its repository/workspace name differs from these examples.** In particular, this repository's old directory-services tfvars has tentative `10.103.*` prefixes and both forests in one VNet. Do not copy that object into the already deployed Internal Identity VNet or replace it with a freshly named VNet. Merge the new overlay into the real owner's existing configuration; confirm its table keys and subnet associations.

## Required Hub Matrix

Trust next hop means `VirtualAppliance` plus the **verified frontend IP** of the deployed Trust ILB. Blackhole means next hop `None`, without a next-hop IP. Each spoke means **each applicable deployed spoke VNet prefix**, not just each subnet or newly onboarded application.

| Role / Document Table Name | BGP Propagation | Trust ILB Destinations | Blackholes |
| --- | --- | --- | --- |
| `gateway` / `cus-prod-gateway-rt` | Yes | Every spoke; SD-WAN LAN, shared, App Gateway, Cloudflare-agent subnets | Untrust subnet |
| `sdwan_lan` / `cus-prod-sdwan-lan-rt` | No | Every spoke; shared, App Gateway, Cloudflare-agent subnets; default | Untrust subnet |
| `sdwan_wan` / `cus-prod-sdwan-wan-rt` | No | None added | Untrust and partner subnets |
| `shared` / `cus-prod-shared-rt` | No | Every spoke; SD-WAN LAN, App Gateway, Cloudflare-agent subnets; default | Untrust and partner subnets |
| `appgw` / `cus-prod-appgw-rt` | No | Every spoke; SD-WAN LAN, shared, Cloudflare-agent subnets | Untrust and partner subnets |
| `cftagent` / `cus-prod-cftagent-rt` | No | Every spoke; SD-WAN LAN, shared, App Gateway subnets; default | Untrust and partner subnets |
| `fw_trust` / `cus-prod-fw-trust-rt` | Yes | None added | Default/Internet, untrust and partner subnets |
| `fw_untrust` / `cus-prod-fw-untrust-rt` | No | None added | Each hub VNet prefix |
| `fw_partner` / `cus-prod-fw-partner-rt` | Yes | None added | Default/Internet, untrust and trust subnets |

The gateway keeps BGP propagation enabled and has **no default UDR**. The App Gateway table also has no default UDR; its documented specific routes do not force its management traffic to an NVA. The overlay rejects an inherited default route in either table rather than silently retaining a workaround. [Azure routing](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview), [App Gateway infrastructure](https://learn.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure).

**Management is deliberately deferred.** The document lists `cus-prod-mgmt-rt` with spoke/default firewall routes but later explicitly says management is direct/out-of-band with no UDR. This change implements neither side silently: it does not create/attach a management table, and enabling requires approved out-of-band management with no existing management UDR association. If one is already configured, reconcile it separately with Dan; do not delete or reroute it just to pass this guard. `RouteServerSubnet` is also not associated by this overlay.

**Internet blackhole interpretation:** Azure does not support the `Internet` service tag as a UDR destination. The two interface-table Internet blackholes are represented as `0.0.0.0/0 -> None`. This drops unmatched traffic, not every destination with a more-specific system/BGP/UDR route. Review this intended fail-closed fallback with the firewall engineer; do not substitute an invalid tag or assume it disables all public-prefix reachability. [Supported service tags](https://learn.microsoft.com/en-us/azure/virtual-network/service-tags-overview#tags-unsupported-for-user-defined-routes-udr).

### Firewall Interface Ownership

`fw_trust`, `fw_untrust` and `fw_partner` are included in **platform-connectivity's** `table_bindings`, because their subnets belong to the Hub VNet. The role matrix generates only their documented blackholes, with `next_hop_type="None"` and no next-hop IP. These roles never expand the spoke inventory or generate a route to their own Trust ILB. Adding a pilot/Identity/other spoke changes only the five documented ingress-role route sets, not these interface blackhole sets. Management has no binding while its OOB decision remains separately reviewed.

Use the existing inline route-table modules for these routes and associations. Do **not** add the illustrative standalone `azurerm_route.palo_alto_blackhole` resources, create duplicate tables in `platform-palo-alto`, or give a second state ownership of a Hub association. The provider forbids mixing standalone and inline routes on the same table. Existing extra routes are not silently deleted: reconcile them and explicitly name approved removals in `remove_route_keys` before cutover. [AzureRM route-table ownership](https://github.com/hashicorp/terraform-provider-azurerm/blob/v4.81.0/website/docs/r/route_table.html.markdown).

## Values To Obtain From Compeer

### Values Already Supplied In The Examples

The document does supply several values; they are now populated rather than left as placeholders. **Documented does not mean verified live.** Reconcile these against the deployed owners and Azure before enabling either example.

| Value | Source And Use |
| --- | --- |
| `10.102.4.42` | Document, **Trust Load Balancer**: static frontend of `platform-cus-prod-fw-trust-ilb`, frontend `platform-cus-prod-fw-trust-feip-01`. Used as the next hop in both examples; it is not a firewall NIC IP or an arbitrary free address |
| `10.102.0.0/21` | Document, **Hub Virtual Network**: Identity's explicit hub destination. Hub destinations also use the existing connectivity inputs |
| `10.102.8.0/27` | Document, **Identity Domain Controller VNET (Internal)**: Internal Identity VNet prefix, populated in the Hub spoke inventory |
| `10.102.64.0/27` | User's last reviewed **pilot plan**, not the design document: pilot VNet prefix, populated in both examples. Confirm its current producer output/Azure allocation |
| Six explicit Hub binding names | Document, **Hub Route Tables**: `cus-prod-gateway-rt`, `cus-prod-shared-rt`, `cus-prod-appgw-rt`, `cus-prod-fw-trust-rt`, `cus-prod-fw-untrust-rt`, `cus-prod-fw-partner-rt`. These are creation names only when the table is genuinely new; omit `name` for an existing table to preserve its deployed name |
| Existing SD-WAN/Cloudflare table names | Deliberately omitted from the bindings so their current names are preserved. The document calls them `cus-prod-sdwan-lan-rt`, `cus-prod-sdwan-wan-rt` and `cus-prod-cftagent-rt`; this is not permission to rename/import a deployed table |

### Values That Still Need Deployment Evidence

| Required Evidence | What To Confirm | Why |
| --- | --- | --- |
| Trust ILB identity and frontend | Actual subscription, RG, LB name, frontend configuration name and private IP; backend/probe health and failover | The document names `platform-cus-prod-fw-trust-ilb` and `10.102.4.42`, but these must match the deployed service; never choose an unused/random IP |
| Existing hub owner | Working directory/backend, current table map keys, actual Azure table names and import status | A matching Azure name alone does not make Terraform reuse it |
| Existing subnet keys/prefixes | All nine role bindings, management subnet, hub prefixes, any multi-prefix subnet | Hub route destinations are derived from the owner's existing subnet inputs, not copied guessed addresses |
| Complete deployed spoke inventory | Internal Identity and pilot prefixes, plus other existing attached VNets; External Identity only if actually deployed | Explicit per-spoke UDRs override direct peering system routes; a default alone is insufficient |
| Identity static-route set | Actual table keys/name/associations and every required hub, pilot/other spoke, on-prem DC/DNS/management prefix | Dan asks for proper static routes but does not enumerate this whole set; do not infer network CIDRs from DNS-server IPs |
| Temporary workarounds | Current route names/destinations/next hops in Azure and in source/state | Required destinations can be corrected in place; unrelated bypasses require explicit reviewed removal |
| Change and ownership approval | Ticket/reference, coordinated hub/Identity/app changes, protected hub gate, rollback owners and test evidence | Terraform readiness flags record these decisions; they do not implement or verify the approvals/health themselves |

The Identity inputs now select **`route_table_keys=["to_firewall"]`**, matching the table key already defined in this repository's `directory_services.route_tables`. That is not a claim about the deployed Compeer key. The document names the Azure table `cus-prod-intdc-rt`, but cannot tell you the key used by its deployment code. Read the actual owner's `route_tables` map and run `terraform state list` against its correct backend. For example, an address containing `module.route_tables["to_firewall"]` identifies the key `to_firewall`, not the Azure table name. Replace the selector with the existing key if different; do not rename or create a table just to match the example.

Obtain the complete static destination list from Dan/network engineering and the AD team/IPAM, including required DC replication, DNS and management networks. DNS-server addresses and broad NSG allow rules are not an authoritative routing inventory. Do not invent a CIDR from either. Unknown on-premises destinations are now omitted from the active inputs, not populated with placeholder strings or empty lists. **Missing information does not mean no routes are needed:** keep `static_route_set_reviewed=false` and Identity routing disabled until the complete set is confirmed. Readiness flags stay false until the named owners provide evidence. `remove_route_keys={}` is optional and removes nothing; fill it only with verified, approved bypass-route names.

`change_reference` is **optional string audit metadata**, retained for compatibility with existing callers. Omit it or use `change_reference=""`; `[]` is the wrong type. It does not configure Azure, verify a ticket or gate routing. Record approvals through the existing PR/change/HCP process; ownership, firewall-path, management and static-route readiness checks still apply independently. A supplied reference can identify the shared approved change covering both roots.

The Trust ILB RG/name are **verification facts**, not extra resources to create. Locate the real LB in Azure or the Palo Alto owner's published `load_balancer_ids`; do not assume the document's hub RG is also the LB RG. These read-only commands help confirm the actual frontend and existing table routes:

```bash
az network lb frontend-ip list \
  --subscription "<actual-firewall-subscription>" \
  --resource-group "<actual-load-balancer-rg>" \
  --lb-name "<actual-trust-ilb-name>" \
  --query "[].{name:name,ip:privateIPAddress,subnet:subnet.id}" -o json

az network route-table show \
  --subscription "<actual-table-subscription>" \
  --resource-group "<actual-table-rg>" --name "<actual-table-name>" \
  --query "{name:name,bgpDisabled:disableBgpRoutePropagation,routes:routes,subnets:subnets[].id}" -o json
```

Neither query proves forwarding health. Also check the LB's backend membership/probe health, effective routes and Palo Alto sessions with the network owner. [Frontend query](https://learn.microsoft.com/en-us/cli/azure/network/lb/frontend-ip#az-network-lb-frontend-ip-list), [route-table query](https://learn.microsoft.com/en-us/cli/azure/network/route-table#az-network-route-table-show).

No bootstrap keys, credentials or other document secrets are copied into code.

## Hub Configuration And Compatibility

The actual Hub root already contains the full `firewall_routing` object. The [portable example](../workspaces/platform-connectivity/firewall-routing.tfvars.example) remains a reference for porting it into Compeer's deployed owner as a **new top-level object**. Do not replace `connectivity` wholesale, change VNet CIDRs, rename tables to match the document or repoint a backend.

**Setting only `firewall_routing={enabled=true}` is not sufficient.** Complete and review the merged object, then change its `enabled` field in place; do not replace the object with that one field. Terraform does not auto-load `.tfvars.example` files. When porting into another root, merge the complete reviewed object into its existing `terraform.tfvars`, or explicitly pass `-var-file=firewall-routing.tfvars.example` for a local plan. Do not define the same attribute twice. An explicit variable file replaces the object supplied by an earlier file, not individual nested fields. For HCP runs, supply the reviewed configuration through the workspace's normal Git/variable process; do not assume a local CLI flag configures VCS-driven runs.

| Input | How To Use It |
| --- | --- |
| `enabled` | Keep false during reconciliation. True changes routing in the existing owner; it is not an operational pause switch after adoption |
| `trust_ilb_frontend_ip` | Verified deployed frontend IPv4 address, in the trust subnet. Both Hub and Identity/pilot next hops must match |
| `spoke_address_prefixes` | Map of stable VNet labels to sets of **all** their confirmed IPv4 network prefixes. Identity and pilot source-backed values are supplied. Add other deployed spokes; do not treat firewall NIC subnets as spoke VNets |
| `table_bindings` | Exactly the nine matrix roles, each bound to a unique existing/approved `route_table_key` and current `subnet_key`. Hub intra-subnet route prefixes are read from those existing subnet inputs |
| Binding `name` | Leave null/omitted for an existing table to preserve its current explicit/generated name. For a genuinely new table, supply its approved Azure name. A different binding name cannot rename an existing table |
| `remove_route_keys` | Optional map of current table keys to the **current inline route names** of reviewed workarounds to remove. Default `{}` deletes no unrelated routes |
| `management_subnet_key` | Current management subnet key; used to ensure this change does not reroute it |
| `change_reference` | Optional audit string; omit or use `""`, not `[]`. It is not an Azure routing setting or a deployment gate |
| Readiness flags | Reviewed ownership, working firewall path and out-of-band management. Set true only after the external evidence exists; optional audit metadata does not replace these checks |

Existing table map keys and module addresses remain the same. For a required destination already present in a selected table, the overlay reuses its inline route key/name and replaces the next hop/type with the required value. It adds only missing required destinations; other routes survive unless explicitly listed for removal. Duplicate destinations, overlapping supplied hub/spoke prefixes and default UDRs on Gateway/App Gateway fail the plan. The complete estate inventory is still a human/network responsibility; the code cannot detect an omitted deployed spoke.

The repository currently uses `to_firewall` for Cloudflare agents and extra PE/app-integration subnets. Binding `cftagent` to that existing key preserves its table name/address, but **all subnets sharing that table receive its routes**. Review every association, not only the named agent subnet. A dedicated split requires a separately approved association/table change; this overlay does not rename or delete the shared table automatically.

### Reviewing The Existing Compeer Hub Plan

The supplied plan is **not ready to apply unchanged**. Most added inspection routes and missing firewall blackholes match the intended matrix, but the input mapping and safety failures need correction:

| Plan Finding | Required Action |
| --- | --- |
| New `module.route_tables["to_firewall"]` and replacement of the Cloudflare subnet association | Bind `cftagent.route_table_key="cftagent"`. The real table already exists as `cus-prod-cftagent-rt`; do not create a second table or move its state |
| Binding checks fail with existing table names generated by the owning pattern | Omit `name` from existing-table bindings. The root preserves the original table name; a copied document name is not a rename/import instruction |
| Effective `appgw.routes.default` remains `0.0.0.0/0 -> VirtualAppliance` | Review/remove that existing inline key with `remove_route_keys={appgw=["default"]}`. This matrix deliberately has no App Gateway default UDR. Do not remove the precondition to retain it |
| Three readiness flags are false while routing is enabled | Confirm ownership, the forwarding path and OOB management before setting the corresponding flags true, or keep the cutover disabled |
| Existing extra blackholes remain on Gateway/App Gateway/shared tables | These are preserved base inputs, not newly required routes. Review them separately against Dan's matrix; remove only explicitly approved route keys |

The inline route collection can display `-`/`+` blocks inside a route table marked `~ update in-place`; that is not the same as replacing the table resource. Compare each route's name, prefix and next hop. Existing `blackhole_*` keys are reused for required destinations. The separate `-/+` Cloudflare association in this plan is an actual proposed reassociation and must disappear after correcting the key. Adding the `appcode` tag is metadata churn, not a route requirement. Reject unapproved VNet/table replacements or new ownership paths.

The updated `firewall_routing.tf` now reports exact failed **check names** without printing input values or bypassing restrictions. `appgw.no_default_route` identifies a retained default; `<role>.table_name_preserved` identifies an unsafe binding-name input; `management.no_inline_route_table` / `management.no_explicit_association` identify existing management routing that needs a separate decision. The presence of an unassociated `mgmt` table alone is not an error. Copy the updated root guard file as well as the reviewed tfvars object into Compeer, then re-plan. No state move/import is needed merely to correct a wrong binding in an unapplied plan.

An existing explicit subnet association retains its map key, with no second inline association added for the same subnet. Newly bound subnets use the pattern's existing derived-association mechanism. If a documented table exists in Azure but is absent from this backend, stop: identify its owner or import it through a reviewed handoff. Do not create a second table/resource owner. Inline routes and standalone `azurerm_route` must not manage the same table. [Pinned AzureRM behavior](https://github.com/hashicorp/terraform-provider-azurerm/blob/v4.81.0/website/docs/r/route_table.html.markdown).

## Internal Identity And Pilot Return Paths

The Identity root also contains the full disabled overlay; use its [portable example](../workspaces/platform-directory-services/firewall-routing.tfvars.example) when porting into the actual deployed Internal Identity owner. Select only the existing route-table keys; the document calls the internal table `cus-prod-intdc-rt`, but its Terraform key may differ. The overlay preserves its name/key, reuses existing route names by destination, adds default plus explicit hub and reviewed remote CIDRs through the Trust ILB, and switches BGP propagation off in the same configuration change. Unselected tables, VNet addresses, DCs and peering ownership are unchanged.

### Identity Table Selection Versus Destinations

`route_table_keys` selects **which Identity-owned tables are modified**. It is required and nonempty when Identity routing is enabled; it is not a list of destination VNets, DC IPs or tables owned by other workspaces. For this repository, the existing key is `to_firewall`, so merge these fields inside the existing Identity `firewall_routing` object:

```hcl
route_table_keys = ["to_firewall"]
remote_address_prefixes = {
  pilot_application = ["10.102.64.0/27"]
  # Add approved on-premises CIDRs when network/AD supplies the complete set.
}
static_route_set_reviewed = false # Keep false while that information is missing.
```

List multiple table keys only if multiple **existing Identity-owned tables** are explicitly in scope. Do not list `fw_trust`, `fw_untrust`, `fw_partner` or the pilot's table here: the firewall-interface tables remain in connectivity's `table_bindings`, and the pilot's own routes remain in its spoke deployment root. Hub and pilot CIDRs are destinations supplied through `hub_address_prefixes` and `remote_address_prefixes`, respectively. The Identity DC subnet is the source subnet using the selected table, not another required destination entry.

The `onprem_domain_services` label is an example, not a mandatory key. Omit it until approved CIDRs are available; do not use `onprem_domain_services=[]` when enabling. The remote map must contain reviewed nonempty prefix sets (currently the pilot entry), but a populated map alone does not establish completeness. Only set `static_route_set_reviewed=true` after network/AD confirms the entire required set, including whether any on-premises entries are needed.

Do not enable External Identity or change its tables as part of this cutover unless it is deployed and explicitly included. If internal and external subnets currently share a table, a table-level propagation change affects both: review/split that ownership and routing scope before proceeding. `static_route_set_reviewed=true` means the AD/network team approved the complete replacement set, not simply that the input map is nonempty.

The pilot blueprint already supports the required spoke-side controls. Review/merge these **fields inside the existing `spoke` object**; this is not a replacement tfvars file:

```hcl
# Documented Trust ILB frontend; confirm its live IP and forwarding health.
egress_next_hop_ip = "10.102.4.42"

# The blueprint already includes the platform hub prefixes in inspected routes.
# Add all OTHER relevant approved destinations, especially other peered spokes
# whose more-specific system routes otherwise outrank the default route.
inspection_address_prefixes = [
  "10.102.8.0/27", # Documented Internal Identity VNet; verify live.
  # Add other approved spoke/on-premises CIDRs where inspection is required.
]
```

Keep `bgp_route_propagation_enabled=false` on every applicable existing application/private-endpoint subnet and any other subnet being inspected. Confirm that the published platform hub address space is correct, and that subnet route tables contain the explicit hub/remote destinations plus the default via the ILB. Check NSG/PE policies and workload exemptions before assuming a UDR controls every service flow. The document's final note requires this spoke-side review; Hub routes alone do not finish it. Peering allows forwarded traffic but does not create these routes or Palo Alto policies.

## Remaining Palo Alto And Pilot Work

The Hub and Identity code covers **those owners' UDR changes**, not end-to-end acceptance. Do not copy `firewall_routing` into Palo Alto or central peering: the NIC subnets are part of the Hub VNet, and connectivity remains their route-table owner.

| Owner | Still Required Before Cutover |
| --- | --- |
| Palo Alto Terraform/firewall team | Reconcile deployed frontend/rules/probes, populate Trust backends with the actual forwarding NIC IP configurations, verify IP forwarding and HA, and configure Panorama policies, appliance routes and symmetric return paths |
| Pilot VNet owner | Set/confirm the existing root inputs shown above, review each subnet's BGP/UDRs and inspect the plan. Existing blueprint inputs support this; this routing change does not require another shared pattern release |
| Network/AD operations | Approve the management decision and complete Identity static routes, then validate allowed/denied traffic and DC/DNS/hybrid reachability during the coordinated window |

**Palo Alto sample discrepancies found during this review:** the repository's [sample tfvars](../workspaces/platform-palo-alto/terraform.tfvars) has a Trust LB name `platform-cus-prod-fw-ilb` and TCP/443 probes, while the document specifies `platform-cus-prod-fw-trust-ilb` and HTTP/80 `/unauth/php/health.php` with a 15-second interval. Its rule inputs also differ from the document's Source-IP persistence / Floating-IP-disabled settings. The current Palo Alto composition creates backend pools but does not declare NIC-to-backend-pool associations. These overlays do not fix those gaps. Confirm whether another deployed owner/manual configuration already supplies the associations; otherwise they must be implemented in the existing Palo Alto owner before enabling traffic routing. Do not blindly rename/recreate LBs or re-IP firewalls to make the old sample match the document. Review the live deployment with the firewall engineer first.

## Controlled Cutover And Rollback

1. Export the current route tables, inline route names, associations, effective routes and BGP settings. Record their real Terraform addresses and the backend owner. Back up state securely; do not commit state/plan exports. Record direct/OOB access and incident contacts.
2. Populate all placeholders and obtain Dan's management decision, Identity destination approval and full spoke inventory. Identify each temporary workaround. Confirm Trust ILB health/HA, Palo Alto policies/SNAT as applicable, symmetric return routes and peering forwarding. Do not call hybrid connectivity validated until its circuits/SD-WAN endpoints are actually ready and tested.
3. Run the local/mock suite below and full plans against the deployed owners. Inspect `firewall_routing_review` and every route/association change. Reject VNet/VM/RG/table replacement, unexpected subnet address changes, changed peering ownership or unapproved route deletion. This preparation does not modify the central attachment pattern/state.
4. Use the protected shared-hub gate already defined in [Network Attachment Operations](../network-attachments/README.md#shared-hub-gate), including core connectivity as a writer. Readiness flags do not serialize runs. Use the pilot as the first coordinated test; work with the network engineer on the precise Hub/pilot/Identity apply sequence and maintenance window. Terraform cannot make separate workspace applies atomic or guarantee a disruption-free association switch.
5. Apply the reviewed Hub route changes and pilot-side changes in that approved sequence. Test pilot-to-Identity DNS/application flows, expected outbound access, forbidden traffic and return paths. Then apply the reviewed Identity static routes/BGP-off configuration as one coordinated cutover, with AD-team validation of on-prem DC replication, DNS/Kerberos/LDAP and management access. Do not toggle Identity BGP off first while replacement paths are absent.
6. Verify route-table associations, BGP flags, live effective routes/next hops and Palo Alto session logs. Validate both allowed and denied traffic and HA failover. Capture a refresh/no-op plan and acceptance evidence. Plan/mock success alone is not operational acceptance.

**Rollback:** under the same gate/window, revert the approved routing configuration to the captured prior routes, associations and per-table BGP settings, then review/apply each owner's full rollback plan in the network engineer's sequence. Merely setting this overlay false returns to the current **base tfvars**, which might not equal the captured pre-cutover state if those inputs changed. Do not restore BGP blindly, run destroy, rename keys, use routine targeted applies or push an old whole-state snapshot to undo traffic changes. Keep OOB access and return-path testing available throughout.

## Local Verification

```bash
bash azure-terraform/alz-module-catalog/implementations/platform-lz/firewall-routing/test.sh
```

The suite uses real root/child configuration with mocked providers. It covers the matrix, five-table spoke selection, per-role BGP/default/blackhole behavior, inline route/name preservation, explicit workaround removal, stable associations, disabled backward compatibility, Identity static-route/BGP coordination and negative readiness/input cases. It explicitly verifies that onboarding another spoke leaves the effective firewall-interface blackhole sets/associations unchanged, optional audit metadata does not gate routing, and omitted on-premises entries cannot bypass static-route review. Empty/foreign Identity table selectors and empty remote-prefix entries are rejected. The supplied existing-Compeer failure scenario is reproduced, and corrected bindings preserve ten existing table keys/generated names and the Cloudflare association. Both merged root tfvars, portable examples and the disabled Compeer-specific example are tested, alongside the existing Phase 2 owner tests. These tests perform no Azure/HCP writes and do not prove deployed resource names, provider write permissions, appliance health or live connectivity.
