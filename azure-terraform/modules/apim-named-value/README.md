# APIM Named Value Module

This module supports the Terraform 2.0 APIM pattern by managing APIM named values as a separate API platform concern.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Secret handling | Named values can be mixed into large APIM service or API modules. | Named values are managed through a dedicated map contract. |
| Key Vault references | Secret values can be passed directly. | Key Vault-backed named values are first-class through `value_from_key_vault`. |
| Scale | One-off resources lead to repeated code. | `for_each` supports multiple named values from one stable map. |

## Design Intent

This module owns:

- APIM named values
- Secret flag configuration
- Optional direct values
- Optional Key Vault secret references
- Optional identity client ID for Key Vault access

Use companion modules for:

- `apim-service`
- `key-vault-secret`
- `role-assignments`

## Why This Matters

Named values are shared API configuration, not APIM infrastructure. Keeping them separate improves security review, reduces module sprawl, and lets applications rotate references without changing the APIM service.

