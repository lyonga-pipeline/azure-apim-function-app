# terraform-azurerm-compeer-app-configuration

Azure App Configuration store (`azurerm_app_configuration`) only. Key/value
data, private endpoints, RBAC and diagnostics are owned elsewhere.

## Contract

- Required: `name`, `resource_group_name`, `location`.
- `sku` validated (`free` / `standard` / `premium`).
- Optional typed blocks: `identity`, `encryption`, `replica` (`map(object)`
  keyed by replica name), `timeouts`. Optional scalars: `local_auth_enabled`,
  `public_network_access`, `purge_protection_enabled`,
  `soft_delete_retention_days`, `data_plane_proxy_authentication_mode`.

## Lifecycle

| Change | Effect |
|---|---|
| `sku` free<->standard | Replace (Azure limitation) |
| `identity`, `replica` add/remove, `local_auth_enabled`, `public_network_access`, `tags` | In-place update |
| `name`, `resource_group_name`, `location` | Replace |
| `purge_protection_enabled` true->false, `encryption` | Replace |

## State exposure

Outputs: `app_config_id`, `app_config_name`, `app_config_endpoint`, `identity`.
Access keys are not output; retrieve them out-of-band or use `identity` +
RBAC / `local_auth_enabled = false`.

## Migration

No breaking changes. Interface unchanged.

## Tests

`terraform test` — create, `sku` default, name/endpoint wiring.
