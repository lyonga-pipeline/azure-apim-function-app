# VNet Peering Module

This module manages virtual network peering as a separate network relationship between two VNets.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Network relationship | Peering can be embedded in the VNet module. | Peering is explicit and managed separately. |
| Ownership | Hub, spoke, and app networks may be owned by different teams. | Roots pass resolved VNet IDs and peering flags. |
| Environment variance | Shared and app-specific networks may differ by environment. | Peering decisions remain in the root or pattern module. |

## Design Intent

This module owns:

- VNet peering relationship
- Traffic forwarding and gateway access flags
- Remote VNet reference

Use companion modules for:

- `virtual-network`
- `route-table`
- `private-dns-vnet-link`

## Why This Matters

Peering is a connectivity decision with cross-team impact. Keeping it separate prevents VNet creation from hiding hub/spoke routing assumptions.

