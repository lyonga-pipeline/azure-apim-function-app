# Diagnostic Settings Module

This companion module manages Azure Monitor diagnostic settings for any supported target resource.

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

Module-specific extension points: The module is target-resource agnostic and supports keyed log and metric categories plus Log Analytics, Storage, Event Hub, partner, destination-type, and timeout options.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Observability lifecycle | Diagnostics can be embedded into every base resource module. | Diagnostics are managed separately so telemetry routing can change independently. |
| Routing | Log Analytics, Storage, Event Hub, and partner destinations can vary by environment. | Destination IDs are explicit inputs rather than hidden inside base modules. |
| Drift handling | Reviewed patterns showed diagnostic `ignore_changes` workarounds. | This module keeps diagnostic routing visible in plan output by default. |

## Design Intent

Use this module to attach logs and metrics to platform or workload resources after the base resource exists.

## Why This Matters

Telemetry routing is often owned by operations or platform observability teams. Keeping diagnostics separate avoids changing the base resource module every time logging destinations or retention expectations change.

