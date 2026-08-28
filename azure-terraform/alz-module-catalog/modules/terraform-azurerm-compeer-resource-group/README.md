# Resource Group Module

This module creates the resource group boundary that application and platform roots compose with reusable resource modules.

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

Module-specific extension points: The module owns only the resource group boundary and exposes ID, name, and location for any resource pattern that composes into it.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Boundary clarity | Resource groups can be created inline in application stacks. | Resource group ownership is explicit and reusable. |
| Tagging | Tags can vary across resources if not normalized. | The module accepts the merged enterprise tag map from `platform-tags`. |
| Composition | Application modules should not assume they own the resource group. | Roots pass `resource_group_name` into child modules. |

## Design Intent

This module owns:

- Resource group creation
- Location
- Tags

Use companion modules for:

- `platform-tags`
- All workload modules that deploy into the resource group

## Why This Matters

Resource groups are lifecycle and ownership boundaries. Keeping them explicit makes environment isolation, RBAC, tagging, and cleanup easier to reason about.

