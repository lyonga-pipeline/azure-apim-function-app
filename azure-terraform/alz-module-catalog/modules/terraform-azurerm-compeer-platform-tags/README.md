# Platform Tags Module

This module normalizes enterprise tags so application and platform roots can apply a consistent tag set without copying tag merge logic everywhere.

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

Module-specific extension points: Tag normalization is centralized while additional tags can be layered by consuming platform or workload roots.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Tag consistency | Each module or app root may build tags differently. | Standard tags are generated once and reused. |
| Governance | Required ownership, cost, and classification metadata can be missed. | Environment, application, owner, repo, workspace, recovery, cost, data, and compliance tags are modeled. |
| Extensibility | Custom tags can overwrite or conflict unpredictably. | `additional_tags` are merged after normalized defaults. |

## Design Intent

This module owns:

- Standard tag normalization
- Optional operational metadata tags
- Additional tag merge behavior
- A single `tags` output for resource modules

Use companion modules for:

- All resource modules that accept `tags`

## Why This Matters

Tags are part of cost, compliance, and ownership governance. Centralizing tag construction reduces drift between teams and keeps module contracts lighter.

