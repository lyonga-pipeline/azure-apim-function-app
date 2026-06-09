# NAT Gateway Module

This module manages the NAT Gateway resource as a focused egress component.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Core lifecycle | NAT gateway, public IPs, and subnet associations can be bundled together. | NAT Gateway is separated from public IP and subnet association modules. |
| Zone support | Reviewed pattern showed partially implemented zone support. | Exposes `zones` directly on the NAT Gateway resource. |
| Attachments | Subnet ownership can belong to a network team while NAT ownership differs. | Subnet and public IP associations are companion modules. |

## Design Intent

This module owns:

- NAT Gateway resource
- SKU
- Idle timeout
- Availability zones
- Tags

Use companion modules for:

- `nat-gateway-public-ip-association`
- `nat-gateway-subnet-association`
- `public-ip`

## Why This Matters

Egress architecture often spans network, security, and application ownership. Separating the gateway from public IP and subnet attachments makes ownership clearer and reduces the blast radius of subnet-level changes.

