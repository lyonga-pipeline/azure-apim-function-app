# NSG Subnet Association Module

This module associates a Network Security Group with a subnet separately from VNet, subnet, and NSG creation.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Subnet security | NSG attachment can be embedded in the VNet module. | Subnet association is its own lifecycle. |
| Network ownership | Shared subnets may be governed centrally. | Roots pass resolved subnet and NSG IDs explicitly. |
| Change scope | NSG changes should not force subnet recreation. | Only the association resource is managed here. |

## Design Intent

This module owns:

- Subnet to NSG association

Use companion modules for:

- `virtual-network`
- `network-security-group`

## Why This Matters

Subnet security may change more often than subnet address space. This module keeps those decisions visible and independently promotable.

