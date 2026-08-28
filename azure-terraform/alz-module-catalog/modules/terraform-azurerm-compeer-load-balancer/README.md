# Load Balancer Module

This module provides a reusable Azure Load Balancer pattern with frontend configuration, backend pools, probes, and rules modeled as maps.

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

Module-specific extension points: Frontend IPs, backend pools, probes, rules, NAT rules, outbound rules, tunnel interfaces, zones, and timeouts are modeled with stable keys for hub and workload patterns.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Input model | Listener and rule-style resources can become repeated blocks or environment-specific variants. | Frontends, backend pools, probes, and rules use stable map-based contracts. |
| Lifecycle | Public IPs, NIC associations, and subnet design are separate concerns. | This module owns the load balancer core and lets roots compose dependencies. |
| Reuse | Internal and external load balancers need different inputs. | Frontend configuration supports subnet or public IP references. |

## Design Intent

This module owns:

- Load Balancer resource
- Frontend IP configurations
- Backend address pools
- Health probes
- Load balancing rules

Use companion modules for:

- `public-ip`
- `network-interface-backend-address-pool-association`
- `virtual-network`
- `network-security-group`

## Why This Matters

Load balancing is shared infrastructure for several workload types. Keeping dependencies explicit avoids hidden coupling to network creation, public IP creation, or NIC lifecycle.

