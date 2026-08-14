# Key Vault Key Module

This companion module manages Key Vault keys separately from the Key Vault resource.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Key lifecycle | Key material can be mixed into the vault module. | Keys are managed independently from vault creation. |
| Rotation | Rotation and key policy concerns evolve separately from vault settings. | Key configuration can be updated without changing the core vault lifecycle. |
| Composition | Workloads may need different keys for encryption or signing. | Application roots compose only the keys they need. |

## Design Intent

Use this module for customer-managed keys, encryption keys, and other workload-owned Key Vault keys. Keep vault networking, RBAC, diagnostics, and private endpoints in their own modules.

