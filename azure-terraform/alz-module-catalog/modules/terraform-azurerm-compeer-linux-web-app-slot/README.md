# terraform-azurerm-compeer-linux-web-app-slot

A single deployment slot for an existing `azurerm_linux_web_app`. The parent app
is passed in by ID (`app_service_id`); this module does not create it.

Implemented fresh during the catalog hardening pass (the directory previously
contained no Terraform).

## Usage

```hcl
module "app_staging" {
  source                    = "../terraform-azurerm-compeer-linux-web-app-slot"
  name                      = "staging"
  app_service_id            = module.app.id
  virtual_network_subnet_id = module.spoke.subnet_ids["web"]

  site_config = {
    always_on        = true
    application_stack = { node_version = "20-lts" }
  }

  app_settings = { ENVIRONMENT = "staging" }
  tags         = module.tags.tags
}
```

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` | string | - | ForceNew |
| `app_service_id` | string | - | ForceNew |
| `https_only` | bool | `true` | update in place |
| `public_network_access_enabled` | bool | `false` | update in place |
| `virtual_network_subnet_id` | string | `null` | regional VNet integration |
| `app_settings` | map(string) | `{}` | update in place |
| `site_config` | object | `{}` | all fields optional; single block always rendered |
| `identity` | object \| null | `null` | optional managed identity |
| `tags` | map(string) | `{}` | update in place |
| `timeouts` | object | `{}` | passthrough |

## Outputs

`id`, `name`, `default_hostname`, `identity_principal_id`.

## Lifecycle contract

| Change | Result |
|---|---|
| `app_settings`, `site_config.*`, `https_only`, `public_network_access_enabled`, `virtual_network_subnet_id`, `identity`, `tags` | **update in place** |
| `name`, `app_service_id` | **replace** |

State exposure: none directly (secrets belong in `app_settings` referencing Key
Vault, which the caller supplies).

## Tests

`terraform test` (offline): secure defaults, site_config + identity wiring.
