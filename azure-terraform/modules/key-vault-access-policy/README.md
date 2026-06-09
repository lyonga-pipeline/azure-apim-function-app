# Key Vault Access Policy Module

This module exists as a compatibility path for Key Vault access policies while the preferred 2.0 pattern remains RBAC-first access through role assignments.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Vault lifecycle | Access policies can be embedded directly in the vault module. | Access policy ownership is separate from vault creation. |
| Compatibility | Some legacy integrations may still require access policies. | The compatibility path is explicit and isolated. |
| Drift control | Access changes can collide with vault changes. | Policy changes affect only the access policy resource. |

## Design Intent

This module owns:

- Key Vault access policy resource
- Object ID, tenant ID, and application ID mapping
- Key, secret, certificate, and storage permissions

Use companion modules for:

- `key-vault`
- `role-assignments`
- `key-vault-secret`
- `key-vault-key`
- `key-vault-certificate`

## Why This Matters

RBAC should be the default for new vaults, but some workloads may still need access policy compatibility. Keeping this module separate prevents legacy access patterns from becoming the default vault design.

