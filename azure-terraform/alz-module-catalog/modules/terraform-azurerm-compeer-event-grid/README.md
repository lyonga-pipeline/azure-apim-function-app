# terraform-azurerm-compeer-event-grid

An Event Grid custom topic and, optionally, its event subscriptions. System topics and domain topics are separate modules.

## Contract

- Resource: `azurerm_eventgrid_topic` (custom topic).
- Inputs are explicitly typed; optional blocks are `optional(object(...))` and repeatables are `map(object(...))` keyed by a caller-stable name.
- Adjacent resource-group / network / RBAC / diagnostic capabilities are composed externally.

## Lifecycle

| Change | Effect |
|---|---|
| `eventgrid_subscription` add/remove/retune, `public_network_access_enabled`, `local_auth_enabled`, `tags` | In-place update |
| `eventgrid_input_schema`, `eventgrid_topic_name`, `resource_group_name`, `location` | Replace |

## State exposure

Outputs: topic `id` / `endpoint` and per-subscription IDs. Access keys are not output.

## Migration

No breaking changes. Dead commented-out `data.tf` and the legacy `test/` fixture were removed.

## Tests

`terraform test` (`tests/defaults.tftest.hcl`, `mock_provider`) — create and attribute wiring; validation failures where the module adds `validation` / `precondition` rules.
