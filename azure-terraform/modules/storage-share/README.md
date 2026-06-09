# Storage Share Module

This companion module manages Azure Files shares separately from the storage account.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Share lifecycle | File shares can be bundled with storage account creation. | Shares can be added, resized, or removed without changing the account lifecycle. |
| Ownership | File-share usage is usually workload-specific. | Workload roots compose shares only where needed. |

## Design Intent

Use this module for application-owned Azure Files shares. Keep account-level network, encryption, and access posture in the storage account and companion governance modules.

