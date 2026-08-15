# Platform ALZ Implementation

This root shows how the staged catalog modules and compositions are consumed for a platform landing zone. It mirrors the existing `landing-zones/net-new-hub-spoke` delivery model, but lives beside the catalog so teams can review the intended end-to-end consumption pattern before modules are promoted to the HCP private registry.

## Source Strategy

The platform slices are consumed as local catalog patterns because the pattern modules themselves are not published HCP modules yet:

- `../../patterns/terraform-azurerm-compeer-global-governance`
- `../../patterns/terraform-azurerm-compeer-subscription-vending`
- `../../patterns/terraform-azurerm-compeer-platform-management`
- `../../patterns/terraform-azurerm-compeer-platform-connectivity`
- `../../patterns/terraform-azurerm-compeer-platform-identity`
- `../../patterns/terraform-azurerm-compeer-platform-hybrid-connectivity`
- `../../patterns/terraform-azurerm-compeer-palo-alto-hub`
- `../../patterns/terraform-cloudflare-compeer-edge-baseline`

When a pattern is promoted, replace the local source with its HCP registry address and a pinned version. Underlying Compeer modules that already have HCP versions should retain the versions listed in `modules.txt` when they are called directly or republished inside the patterns.

## Deployment Notes

- Keep `subscription_vending.vending_enabled = false` until the billing scope, invoice section, and management-group placement permissions are confirmed in the client tenant.
- Defender/SOC posture is modeled but disabled by default. Enabling paid Defender plans, Sentinel, or data collection rules should require SOC approval.
- Palo Alto is modeled as a route/DNS contract first. VM-Series compute stays disabled until Panorama ownership, license model, bootstrap storage, and ExpressRoute routing are approved.
- Cloudflare edge controls are disabled by default because the Cloudflare account and token lifecycle are owned outside Azure.
- Workload spoke deployment is disabled by default; platform ALZ should provide contracts and shared services while workload teams own workload resource lifecycles.

Copy `terraform.tfvars.example` to `terraform.tfvars` in an environment-specific root, replace subscription IDs and billing scope values, and then enable only the slices approved for that rollout.
