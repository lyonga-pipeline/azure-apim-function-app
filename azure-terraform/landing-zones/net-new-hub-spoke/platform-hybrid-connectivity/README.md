# Platform Hybrid Connectivity Root

This optional root is the placeholder for Compeer's on-premises connectivity path. Use it for ExpressRoute circuits, the ExpressRoute virtual network gateway, and circuit-to-gateway connections after the carrier/provider design is approved.

Keep this root in a separate HCP workspace from `platform-connectivity`. The hub VNet and subnets are a platform network baseline, while ExpressRoute circuit activation, provider coordination, BGP routing, and cutover windows have a separate lifecycle and approval chain.

The `platform-connectivity` hub VNet must expose a `GatewaySubnet` before enabling the gateway here. The current test tfvars include that subnet but do not deploy the gateway or circuit by default.

Leave the maps in `terraform.tfvars.example` empty for smoke tests. Populate them only when the service provider, peering location, bandwidth, SKU, BGP design, and routing approvals are known.
