# terraform-azurerm-compeer-apim-api

A single API in an existing API Management service. Operations, policies, diagnostics, products and subscriptions are separate resources owned by the pattern.

## Contract

- Resource: `azurerm_api_management_api` (API definition).
- Inputs are explicitly typed; optional blocks are `optional(object(...))` and repeatables are `map(object(...))` keyed by a caller-stable name.
- Adjacent resource-group / network / RBAC / diagnostic capabilities are composed externally.

## Lifecycle

| Change | Effect |
|---|---|
| `display_name`, `path`, `protocols`, `description`, `service_url`, `subscription_required`, contact/license/import blocks | In-place update |
| `revision` | Creates a new API revision |
| `name`, `apim_name`, `resource_group_name` | Replace |
| `version` / `version_set_id` | Replace |

## State exposure

Outputs: `id`, `name`. No secrets.

## Migration

No breaking changes. Interface unchanged.

## Tests

`terraform test` (`tests/defaults.tftest.hcl`, `mock_provider`) — create and attribute wiring; validation failures where the module adds `validation` / `precondition` rules.
