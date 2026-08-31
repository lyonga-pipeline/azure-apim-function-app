# terraform-azurerm-compeer-keyvault-assets

Bulk Key Vault data-plane assets - secrets, keys and certificates - for **one**
existing vault, passed in as `key_vault_id`. This module does not create the
vault. For assets whose rotation or ownership lifecycle is independent, use the
single-purpose `key-vault-secret` / `key-vault-key` / `key-vault-certificate`
modules instead.

## Usage

```hcl
module "kv_assets" {
  source       = "../terraform-azurerm-compeer-keyvault-assets"
  key_vault_id = module.vault.id

  keys = {
    storage-cmk = { key_type = "RSA", key_size = 4096, key_opts = ["wrapKey", "unwrapKey"] }
  }
  secrets = {
    sql-connstring = { value = var.sql_connstring, content_type = "text/plain" }
  }
}
```

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `key_vault_id` | string | - | existing vault; not created here |
| `secrets` | map(object) | `{}` | key = logical name (also the secret name unless `name` set) |
| `keys` | map(object) | `{}` | `key_type` validated RSA/RSA-HSM/EC/EC-HSM; optional `rotation_policy` |
| `certificates` | map(object) | `{}` | exactly one of `import` / `policy` per entry (precondition) |

## Outputs

`secret_ids`, `key_ids`, `key_versionless_ids`, `certificate_ids`,
`certificate_versionless_ids` - all keyed by the caller's logical key.

## Lifecycle contract

| Change | Result |
|---|---|
| add / remove a key in `secrets` / `keys` / `certificates` | create / destroy **only that asset** (stable keys) |
| `value`, `content_type`, `tags`, `expiration_date`, `rotation_policy` | **update in place** |
| `key_type`, `key_size`, `curve` on an existing key | **replace** (Azure ForceNew) |
| switch a certificate between `import` and `policy` | **replace** |
| `key_vault_id` | **replace** every asset |

**State exposure:** secret and imported-certificate material is stored in
Terraform state. Protect the backend. The provider marks
`azurerm_key_vault_secret.value` sensitive in plan output, but it is still in state.

## Migration

`keys[*].key_type` is now validated. No input/output renames. `name` still
defaults to the map key.

## Tests

`terraform test` (offline): empty no-op, create secret+key, key_type validation,
certificate import/policy exclusivity.
