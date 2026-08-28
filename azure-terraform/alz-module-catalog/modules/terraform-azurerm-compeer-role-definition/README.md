# Role Definition Module

This module creates custom Azure role definitions separately from role assignments and resource modules.

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

Module-specific extension points: Custom-role permissions are modeled as input data and outputs expose role IDs and scope details for governance and RBAC patterns.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Access design | Custom permissions can be mixed with assignment logic. | Role definition and role assignment are separate lifecycles. |
| Governance | Permissions need careful review before assignment. | Permissions are modeled as explicit action and data action sets. |
| Reuse | One custom role may be assigned to many principals. | The role definition can be created once and consumed by `role-assignments`. |

## Design Intent

This module owns:

- Custom role definition
- Permission actions and data actions
- Assignable scopes
- Optional stable role definition ID

Use companion modules for:

- `role-assignments`
- Resource modules that expose scope IDs

## Why This Matters

Role definitions define what access means. Role assignments define who receives it. Separating the two supports least privilege review and cleaner access governance.

