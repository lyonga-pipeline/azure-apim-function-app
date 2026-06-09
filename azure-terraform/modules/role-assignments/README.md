# Role Assignments Module

This companion module manages Azure RBAC role assignments separately from base resources.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Access lifecycle | Access can be embedded into Key Vault, Storage, App, or SQL modules. | RBAC assignments are separate and can be changed without touching base resources. |
| Reuse | Different principals need access across different scopes. | Uses a map of assignments with stable keys. |
| Governance | Human, workload, and platform access may need different approval paths. | Access changes can be reviewed and promoted independently. |

## Design Intent

Use this module for Azure RBAC assignments across subscriptions, resource groups, and resources. Keep access changes explicit in the application root or governance stack.

## Why This Matters

Access control changes frequently and often has different owners than infrastructure creation. Keeping RBAC separate helps prevent drift and avoids rebuilding base resources for access changes.
