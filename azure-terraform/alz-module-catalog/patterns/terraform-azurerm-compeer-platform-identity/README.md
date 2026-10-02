# Platform Identity Root

## Overview

**What this deploys:** the platform Key Vault (RBAC-first, public access off)
and, optionally, customer-managed-key disk encryption sets — the shared
identity/secrets foundation other patterns' `key_vault_secret_id`-style
inputs point at.

| Resource / module | Purpose |
|---|---|
| `module.key_vault` | The vault itself — RBAC authorization, `network_acls` default-deny |
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

Key Vault is RBAC-first with public network access disabled. Access assignments
and diagnostics are composed explicitly so ownership and approval remain visible.

The Key Vault private endpoint is intentionally not created by this pattern. The
refined placement sheet keeps platform private endpoints in the connectivity
subscription because they attach to the hub VNet private endpoint subnet. When
the on-hold private endpoint item is approved, create it from a connectivity-
owned composition using this workspace's `key_vault_id` output and the
`platform-connectivity` private DNS zone/subnet outputs.

`tenant_id` is optional and defaults to the tenant from the active Azure/HCP run credentials. `log_analytics_workspace_id` is also optional; set it to the `platform-management` output with the same name when you want Key Vault diagnostics enabled.

Certificate contacts are intentionally empty in the smoke-test tfvars. AzureRM 4.x deprecated the inline Key Vault `contact` field, and new private/RBAC vaults should use certificate-contact management only after the vault is reachable and the deployment identity has confirmed data-plane access.

Keep live secret values, certificate private keys, break-glass credentials, and one-time operational recovery material outside Terraform state. Terraform should manage vaults, RBAC, private endpoints, diagnostics, and policy; controlled secret injection should use approved secret-management or CI/CD release processes.

`disk_encryption_sets` (design doc Phase 5 Step 6) creates customer-managed-key
disk encryption sets via `terraform-azurerm-compeer-disk-encryption-set`, empty
by default. Grant each set's `disk_encryption_set_identity_principal_ids` entry
"Key Vault Crypto Service Encryption User" on its source key, then pass
`disk_encryption_set_ids[<key>]` to a VM pattern's `os_disk.disk_encryption_set_id`.
