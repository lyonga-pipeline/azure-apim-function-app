# terraform-azurerm-compeer-disk-encryption-set

Creates a Disk Encryption Set (DES) for customer-managed-key VM/managed-disk
encryption — design doc Phase 5 Step 6 ("Compute and Disk Encryption Controls",
CMK where required for `regulated-apps-mg` / restricted data).

## Contract

- `key_vault_key_id` XOR `managed_hsm_key_id` — exactly one.
- The DES gets its own identity (`SystemAssigned` by default). That identity
  needs **Key Vault Crypto Service Encryption User** (or the legacy access
  policy equivalent) on the source Key Vault before the first disk can be
  created with it — grant that at the pattern/workspace level with
  `terraform-azurerm-compeer-role-assignments`, not inside this module.
- Output `id` feeds `disk_encryption_set_id` on `os_disk` / `additional_capabilities`
  in `terraform-azurerm-compeer-windows-virtual-machine` /
  `-linux-virtual-machine` (both already accept it).

## Lifecycle

`key_vault_key_id`, `encryption_type`, and `identity` block changes are
in-place where Azure allows it; recreation risk is the same as any other
identity/config change on a durable resource. Deleting a DES that a VM disk
still references fails at the Azure API, which is the correct guardrail.

## Tests

`terraform test` (offline, `mock_provider`): create with a Key Vault key,
precondition rejects setting both key sources or neither, precondition rejects
`UserAssigned` without `identity_ids`.
