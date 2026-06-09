# NAT Gateway Subnet Association Module

This module attaches a NAT Gateway to a subnet as a separate lifecycle resource.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Network ownership | NAT Gateway subnet attachments can be buried in the NAT Gateway module. | The subnet association is explicit and independently managed. |
| Environment variance | Different environments may attach different subnets. | Roots pass the exact subnet ID per environment. |
| Blast radius | Subnet attachment changes should not alter gateway creation. | Only the association changes. |

## Design Intent

This module owns:

- NAT Gateway to subnet association

Use companion modules for:

- `nat-gateway`
- `virtual-network`
- `route-table`

## Why This Matters

Subnet routing and outbound egress ownership usually sit with platform and network teams. Keeping the association separate prevents the NAT Gateway module from hiding environment-specific networking decisions.

