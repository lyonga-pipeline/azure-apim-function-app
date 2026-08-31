# terraform-azurerm-compeer-apim

Azure API Management **service** (the `azurerm_api_management` resource only).
APIs, backends, named values, identity providers, products, policies and
diagnostics are composed by the companion modules (`apim-api`, `apim-backend`,
`apim-openid`, `apim-identity-aad-aad2bc`, `diagnostic-settings`, ...).

Equivalent to `terraform-azurerm-compeer-apim-service`; both are maintained to the
same standard.

## Usage

```hcl
module "apim" {
  source              = "../terraform-azurerm-compeer-apim"
  name                = "apim-platform-prod"
  resource_group_name = module.rg.name
  location            = "eastus2"
  publisher_name      = "Platform Team"
  publisher_email     = "platform@example.com"
  sku_name            = "Premium_1"

  virtual_network_type = "Internal"
  virtual_network_configuration = {
    subnet_id = module.hub.subnet_ids["apim"]
  }

  tags = module.tags.tags
}
```

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` / `resource_group_name` / `location` | string | — | ForceNew |
| `publisher_name` / `publisher_email` | string | — | update in place |
| `sku_name` | string | `Developer_1` | `<tier>_<capacity>`, validated; capacity change is in-place, tier change may replace |
| `public_network_access_enabled` | bool | `false` | update in place |
| `virtual_network_type` | string | `None` | `None` \| `External` \| `Internal`; changing to/from `None` is ForceNew |
| `virtual_network_configuration` | object \| null | `null` | required iff `virtual_network_type != None` (precondition) |
| `identity` | object \| null | `null` | optional managed identity |
| `security` | object \| null | `null` | TLS/cipher overrides; defaults disable SSL3/TLS1.0/TLS1.1 (v5-ready attribute names) |
| `protocols` | object \| null | `null` | `http2_enabled` defaults on |
| `sign_in` / `sign_up` | object \| null | `null` | developer-portal settings |
| `min_api_version` | string | `null` | pin the control-plane API version |
| `client_certificate_enabled` | bool | `null` | Consumption tier only |
| `zones` | list(string) | `null` | Premium tier |
| `timeouts` | object | `{}` | defaults 1h30m for create/update/delete |

## Outputs

`id`, `name`, `gateway_url`, `developer_portal_url`, `management_api_url`,
`identity_principal_id`, `private_ip_addresses`, `public_ip_addresses`.

## Lifecycle contract

| Change | Result |
|---|---|
| `publisher_*`, `sku_name` capacity, `security`, `protocols`, `sign_in`, `sign_up`, `tags`, `public_network_access_enabled`, `identity` | **update in place** |
| `sku_name` tier change (e.g. Developer → Premium) | provider-dependent; often long in-place migration, sometimes replace — test in a scratch RG first |
| `virtual_network_type` None ↔ Internal/External | **replace** |
| `name`, `resource_group_name`, `location` | **replace** |

State exposure: none directly.

## Migration

Embedded `azurerm_monitor_diagnostic_setting` was removed — compose
`terraform-azurerm-compeer-diagnostic-settings` at the pattern layer. Broad
`ignore_changes` removed. `security.*` / `protocols.*` attributes renamed to the
azurerm-v5-ready form (`backend_ssl30_enabled`, `frontend_tls10_enabled`,
`http2_enabled`). New optional inputs: `min_api_version`,
`client_certificate_enabled`, `zones`, `timeouts`.

## Tests

`terraform test` (offline): secure defaults, SKU validation, VNet precondition
(rejects Internal without a subnet, accepts with one).
