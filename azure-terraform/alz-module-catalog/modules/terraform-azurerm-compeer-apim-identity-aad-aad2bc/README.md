# terraform-azurerm-compeer-apim-identity-aad-aad2bc

Configures the Entra ID and/or Entra ID B2C identity providers on an existing API
Management service (`azurerm_api_management_identity_provider_aad` /
`_aadb2c`). The APIM service is passed in by name.

Each provider is managed only when its config object is supplied — `var.aad` /
`var.aadb2c` default `null` (= "not managed"), so this module can own the AAD
provider while another owner (or nobody) owns AADB2C.

## Usage

```hcl
module "apim_idp" {
  source              = "../terraform-azurerm-compeer-apim-identity-aad-aad2bc"
  apim_name           = module.apim.name
  resource_group_name = module.rg.name

  aad = {
    client_id       = module.apim_app.client_id
    client_secret   = var.apim_app_secret
    allowed_tenants = [var.tenant_id]
  }
}
```

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `apim_name` / `resource_group_name` | string | — | target APIM |
| `aad` | object \| null | `null` | `{client_id, client_secret, allowed_tenants(list, required), client_library?, signin_tenant?}` |
| `aadb2c` | object \| null | `null` | `{client_id, client_secret, allowed_tenant, signin_tenant, authority, signin_policy, signup_policy?, password_reset_policy?, profile_editing_policy?}` |

## Outputs

`identity_aad_id`, `identity_aadb2c_id` (null when the provider is not managed).

## Lifecycle contract

Setting or clearing `var.aad` / `var.aadb2c` creates / destroys **only that
provider**. `client_secret` and policy changes update in place. Changing
`apim_name` / `resource_group_name` replaces the provider(s).

**State exposure:** `client_secret` is stored in Terraform state.

## Migration

`create_*` booleans + `count` were already replaced by the optional-object model
in the redesign. Made `aad.allowed_tenants` a required list (the provider requires
it). Added `apim_name` / `resource_group_name` descriptions and output descriptions.

## Tests

`terraform test` (offline): none-by-default, AAD-only (AADB2C stays unmanaged).
