# Storage Container Immutability Policy Module

This module manages immutability policy for storage containers separately from container and storage account creation.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Compliance control | Immutability can be hidden inside container creation. | Immutability is an explicit compliance module. |
| Risk | Locking policies have operational consequences. | The policy is reviewed and applied separately. |
| Lifecycle | Containers may exist before immutability is approved. | Roots compose this module when the retention requirement is confirmed. |

## Design Intent

This module owns:

- Container immutability policy
- Retention period and lock behavior where supported

Use companion modules for:

- `storage-account`
- `storage-container`

## Why This Matters

Immutable storage can affect delete, retention, and recovery operations. Separating the policy makes the risk visible before it is applied.

