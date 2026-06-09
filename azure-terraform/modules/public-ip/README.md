# Public IP Module

This module creates public IP resources separately from load balancers, NAT Gateways, Application Gateways, and other consumers.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Public endpoint ownership | Public IP creation can be embedded in consumer modules. | Public IP lifecycle is explicit and reusable. |
| DNS and SKU choices | Allocation, SKU, zones, and DNS labels may vary. | Public IP attributes are controlled through a focused contract. |
| Reuse | A public IP may be consumed by several platform patterns. | Consumers receive an explicit public IP ID. |

## Design Intent

This module owns:

- Public IP resource creation
- Allocation, SKU, tier, zones, and DNS label settings
- Tags and outputs

Use companion modules for:

- `nat-gateway-public-ip-association`
- `load-balancer`
- `application-gateway`

## Why This Matters

Public IPs are externally visible resources and often need separate approval, naming, and lifecycle control. This module prevents consumer modules from creating public exposure implicitly.

