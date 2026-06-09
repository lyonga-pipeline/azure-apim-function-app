# NAT Gateway Associations Module

This module attaches a NAT Gateway to both public IPs and subnets when a root or pattern intentionally wants one combined association step.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Coupling | NAT Gateway modules can create the gateway, public IPs, and subnet associations together. | Association ownership is separated from NAT Gateway creation. |
| Flexibility | Some roots want one association module, others want split association resources. | This combined module exists for convenience while split modules are also available. |
| Drift | Subnet association changes should not alter the gateway itself. | Only association resources are managed here. |

## Design Intent

This module owns:

- NAT Gateway to public IP associations
- NAT Gateway to subnet associations

Use companion modules for:

- `nat-gateway`
- `nat-gateway-public-ip-association`
- `nat-gateway-subnet-association`
- `public-ip`
- `virtual-network`

## Why This Matters

NAT Gateway lifecycle and subnet attachment lifecycle are not the same. This module makes the association step explicit while still allowing a compact composition pattern.

