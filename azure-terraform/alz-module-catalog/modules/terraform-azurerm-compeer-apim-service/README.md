# terraform-azurerm-compeer-apim-service

> **⚠ Duplicate pair with [`terraform-azurerm-compeer-apim`](../terraform-azurerm-compeer-apim).** Both wrap `azurerm_api_management` and are 0-consumer. Consolidate to one before a workload adopts either.


Azure API Management **service** only (`azurerm_api_management`). APIs, backends,
products, named values, policies, diagnostics and OpenID providers are separate
modules composed by the pattern.

## Contract

- Required: `name`, `resource_group_name`, `location`, `publisher_name`,
  `publisher_email`.
- `sku_name` is `<tier>_<capacity>` (validated by regex).
- `virtual_network_type` is `None` / `External` / `Internal`; a precondition
  requires `virtual_network_configuration` for the VNet-integrated modes and
  forbids it for `None`.
- Optional typed blocks: `identity`, `security` (transport toggles, azurerm 4.x
  `*_enabled` names), `protocols` (`http2_enabled`), `sign_in`, `sign_up`,
  `timeouts`.

## Lifecycle

| Change | Effect |
|---|---|
| `sku_name` capacity or tier | In-place scale (can take ~30-45 min) |
| `security`, `protocols`, `sign_in`, `sign_up`, `identity`, `public_network_access_enabled`, `tags` | In-place update |
| `name`, `resource_group_name`, `location` | Replace |
| `virtual_network_type`, `virtual_network_configuration.subnet_id` | Replace |

## State exposure

No secrets in state. Outputs: `id`, `name`, `gateway_url`,
`gateway_regional_url`, `management_api_url`, `developer_portal_url`,
`portal_url`, `public_ip_addresses`, `private_ip_addresses`,
`identity_principal_id`, `identity_tenant_id`.

## Migration

`security` object keys renamed to the azurerm 4.x form
(`enable_backend_tls10` -> `backend_tls10_enabled`, etc.) and `protocols.enable_http2`
-> `protocols.http2_enabled`. `timeouts` and the richer output set are additive.

## Tests

`terraform test` — create + default SKU, bad-SKU rejection, VNet precondition.
