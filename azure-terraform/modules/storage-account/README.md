# Storage Account Module

This module is the Terraform 2.0 replacement pattern for reviewed storage account configurations. It keeps the account lifecycle focused on the storage account while child objects and governance controls are handled by companion modules.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Security defaults | Consumers can accidentally leave public access, weak TLS, or shared access posture inconsistent. | Defaults emphasize secure posture: TLS 1.2, public access disabled, nested public access disabled, and infrastructure encryption support. |
| Input contract | Many raw provider settings can be passed without clear validation. | Validates account tier, replication type, account kind, access tier, and TLS version. |
| Data-plane objects | Containers, queues, tables, shares, and blobs are often added to the account module. | Data-plane objects are separate modules so app data lifecycle does not replace or churn the account. |
| Governance controls | CMK, lifecycle policies, and immutability can become bolted-on custom code. | Uses companion modules for customer-managed keys, management policies, and immutability policies. |
| Outputs | Downstream private endpoints and apps need stable endpoints. | Outputs storage account ID, name, and primary service endpoints. |

## Design Intent

This module owns:

- Storage account resource
- Account kind, tier, replication, and access tier
- TLS and public access posture
- Shared access key posture
- Identity
- Network rules
- Blob, queue, and static website account-level properties

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

The account lifecycle is different from application data objects. A storage account may be created once, while containers, queues, shares, private endpoints, immutability, and lifecycle rules change independently. Keeping those concerns separate reduces custom stitching and prevents unnecessary account churn.

