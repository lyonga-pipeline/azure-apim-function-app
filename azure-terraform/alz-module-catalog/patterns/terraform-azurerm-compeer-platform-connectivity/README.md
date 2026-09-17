# Platform Connectivity Root

## Overview

**What this deploys:** the hub VNet, subnets, and the two enforcement
contracts (Palo Alto routing, DNS resolution mode) that other patterns
(`platform-hybrid-connectivity`, `palo-alto-hub`, `directory-services`) rely
on being correct before they run. Bastion and DDoS Protection Plan are wired
but left **off by default** — this is a deliberate cost-safe baseline (each
is a paid, always-on Azure service), not an oversight; see
`implementations/platform-lz/PATTERN-REFERENCE.md` §8.

**Removed, not just left off: generic `public_ips`, `route_server`,
`route_server_public_ips`, `private_dns_resolver`.** Network engineer
review confirmed none of these are needed for this environment — a public
IP is declared alongside the specific resource that needs it (Bastion,
Palo Alto, a load balancer frontend via a direct `public_ip_address_id`),
Route Server isn't part of this design, and DNS resolution uses conditional
forwarders on the existing domain controllers, not Azure DNS Private
Resolver. Leaving the module/variable in place with an empty default would
mean a later tfvars change could deploy real infrastructure that was
already reviewed and rejected, so the code itself was removed rather than
just zeroed out — see `implementations/platform-lz/PATTERN-REFERENCE.md` §8
for the full writeup.

| Resource | Purpose |
|---|---|
| `module.virtual_network` | Hub VNet + typed subnet map (`subnet_ids` keyed by purpose) |
| `azurerm_network_watcher.watcher` | Network Watcher for the hub |
| `module.private_dns_zones` / `_hub_links` / `_zones_resource_group` | The privatelink zone catalogue — see below |
| `terraform_data.palo_alto_route_contract` | See below |
| `terraform_data.dns_resolution_contract` | See below |

**Private DNS zones are reused from the existing landing zone, not
created.** Confirmed: the privatelink zones this platform needs
(`privatelink_zone_catalogue`) already exist elsewhere — this pattern only
creates the hub VNet link to each, via `existing = true` (with
`resource_group_name` pointing at the real shared DNS resource group) on
every `private_dns_zones` entry. The real tfvars carries a placeholder
resource group name (`net-ncus-plfc-rg`) pending confirmation of the actual
name — **flagged, not fabricated**, since it's an assumption about the
existing landing zone's naming, not a value this repo can know on its own.

The pattern also supports the opposite case — creating zones fresh, in
their own dedicated resource group (`private_dns_zones_resource_group`,
default name `<naming.resource_group>-dns`) — for a zone that genuinely
doesn't exist yet (omit `existing`, or set it to `false`). Not the current
real-tfvars path, but available if a future zone needs it. See
`tests/defaults.tftest.hcl` for both paths.

**The two `terraform_data` contracts — why enforcement lives here instead of
just in tfvars comments:** both encode an architectural decision that's easy
to violate by accident in a plain map of route/subnet inputs, so Terraform
checks it at plan time rather than relying on code review to catch it:

- **`palo_alto_route_contract`** — when `palo_alto.enabled = true`, every
  `VirtualAppliance` route next-hop must match an approved Palo Alto private
  IP, and every subnet key `palo_alto` declares must actually exist in the
  hub VNet. This keeps egress routing and the firewall's actual subnet
  layout from silently drifting apart.
- **`dns_resolution_contract`** — enforces that `dc-forwarders` (the only
  mode this pattern supports; the network engineer confirmed a
  resolver-based path isn't needed here) has at least one DNS server IP
  configured when enabled, so a half-configured DNS posture fails the plan
  instead of producing broken name resolution at apply time.

See `tests/contracts.tftest.hcl` for the exact pass/fail scenarios both
contracts cover.

---

This root creates shared network foundations for a landing-zone environment.

It keeps address allocation explicit in the root input contract. The VNet module receives VNet address spaces and typed subnet maps, then outputs `subnet_ids` keyed by the same subnet purpose keys.

NSGs, route tables, Private DNS zones, and VNet links are composed outside the VNet base module so networking ownership remains visible.

The current smoke-test tfvars deploy hub networking primitives only. They include reserved `GatewaySubnet` address space for ExpressRoute/VPN gateway enablement and dedicated Palo Alto trust, untrust, and management subnet reservations. They do not deploy paid firewall, gateway, DNS resolver, or DDoS services by default.

**DDoS Protection stays off — a real cost/capability gap, not just a
deferred decision.** The `ddos_protection_plan` module only wraps
`azurerm_network_ddos_protection_plan` — Azure's **DDoS Network
Protection**, a flat ~$2,944/month covering up to 100 public IPs. Azure's
actual low-cost tier, **DDoS IP Protection** (~$199/month per protected
public IP — far cheaper for a hub with only a handful of public IPs), has
**no Terraform support today**: confirmed via an open, unresolved
`hashicorp/terraform-provider-azurerm` GitHub issue (#27658, "Support for
DDOS IP Protection for azurerm_public_ip resource"). `azurerm_public_ip`'s
existing `ddos_protection_mode`/`ddos_protection_plan_id` arguments only
associate a public IP with a **Network Protection** plan, not the newer
per-IP tier. Decision: leave DDoS off entirely for now, rather than enable
the ~$2,944/month plan just to have something on, or claim IP Protection
coverage Terraform can't actually deliver yet. Revisit once the provider
adds IP Protection support, or if the Network Protection cost becomes
acceptable.

Palo Alto is codified as a route, subnet, bootstrap, HA, and management contract in `palo_alto`. When `palo_alto.enabled = true`, every `VirtualAppliance` route next hop must match an approved Palo Alto private IP, and the declared Palo Alto subnet keys must exist in the hub VNet input. This lets the landing zone enforce the intended egress architecture while keeping VM-Series/Panorama deployment in a separate approved vendor lifecycle.

DNS is codified through `dns_resolution`. `dc-forwarders` — pointing hub VNet DNS to the approved domain-controller resolvers over ExpressRoute — is the only mode this pattern supports; the resolver-based path (Azure DNS Private Resolver) was removed after network engineer review confirmed it isn't needed for this environment.

Optional `load_balancers` expose the deployable hooks for Palo Alto egress and HA load-balancing controls from the ALZ workbook (a frontend can take a direct `public_ip_address_id` if it needs one — declared alongside the load balancer itself, not sourced from a generic hub-level pool):

| Component | Root input | Baseline posture |
| --- | --- | --- |
| `NET-13` Internal Load Balancer - Trust | `load_balancers` | Empty map, no resource created |
| `NET-14` Internal Load Balancer - Untrust | `load_balancers` | Empty map, no resource created |

Populate that map only after the Palo Alto HA, bootstrap, Panorama/Strata onboarding, routing, and cost-ownership design is approved.

Integrate these enterprise controls into this root when approved:

- Palo Alto VM-Series/Panorama modules or marketplace deployment automation after the vendor design, licensing, HA, bootstrap, and operations model are approved.
- Azure Firewall and Firewall Policy only if Compeer chooses Azure Firewall for a specific landing-zone path.
- DDoS Network Protection using the `ddos-protection-plan` module, then associate the plan to production VNets.
- NAT Gateway only for explicit outbound scenarios where the approved egress authority is not used.

(Public IPs, Route Server, and Azure DNS Private Resolver are **not** on this
list — network engineer review confirmed none are needed for this
environment, and the code was removed rather than left as an unused hook.)

Keep ExpressRoute circuit and gateway lifecycle in `platform-hybrid-connectivity`; consume the hub `GatewaySubnet` output there.
