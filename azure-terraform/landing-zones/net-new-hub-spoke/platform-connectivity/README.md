# Platform Connectivity Root

This root creates shared network foundations for a landing-zone environment.

It keeps address allocation explicit in the root input contract. The VNet module receives VNet address spaces and typed subnet maps, then outputs `subnet_ids` keyed by the same subnet purpose keys.

NSGs, route tables, Private DNS zones, and VNet links are composed outside the VNet base module so networking ownership remains visible.

The current smoke-test tfvars deploy hub networking primitives only. They include reserved `AzureFirewallSubnet` and `GatewaySubnet` address space so the hub is ready for Azure Firewall and ExpressRoute/VPN gateway enablement, but they do not deploy those paid services by default.

Integrate these enterprise controls into this root when approved:

- Azure Firewall and Firewall Policy using the `azure-firewall` and `firewall-policy` modules.
- DDoS Network Protection using the `ddos-protection-plan` module, then associate the plan to production VNets.
- Azure DNS Private Resolver using the `private-dns-resolver` module for inbound on-prem queries and outbound conditional forwarding.
- NAT Gateway only for explicit outbound scenarios where Azure Firewall is not the egress authority.

Keep ExpressRoute circuit and gateway lifecycle in `platform-hybrid-connectivity`; consume the hub `GatewaySubnet` output there.
