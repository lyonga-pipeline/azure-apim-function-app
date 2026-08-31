# terraform-azurerm-compeer-apim-openid

A single OpenID Connect provider registration in an existing API Management service.

## Contract

- Resource: `azurerm_api_management_openid_connect_provider` (OpenID Connect provider).
- Inputs are explicitly typed; optional blocks are `optional(object(...))` and repeatables are `map(object(...))` keyed by a caller-stable name.
- Adjacent resource-group / network / RBAC / diagnostic capabilities are composed externally.

## Lifecycle

| Change | Effect |
|---|---|
| `display_name`, `description`, `metadata_endpoint`, `client_id` | In-place update |
| `client_secret` | In-place update (secret rotation) |
| `name`, `apim_name`, `resource_group_name` | Replace |

## State exposure

Outputs: `openid_id`. `client_secret` is stored in Terraform state.

## Migration

No breaking changes. Interface unchanged.

## Tests

`terraform test` (`tests/defaults.tftest.hcl`, `mock_provider`) — create and attribute wiring; validation failures where the module adds `validation` / `precondition` rules.
