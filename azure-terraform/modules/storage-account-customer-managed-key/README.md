# Storage Account Customer Managed Key Module

This module configures customer-managed key encryption for a storage account as a separate security lifecycle.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Encryption lifecycle | CMK settings can be embedded directly in the storage account module. | CMK configuration is isolated. |
| Key rotation | Key versions and identities may change independently. | Storage account creation does not need to change when key configuration changes. |
| Access dependency | CMK requires Key Vault access and identity readiness. | Roots compose Key Vault, identity, role assignment, and CMK explicitly. |

## Design Intent

This module owns:

- Storage account customer-managed key configuration
- Key Vault key reference
- Managed identity reference where required

Use companion modules for:

- `storage-account`
- `key-vault`
- `key-vault-key`
- `user-assigned-identity`
- `role-assignments`

## Why This Matters

Encryption posture is a security control with its own approval and rotation cadence. Keeping it separate avoids mixing storage creation with key lifecycle.

