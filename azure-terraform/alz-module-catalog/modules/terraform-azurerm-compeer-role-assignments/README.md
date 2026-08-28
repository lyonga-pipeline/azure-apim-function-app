# Role Assignments Module

This companion module manages Azure RBAC role assignments separately from base resources.

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

Module-specific extension points: Assignments are keyed by logical name and support deterministic names, role ID or name, conditions, principal type, delegated identity, and stable outputs.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Access lifecycle | Access can be embedded into Key Vault, Storage, App, or SQL modules. | RBAC assignments are separate and can be changed without touching base resources. |
| Reuse | Different principals need access across different scopes. | Uses a map of assignments with stable keys. |
| Governance | Human, workload, and platform access may need different approval paths. | Access changes can be reviewed and promoted independently. |

## Design Intent

Use this module for Azure RBAC assignments across subscriptions, resource groups, and resources. Keep access changes explicit in the application root or governance stack.

## Why This Matters

Access control changes frequently and often has different owners than infrastructure creation. Keeping RBAC separate helps prevent drift and avoids rebuilding base resources for access changes.
