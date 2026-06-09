# Storage Container Module

This companion module manages blob containers separately from the storage account.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Data-plane lifecycle | Containers can be embedded in the storage account module. | Containers are managed independently from the account. |
| Ownership | Platform account ownership and app data namespace ownership can be mixed. | Application roots compose only the containers they need. |
| Reuse | Different workloads need different containers. | Container lifecycle can change without changing the storage account. |

## Design Intent

Use this module for application-owned blob containers. Keep account security, networking, CMK, lifecycle policy, and private endpoints in their own modules.

