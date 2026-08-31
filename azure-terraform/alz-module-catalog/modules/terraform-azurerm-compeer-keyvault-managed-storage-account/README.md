# terraform-azurerm-compeer-keyvault-managed-storage-account

Registers an existing storage account with a Key Vault so the vault rotates the
account keys, and optionally defines SAS token definitions. Both the vault and the
storage account are passed in by ID; this module creates neither.

Implemented fresh during the catalog hardening pass (the directory previously
contained no Terraform).

## Usage

```hcl
module "kv_managed_sa" {
  source             = "../terraform-azurerm-compeer-keyvault-managed-storage-account"
  name               = "diagsa"
  key_vault_id       = module.vault.id
  storage_account_id = module.storage.id

  sas_token_definitions = {
    blob-readonly = {
      sas_template_uri = "https://${module.storage.name}.blob.core.windows.net/?sv=2021-08-06&ss=b&srt=sco&sp=r&se=2099-01-01T00:00:00Z"
      sas_type         = "account"
      validity_period  = "P7D"
    }
  }
}
```

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` | string | - | ForceNew |
| `key_vault_id` | string | - | ForceNew |
| `storage_account_id` | string | - | the account KV manages |
| `storage_account_key` | string | `key1` | `key1` \| `key2` (validated) |
| `regenerate_key_automatically` | bool | `true` | update in place |
| `regeneration_period` | string | `P90D` | ISO 8601 duration |
| `sas_token_definitions` | map(object) | `{}` | key = definition name; `{sas_template_uri, sas_type, validity_period}` |
| `tags` | map(string) | `{}` | update in place |

## Outputs

`id`, `name`, `sas_token_definition_secret_ids` (name -> Key Vault secret ID).

## Lifecycle contract

| Change | Result |
|---|---|
| `regenerate_key_automatically`, `regeneration_period`, `tags` | **update in place** |
| add / remove a key in `sas_token_definitions` | create / destroy **only that definition** |
| `name`, `key_vault_id`, `storage_account_key` | **replace** |

State exposure: SAS template URIs may embed a signature - treat them as
secret-adjacent. The generated SAS tokens themselves live in Key Vault, not state.

## Tests

`terraform test` (offline): defaults, SAS-definition wiring, `storage_account_key`
validation.
