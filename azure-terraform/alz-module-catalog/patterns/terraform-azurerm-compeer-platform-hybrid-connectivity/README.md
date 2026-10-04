# Platform Hybrid Connectivity Root

## Overview

**What this deploys:** Azure Route Server for the SDWAN handoff and, when
approved later, ExpressRoute circuits, gateways, and connections. It stays in
its own workspace, separate from `platform-connectivity`, because activating
hybrid routing involves provider coordination, BGP routing, and cutover
approval with a different lifecycle than the hub VNet itself.

| Resource | Purpose |
|---|---|
| `azurerm_express_route_circuit` (module) | The circuit itself |
| `azurerm_virtual_network_gateway` (module) | ExpressRoute gateway in the hub's `GatewaySubnet` |
| `azurerm_virtual_network_gateway_connection` (module) | Circuit-to-gateway connection |
| `azurerm_route_server` (module) | Azure Route Server in the hub `RouteServerSubnet` |
| `terraform_data.expressroute_contract` | See below |

**Route Server.** This pattern deploys Azure Route Server because its lifecycle
belongs with hybrid routing, while `platform-connectivity` owns the hub VNet
and the `RouteServerSubnet`. Pass the hub subnet ID directly, or let the
workspace wrapper resolve `subnet_key = "RouteServerSubnet"` from the
`platform-connectivity` outputs.

**The `terraform_data` contract — why "enabled" isn't just a boolean:**
`expressroute_posture` requires **both** the actual resources (circuit,
gateway, connection) **and** the sign-offs (provider design reference,
BGP/routing approval, cutover-window approval) before Terraform will apply
anything. This exists so a half-promoted hybrid connection — resources
declared but approvals missing, or approvals claimed but resources never
declared — fails the plan loudly instead of quietly going live without the
required sign-off. See `tests/contracts.tftest.hcl` for the exact pass/fail
scenarios.

---

This optional root is the placeholder for Compeer's on-premises connectivity path. Use it now for Route Server/SDWAN routing prep, then for ExpressRoute circuits, the ExpressRoute virtual network gateway, and circuit-to-gateway connections after the carrier/provider design is approved.

Keep this root in a separate HCP workspace from `platform-connectivity`. The hub VNet and subnets are a platform network baseline, while ExpressRoute circuit activation, provider coordination, BGP routing, and cutover windows have a separate lifecycle and approval chain.

The `platform-connectivity` hub VNet must expose `RouteServerSubnet` for the current deployment and `GatewaySubnet` before enabling the ExpressRoute gateway later.

Leave `expressroute_posture.enabled = false` with the ExpressRoute maps empty until the provider/circuit details are approved. Route Server can still be deployed independently for the SDWAN handoff. `terraform.tfvars.example` remains as a reference, but HCP workspaces should use the autoloaded `terraform.tfvars`.

When `expressroute_posture.enabled = true`, Terraform requires at least one circuit, gateway public IP, ExpressRoute gateway, and connection. It also requires a provider design reference, BGP/routing approval, and cutover-window approval so partial hybrid connectivity cannot be promoted accidentally.
