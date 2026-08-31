# terraform-azurerm-compeer-keyvault-managed-hsm

A Key Vault Managed HSM pool. Key material, role assignments and security-domain activation ceremony are operated separately.

## Contract

- Resource: `azurerm_key_vault_managed_hardware_security_module` (Managed HSM).
- Inputs are explicitly typed; optional blocks are `optional(object(...))` and repeatables are `map(object(...))` keyed by a caller-stable name.
- Adjacent resource-group / network / RBAC / diagnostic capabilities are composed externally.

## Lifecycle

| Change | Effect |
|---|---|
| `tags` | In-place update |
| `admin_object_ids`, `public_network_access_enabled`, `network_acls` | In-place update |
| `name`, `resource_group_name`, `location`, `sku_name`, `tenant_id` | Replace |
| `purge_protection_enabled`, `soft_delete_retention_days`, `security_domain_*` | Replace |

## State exposure

Outputs: `key_vault_hsm_id`, `key_vault_hsm_uri`, security-domain encrypted data. No plaintext key material.

## Migration

- `public_network_access_enabled` default changed **`true` -> `false`** (private by default). An HSM behind a Private Endpoint is the intended posture.

`network_acls` changed from `list(object)` to a single optional `object` (the provider block is singular). `security_domain_key_vault_certificate_ids` + `security_domain_quorum` must now be set together (precondition) or left unset.

## Tests

`terraform test` (`tests/defaults.tftest.hcl`, `mock_provider`) — create and attribute wiring; validation failures where the module adds `validation` / `precondition` rules.
