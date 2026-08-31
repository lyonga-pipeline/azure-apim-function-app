# terraform-azurerm-compeer-event-grid-system-topic

An Event Grid system topic bound to an Azure source resource, and optional event subscriptions.

## Contract

- Resource: `azurerm_eventgrid_system_topic` (system topic).
- Inputs are explicitly typed; optional blocks are `optional(object(...))` and repeatables are `map(object(...))` keyed by a caller-stable name.
- Adjacent resource-group / network / RBAC / diagnostic capabilities are composed externally.

## Lifecycle

| Change | Effect |
|---|---|
| `eventgrid_subscription` add/remove, `eventgrid_identity_type`, `tags` | In-place update |
| `source_arm_resource_id`, `topic_type`, `eventgrid_topic_name`, `resource_group_name` | Replace |

## State exposure

Outputs: system topic `id` and per-subscription IDs.

## Migration

No breaking changes. An in-module provider block and the pipeline YAML were removed (a module must not pin its own provider).

## Tests

`terraform test` (`tests/defaults.tftest.hcl`, `mock_provider`) — create and attribute wiring; validation failures where the module adds `validation` / `precondition` rules.
