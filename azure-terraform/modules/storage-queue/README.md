# Storage Queue Module

This companion module manages storage queues separately from the storage account.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Queue lifecycle | Queues can be bundled into the account module. | Queues are app-owned data-plane objects with independent lifecycle. |
| Reuse | Different apps need different queues. | Application roots create only the queues they consume. |

## Design Intent

Use this module for workload-owned storage queues. Keep account security, private endpoints, diagnostics, and RBAC outside this module.

