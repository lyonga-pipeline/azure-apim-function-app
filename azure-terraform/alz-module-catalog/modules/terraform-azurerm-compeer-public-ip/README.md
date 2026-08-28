# Public IP Module

This module creates public IP resources separately from load balancers, NAT Gateways, Application Gateways, and other consumers.

## Reusability and Extensibility

This module is designed as a reusable resource building block for Compeer platform and workload patterns:

- Resource-scoped ownership: the module models the Azure resource boundary, not a single application, environment, or landing-zone root.
- Pattern-ready interface: enterprise decisions such as naming, network placement, diagnostics, RBAC, private endpoints, and policy posture stay in the consuming pattern or root.
- Optional capability surface: optional Azure features are exposed through typed inputs, objects, maps, and empty defaults so consumers can enable them without forking the module.
- Stable identity for repeatable configuration: repeatable nested configuration uses keyed maps where identity matters, reducing unrelated replacement when an item is added or removed.
- Lifecycle-aware defaults: inputs favor provider-supported in-place updates and avoid generated names, positional indexes, or hidden defaults that create unnecessary replacement.
- Composition-ready outputs: IDs, names, endpoint details, and other downstream attributes are exported so dependent modules and HCP workspaces do not need to reconstruct implementation details.
- Backward-compatible growth: new capabilities should be added with optional inputs and sensible defaults; breaking input or output changes should be versioned deliberately.
- Validation focus: consumers should test create, no-change plan, in-place updates, optional feature add/remove, expected replacement cases, and destroy behavior before broad reuse.

Module-specific extension points: SKU, tier, zones, labels, prefix, DDoS posture, IP tags, and timeouts are configurable so public IPs can be reused by Bastion, Route Server, gateways, and appliances.

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

