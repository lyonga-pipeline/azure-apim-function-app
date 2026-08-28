# Storage Account Module

This module is the Terraform 2.0 replacement pattern for reviewed storage account configurations. It keeps the account lifecycle focused on the storage account while child objects and governance controls are handled by companion modules.

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

Module-specific extension points: Account-level identity, CMK, network rules, private-link access, Blob, Queue, File, Azure Files auth, routing, SAS, immutability, static website, endpoints, and timeouts are exposed while data-plane objects remain companion modules.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Security defaults | Consumers can accidentally leave public access, weak TLS, or shared access posture inconsistent. | Defaults emphasize secure posture: TLS 1.2, public access disabled, nested public access disabled, and infrastructure encryption support. |
| Input contract | Many raw provider settings can be passed without clear validation. | Validates account tier, replication type, account kind, access tier, and TLS version. |
| Data-plane objects | Containers, queues, tables, shares, and blobs are often added to the account module. | Data-plane objects are separate modules so app data lifecycle does not replace or churn the account. |
| Governance controls | CMK, lifecycle policies, and immutability can become bolted-on custom code. | Uses companion modules for customer-managed keys, management policies, and immutability policies. |
| Outputs | Downstream private endpoints and apps need stable endpoints. | Outputs storage account ID, name, and primary service endpoints. |

## Design Intent

This module owns the reusable storage account resource surface, not a specific workload shape:

- Storage account resource
- Account kind, tier, replication, and access tier
- TLS and public access posture
- Shared access key posture
- Identity
- Network rules
- Customer-managed keys
- Blob, queue, file share, routing, SAS, immutability, Azure Files authentication, custom domain, and static website account-level properties

Use companion modules for:

- `storage-container`
- `storage-blob`
- `storage-queue`
- `storage-table`
- `storage-share`
- `storage-account-customer-managed-key`
- `storage-management-policy`
- `storage-container-immutability-policy`
- `private-endpoint`
- `diagnostic-settings`
- `role-assignments`

## Why This Matters

The account lifecycle is different from application data objects. A storage account may be created once, while containers, queues, shares, private endpoints, lifecycle rules, diagnostics, and RBAC change independently. Keeping those concerns separate reduces custom stitching and prevents unnecessary account churn.

Pattern and root modules should apply enterprise policy choices, such as minimum TLS expectations, public access stance, diagnostics, private endpoint placement, and role assignments. This base module exposes valid Azure capabilities through optional typed inputs so new use cases do not require forking the module.
