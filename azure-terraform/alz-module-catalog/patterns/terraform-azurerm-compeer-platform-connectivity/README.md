# Platform Connectivity Root

This root creates shared network foundations for a landing-zone environment.

It keeps address allocation explicit in the root input contract. The VNet module receives VNet address spaces and typed subnet maps, then outputs `subnet_ids` keyed by the same subnet purpose keys.

NSGs, route tables, Private DNS zones, and VNet links are composed outside the VNet base module so networking ownership remains visible.

The current smoke-test tfvars deploy hub networking primitives only. They include reserved `GatewaySubnet` address space for ExpressRoute/VPN gateway enablement and dedicated Palo Alto trust, untrust, and management subnet reservations. They do not deploy paid firewall, gateway, DNS resolver, or DDoS services by default.

Palo Alto is codified as a route, subnet, bootstrap, HA, and management contract in `palo_alto`. When `palo_alto.enabled = true`, every `VirtualAppliance` route next hop must match an approved Palo Alto private IP, and the declared Palo Alto subnet keys must exist in the hub VNet input. This lets the landing zone enforce the intended egress architecture while keeping VM-Series/Panorama deployment in a separate approved vendor lifecycle.

DNS is codified through `dns_resolution`. The Phase 1 default is `dc-forwarders`, pointing hub VNet DNS to the approved domain-controller resolvers over ExpressRoute. Switch to `private-resolver` only after the NET-27 decision is approved and the resolver modules are intentionally enabled.

Optional `public_ips` and `load_balancers` expose the deployable hooks for Palo Alto egress and HA load-balancing controls from the ALZ workbook:

| Component | Root input | Baseline posture |
| --- | --- | --- |
| `NET-13` Internal Load Balancer - Trust | `load_balancers` | Empty map, no resource created |
| `NET-14` Internal Load Balancer - Untrust | `load_balancers` | Empty map, no resource created |
| `NET-37` Public IPs for firewall egress | `public_ips` | Empty map, no resource created |

Populate those maps only after the Palo Alto HA, bootstrap, Panorama/Strata onboarding, routing, and cost-ownership design is approved.

Integrate these enterprise controls into this root when approved:

- Palo Alto VM-Series/Panorama modules or marketplace deployment automation after the vendor design, licensing, HA, bootstrap, and operations model are approved.
- Azure Firewall and Firewall Policy only if Compeer chooses Azure Firewall for a specific landing-zone path.
- DDoS Network Protection using the `ddos-protection-plan` module, then associate the plan to production VNets.
- Azure DNS Private Resolver using the `private-dns-resolver` module for inbound on-prem queries and outbound conditional forwarding.
- NAT Gateway only for explicit outbound scenarios where the approved egress authority is not used.

Keep ExpressRoute circuit and gateway lifecycle in `platform-hybrid-connectivity`; consume the hub `GatewaySubnet` output there.
