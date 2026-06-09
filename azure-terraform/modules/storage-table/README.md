# Storage Table Module

This companion module manages storage tables separately from the storage account.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Table lifecycle | Tables can be hidden inside account modules. | Tables are explicit workload-owned objects. |
| Composition | Not every storage account needs tables. | Application roots add table support only where required. |

## Design Intent

Use this module for application-owned storage tables. Keep account security, network, diagnostics, and role assignments in separate modules.

