# NSG Subnet Association Module

This module associates a Network Security Group with a subnet separately from VNet, subnet, and NSG creation.

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

Module-specific extension points: Subnet-to-NSG association is separate from NSG creation so network ownership and security-rule ownership can evolve independently.

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

