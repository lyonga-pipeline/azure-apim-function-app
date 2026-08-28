# Virtual Network Module

This module manages virtual networks and subnets with stable map-based subnet keys.

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

Module-specific extension points: VNet settings, DDoS attachment, DNS servers, encryption, flow timeout, VNet policies, subnets, delegations, service endpoints, IP pools, and subnet timeouts are configurable with stable subnet keys.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Subnet modeling | Subnets are often modeled as ordered lists or embedded inside broad landing-zone modules. | Uses `map(object(...))` for subnets so each subnet has a stable key and less plan churn. |
| Ownership | Network, subnet attachments, NSGs, routes, and private DNS can be bundled together. | VNet and subnets are kept separate from NSG, route table, NAT, and DNS associations. |
| Outputs | App modules need service-specific subnet IDs. | Outputs a `subnet_ids` map keyed by subnet name. |

## Design Intent

This module owns:

- Virtual network resource
- Subnet resources
- Address spaces and DNS server configuration
- Service endpoints and delegations per subnet

Use companion modules for:

- `network-security-group`
- `nsg-subnet-association`
- `route-table`
- `subnet-route-table-association`
- `nat-gateway-subnet-association`
- `vnet-peering`
- `private-dns-vnet-link`

## Why This Matters

Virtual network lifecycle and attachment lifecycle are often owned by different teams. Keeping associations separate prevents broad network modules from becoming the place where every application-specific decision is hidden.

