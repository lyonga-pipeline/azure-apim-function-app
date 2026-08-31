# terraform-azurerm-compeer-apim-backend

A single backend registration in an existing API Management service.

## Contract

- Resource: `azurerm_api_management_backend` (backend).
- Inputs are explicitly typed; optional blocks are `optional(object(...))` and repeatables are `map(object(...))` keyed by a caller-stable name.
- Adjacent resource-group / network / RBAC / diagnostic capabilities are composed externally.

## Lifecycle

| Change | Effect |
|---|---|
| `url`, `protocol`, `description`, `title`, `resource_id`, `credentials`, `proxy`, `tls` blocks | In-place update |
| `name`, `apim_name`, `resource_group_name` | Replace |

## State exposure

Outputs: `id`, `name`. `credentials`/`proxy` may carry secrets supplied by the caller; those values enter Terraform state.

## Migration

No breaking changes. `credentials`/`proxy` objects are not marked `sensitive` so they can drive `dynamic` blocks; pass bare secret strings through a sensitive wrapper.

## Tests

`terraform test` (`tests/defaults.tftest.hcl`, `mock_provider`) — create and attribute wiring; validation failures where the module adds `validation` / `precondition` rules.
