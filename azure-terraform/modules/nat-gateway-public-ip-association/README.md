# NAT Gateway Public IP Association Module

This module attaches public IP resources to a NAT Gateway as a separate lifecycle concern.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Gateway lifecycle | Public IP attachment can be hidden inside NAT Gateway creation. | Public IP association is explicit. |
| Scaling | Additional outbound IPs may be added later. | Public IP associations can change without changing the gateway resource. |
| Ownership | Public IPs may be governed separately. | The root passes resolved NAT Gateway and public IP IDs. |

## Design Intent

This module owns:

- NAT Gateway to public IP association

Use companion modules for:

- `nat-gateway`
- `public-ip`

## Why This Matters

Outbound IP scaling should not require a NAT Gateway module redesign. This small module keeps that relationship independent and reviewable.

