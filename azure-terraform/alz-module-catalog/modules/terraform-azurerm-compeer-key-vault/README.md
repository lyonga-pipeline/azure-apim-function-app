# Key Vault Module

This module is the Terraform 2.0 replacement pattern for the reviewed Key Vault configuration. It keeps the vault lifecycle focused on the vault resource itself while moving access, secrets, keys, certificates, diagnostics, and private connectivity into companion modules.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Vault lifecycle | Vault creation and access policy ownership are coupled together. | Vault creation is kept separate from access assignments and data-plane objects. |
| Access model | Access-policy-first design can create drift when application and platform teams change access independently. | Supports RBAC-first vault posture with `enable_rbac_authorization`; access policies remain a separate compatibility module when needed. |
| Security posture | Public access and network ACL choices depend heavily on consumer input. | Defaults to private-by-default posture with `public_network_access_enabled = false` and explicit `network_acls`. |
| Validation | Limited visible validation in the reviewed pattern. | Validates SKU and soft-delete retention bounds. |
| Outputs | Dependent modules need stable vault identifiers. | Exposes `id`, `name`, and `vault_uri` for companion modules and application roots. |
| Lifecycle separation | Secrets, keys, certificates, private endpoints, diagnostics, and role assignments can become mixed into the vault module. | Those concerns are composed with `key-vault-secret`, `key-vault-key`, `key-vault-certificate`, `private-endpoint`, `diagnostic-settings`, and `role-assignments`. |

## Design Intent

This module owns:

- Key Vault resource creation
- SKU, tenant, soft-delete, and purge-protection settings
- RBAC enablement flag
- Public network access posture
- Network ACLs
- Certificate contacts
- Standard outputs for downstream composition

Use companion modules for:

- `role-assignments`
- `key-vault-access-policy`
- `key-vault-secret`
- `key-vault-key`
- `key-vault-certificate`
- `private-endpoint`
- `diagnostic-settings`
- `monitor-metric-alert`

## Why This Matters

The reviewed pattern is a good starting point, but coupling vault creation with access and data-plane objects makes the module harder to reuse at enterprise scale. A vault can live for years while secrets, keys, certificates, access, private DNS, and diagnostics change on different cadences.

The improved pattern keeps the vault stable and lets application roots compose the surrounding capabilities explicitly.

