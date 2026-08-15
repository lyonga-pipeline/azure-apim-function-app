# Platform ALZ Implementation

This root shows the end-to-end platform landing-zone composition for the new ALZ path. It mirrors the delivery model in the existing landing-zone implementation but keeps the module references aligned to the catalog and to the registry versions recorded in `modules.txt`.

## Source strategy

The implementation prefers published Terraform Cloud modules where the module already exists in the registry. For modules that are not yet published, it falls back to local catalog patterns in this repository.

The current pattern references are:

- `../../patterns/terraform-azurerm-compeer-global-governance`
- `../../patterns/terraform-azurerm-compeer-subscription-vending`
- `../../patterns/terraform-azurerm-compeer-platform-management`
- `../../patterns/terraform-azurerm-compeer-platform-connectivity`
- `../../patterns/terraform-azurerm-compeer-platform-identity`
- `../../patterns/terraform-azurerm-compeer-platform-hybrid-connectivity`
- `../../patterns/terraform-azurerm-compeer-palo-alto-hub`
- `../../patterns/terraform-cloudflare-compeer-edge-baseline`
- `../../patterns/terraform-azurerm-compeer-network-peering`
- `../../patterns/terraform-azurerm-compeer-workload-spoke`

Where the module already appears in `modules.txt` with a released registry version, keep that pinned version in the source statement when the pattern is promoted. Where the module does not yet exist, keep the local path until the registry module is available and reviewed.

## End-to-end composition

This implementation follows the same platform order used by the existing `net-new-hub-spoke` landing-zone path:

1. governance and policy baseline
2. subscription vending
3. platform management
4. platform connectivity
5. platform identity
6. hybrid connectivity
7. optional Palo Alto hub
8. optional Cloudflare edge baseline
9. workload spoke and network peering

This keeps the design aligned with the real deployment order used by the net-new hub/spoke roots while recording which platform slices are still local-only pending registry publication.

## Deployment notes

- Keep `subscription_vending.vending_enabled = false` until the billing scope, invoice section, and management-group placement permissions are confirmed for the tenant.
- Defender/SOC posture is modeled but disabled by default.
- Palo Alto is modeled as a route/DNS contract first; compute remains disabled until license and operational ownership are approved.
- Cloudflare edge controls stay disabled by default unless Cloudflare ownership and API access are approved.
- Workload spoke deployment is intentionally disabled by default so the platform ALZ can provide the shared service contract while workload owners own application resources.

Copy `terraform.tfvars.example` to `terraform.tfvars` in an environment-specific root, update the subscription IDs and billing-scope values, and only enable the slices approved for that rollout.
