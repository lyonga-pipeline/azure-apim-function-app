# Platform Identity Root

## Overview

**What this deploys:** the platform Key Vault (RBAC-first, private-by-default)
and, optionally, customer-managed-key disk encryption sets — the shared
identity/secrets foundation other patterns' `key_vault_secret_id`-style
inputs point at.

| Resource / module | Purpose |
|---|---|
| `module.key_vault` | The vault itself — RBAC authorization, `network_acls` default-deny |
| `module.key_vault_private_endpoint` | Optional; `null` in smoke tests so this root validates without needing hub private DNS outputs |
| `module.disk_encryption_set` | Optional customer-managed-key disk encryption sets, empty by default |

**`network_acls` — why it's built field-by-field instead of one `coalesce()`:**
`module.key_vault`'s `network_acls` argument builds its final object with a
`try(var.key_vault.network_acls.<field>, <default>)` per field rather than
`coalesce(var.key_vault.network_acls, {bypass=.., default_action=..})`. The
`coalesce()` form crashes when `network_acls` is left unset (as it is in
this pattern's own `terraform.tfvars.example`) — Terraform's "all arguments
must have the same type" error, because the literal fallback object and the
variable's declared type (which also allows `ip_rules` /
`virtual_network_subnet_ids`) are different shapes. See
`tests/defaults.tftest.hcl` for the regression test.

---

Key Vault is RBAC-first and private-by-default. Access assignments, diagnostics, and private endpoint attachment are composed explicitly so ownership and approval remain visible.

For smoke tests, `key_vault_private_endpoint` is left `null` so this root can validate the identity/vault baseline without requiring hub private DNS outputs. For enterprise testing, attach the private endpoint to the approved private endpoint subnet and pass the Key Vault private DNS zone ID from `platform-connectivity`.

`tenant_id` is optional and defaults to the tenant from the active Azure/HCP run credentials. `log_analytics_workspace_id` is also optional; set it to the `platform-management` output with the same name when you want Key Vault diagnostics enabled.

Certificate contacts are intentionally empty in the smoke-test tfvars. AzureRM 4.x deprecated the inline Key Vault `contact` field, and new private/RBAC vaults should use certificate-contact management only after the vault is reachable and the deployment identity has confirmed data-plane access.

Keep live secret values, certificate private keys, break-glass credentials, and one-time operational recovery material outside Terraform state. Terraform should manage vaults, RBAC, private endpoints, diagnostics, and policy; controlled secret injection should use approved secret-management or CI/CD release processes.

`disk_encryption_sets` (design doc Phase 5 Step 6) creates customer-managed-key
disk encryption sets via `terraform-azurerm-compeer-disk-encryption-set`, empty
by default. Grant each set's `disk_encryption_set_identity_principal_ids` entry
"Key Vault Crypto Service Encryption User" on its source key, then pass
`disk_encryption_set_ids[<key>]` to a VM pattern's `os_disk.disk_encryption_set_id`.
