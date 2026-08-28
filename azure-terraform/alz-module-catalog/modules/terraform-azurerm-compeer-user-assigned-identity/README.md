# User Assigned Identity Module

This module creates user-assigned managed identities that can be shared by applications, private resources, Key Vault references, and automation patterns.

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

Module-specific extension points: Identities are keyed and output with principal, client, and tenant attributes for reusable RBAC, CMK, workload identity, and automation patterns.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Identity lifecycle | Identities can be created inside each workload module. | Identity lifecycle is explicit and reusable. |
| Access assignment | Identity creation and role assignment can be mixed. | This module creates identity only; `role-assignments` grants access. |
| Reuse | The same identity may be used by app, storage, Key Vault, or APIM integration. | Outputs provide stable identity IDs for composition. |

## Design Intent

This module owns:

- User-assigned managed identity creation
- Tags and identity outputs

Use companion modules for:

- `role-assignments`
- `function-app`
- `web-app`
- `key-vault`
- `storage-account-customer-managed-key`

## Why This Matters

Identity is a shared security primitive. Creating it separately prevents workload modules from hiding access boundaries or recreating identities unnecessarily.

