# terraform-azurerm-compeer-disk-encryption-set

Creates a Disk Encryption Set (DES) for customer-managed-key VM/managed-disk
encryption — design doc Phase 5 Step 6 ("Compute and Disk Encryption Controls",
CMK where required for `regulated-apps-mg` / restricted data).

## Contract

- `key_vault_key_id` XOR `managed_hsm_key_id` — exactly one.
- `name` follows the Azure Compute DES rule: 1-80 characters, letters,
  numbers, underscores, and hyphens only.
- The DES gets its own identity (`SystemAssigned` by default). That identity
  needs **Key Vault Crypto Service Encryption User** (or the legacy access
  policy equivalent) on the source Key Vault before the first disk can be
  created with it — grant that at the pattern/workspace level with
  `terraform-azurerm-compeer-role-assignments`, not inside this module.
- `auto_key_rotation_enabled = true` requires a versionless Key Vault key ID,
  for example `https://vault.vault.azure.net/keys/des-key`. Use a versioned key
  ID only when `auto_key_rotation_enabled = false`.
- Output `id` feeds `disk_encryption_set_id` on `os_disk` / `additional_capabilities`
  in `terraform-azurerm-compeer-windows-virtual-machine` /
  `-linux-virtual-machine` (both already accept it).

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` / `resource_group_name` / `location` | string | - | `name` is validated against DES naming rules; RG/location must not be empty |
| `key_vault_key_id` / `managed_hsm_key_id` | string | `null` | exactly one must be set |
| `encryption_type` | string | `EncryptionAtRestWithCustomerKey` | supports current Azure Compute DES enum values |
| `auto_key_rotation_enabled` | bool | `true` | requires a versionless Key Vault key ID |
| `identity_type` / `identity_ids` | string / list(string) | `SystemAssigned` / `null` | `identity_ids` required when identity type includes `UserAssigned` |
| `federated_client_id` | string | `null` | GUID for cross-tenant key access |
| `tags` | map(string) | `{}` | update in place |

## Lifecycle

`key_vault_key_id`, `encryption_type`, and `identity` block changes are
in-place where Azure allows it; recreation risk is the same as any other
identity/config change on a durable resource. Deleting a DES that a VM disk
still references fails at the Azure API, which is the correct guardrail.

## Tests

`terraform test` (offline, `mock_provider`): key-source contract, auto-rotation
guardrails, supported encryption types, identity modes, output wiring, and
required string validation.
