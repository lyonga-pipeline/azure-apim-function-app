# Platform Hybrid Connectivity Root

## Overview

**What this deploys:** ExpressRoute (and VPN) circuits, gateways, and
connections — kept in its own workspace, separate from `platform-connectivity`,
because activating a circuit involves a carrier, BGP routing, and a cutover
window with a different approval chain than the hub VNet itself.

| Resource | Purpose |
|---|---|
| `azurerm_express_route_circuit` (module) | The circuit itself |
| `azurerm_virtual_network_gateway` (module) | ExpressRoute/VPN gateway in the hub's `GatewaySubnet` |
| `azurerm_virtual_network_gateway_connection` (module) | Circuit-to-gateway (or VPN) connection |
| `azurerm_route_server` (module) | Azure Route Server in the hub `RouteServerSubnet` |
| `terraform_data.expressroute_contract`, `.vpn_contract` | See below |
| `vpn_certificate_key_vault` (optional) | User-assigned identity + RBAC for VPN gateway certificate management against the shared platform Key Vault — see below |

**Route Server.** This pattern deploys Azure Route Server because its lifecycle
belongs with hybrid routing, while `platform-connectivity` owns the hub VNet
and the `RouteServerSubnet`. Pass the hub subnet ID directly, or let the
workspace wrapper resolve `subnet_key = "RouteServerSubnet"` from the
`platform-connectivity` outputs.

**`vpn_certificate_key_vault` — network engineer request.** VPN gateway
certificate management needs somewhere to store certs/secrets and an
identity to read them with. Set `vpn_certificate_key_vault.enabled = true`
to grant a user-assigned managed identity **Key Vault Certificates User** and
**Key Vault Secrets User** on the externally-owned shared platform Key Vault.
This pattern does not create that vault. Note: azurerm's VPN
gateway/connection resources have no native "read this certificate from Key
Vault" argument for a site-to-site gateway, so this wiring gives whatever
automation manages the gateway's certificates (rotation tooling, a pipeline
step) an identity to work with, rather than claiming a direct provider
integration that doesn't exist for this resource type.

**The two `terraform_data` contracts — why "enabled" isn't just a boolean:**
both `expressroute_posture` and `vpn_posture` require **both** the actual
resources (circuit, gateway, connection) **and** the sign-offs (provider
design reference, BGP/routing approval, cutover-window approval) before
Terraform will apply anything. This exists so a half-promoted hybrid
connection — resources declared but approvals missing, or approvals claimed
but resources never declared — fails the plan loudly instead of quietly
going live without the required sign-off. See `tests/contracts.tftest.hcl`
for the exact pass/fail scenarios both contracts cover.

---

This optional root is the placeholder for Compeer's on-premises connectivity path. Use it for ExpressRoute circuits, the ExpressRoute virtual network gateway, and circuit-to-gateway connections after the carrier/provider design is approved.

Keep this root in a separate HCP workspace from `platform-connectivity`. The hub VNet and subnets are a platform network baseline, while ExpressRoute circuit activation, provider coordination, BGP routing, and cutover windows have a separate lifecycle and approval chain.

The `platform-connectivity` hub VNet must expose a `GatewaySubnet` before enabling the gateway here. The current test tfvars include that subnet but do not deploy the gateway or circuit by default.

Leave `expressroute_posture.enabled = false` and the maps in `terraform.tfvars` empty for smoke tests. This keeps the root cost-free while still documenting that ExpressRoute is the expected production on-premises path. `terraform.tfvars.example` remains as a reference, but HCP workspaces should use the autoloaded `terraform.tfvars`.

When `expressroute_posture.enabled = true`, Terraform requires at least one circuit, gateway public IP, ExpressRoute gateway, and connection. It also requires a provider design reference, BGP/routing approval, and cutover-window approval so partial hybrid connectivity cannot be promoted accidentally.
