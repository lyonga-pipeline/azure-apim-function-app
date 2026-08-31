# terraform-azurerm-compeer-windows-vm-domain-join

`JsonADDomainExtension` VM extension that joins a Windows VM to an AD DS domain.
Companion to `terraform-azurerm-compeer-windows-vm` — the VM and NIC are passed in
by ID.

## Usage

```hcl
module "dc_domain_join" {
  source             = "../terraform-azurerm-compeer-windows-vm-domain-join"
  virtual_machine_id = module.dc.id
  domain_name        = "corp.example.com"
  domain_username    = "corp\\svc-domainjoin"

  # Preferred: protected settings sourced from Key Vault (no inline secret)
  protected_settings_from_key_vault = {
    secret_url      = data.azurerm_key_vault_secret.domain_join.id
    source_vault_id = module.vault.id
  }
}
```

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `virtual_machine_id` | string | — | ForceNew |
| `domain_name` | string | — | non-empty (precondition) |
| `domain_username` | string | — | non-empty (precondition) |
| `domain_password` | string (sensitive) | — | used only when `protected_settings_from_key_vault` is null |
| `protected_settings_from_key_vault` | object \| null | `null` | `{secret_url, source_vault_id}` — preferred, keeps the secret out of state |
| `ou_path` | string | `null` | LDAP OU path |
| `join_options` | number | `3` | validated 0–63 |
| `restart` | bool | `true` | |
| `auto_upgrade_minor_version` / `automatic_upgrade_enabled` / `failure_suppression_enabled` | bool | see vars | |
| `timeouts` | object | `{}` | passthrough |

## Outputs

`id`.

## Lifecycle contract

| Change | Result |
|---|---|
| `settings` fields (`domain_name`, `ou_path`, `join_options`, `restart`) | **replace** the extension (Azure re-runs the join) |
| `domain_password` / `protected_settings_from_key_vault` | update in place (protected settings are not diffed by the provider) |
| `tags` | update in place |
| `virtual_machine_id` | **replace** |

**State exposure:** with `domain_password` set, the password is in state. Use
`protected_settings_from_key_vault` to avoid this — the extension pulls the
protected-settings document straight from Key Vault.

## Migration

Added `join_options` validation (0–63) and input descriptions. No interface change.

## Tests

`terraform test` (offline): inline-password path, Key-Vault-protected-settings
path, `join_options` validation.
