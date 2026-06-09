# User Assigned Identity Module

This module creates user-assigned managed identities that can be shared by applications, private resources, Key Vault references, and automation patterns.

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

