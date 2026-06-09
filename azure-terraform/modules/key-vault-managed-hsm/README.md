# Key Vault Managed HSM Module

This module manages Managed HSM as a dedicated security boundary instead of treating it as a variation of a standard Key Vault.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Resource boundary | HSM can be grouped conceptually with standard Key Vault. | Managed HSM has its own module and lifecycle. |
| Security posture | HSM network and purge settings require stricter handling. | Tenant, network ACLs, purge protection, and retention are explicit. |
| Data-plane separation | Keys and assignments can drift on a separate cadence. | HSM keys, private connectivity, diagnostics, and access are composed separately. |

## Design Intent

This module owns:

- Managed HSM resource creation
- Tenant and administrator configuration
- Soft-delete and purge-protection posture
- Network ACLs
- Tags and outputs

Use companion modules for:

- `role-assignments`
- `private-endpoint`
- `diagnostic-settings`
- Future HSM key modules where required

## Why This Matters

Managed HSM is a stronger security boundary than a standard Key Vault. Treating it separately keeps its operational controls explicit and avoids overloading the Key Vault module contract.

