# terraform-azurerm-compeer-service-plan

Azure App Service plan (`azurerm_service_plan`) only. Web/function apps, slots
and diagnostics are separate modules (`linux-web-app`, `windows-web-app`,
`function-app`, ...).

## Contract

- Required: `name`, `resource_group_name`, `location`, `os_type`, `sku_name`.
- `os_type` is validated (`Linux` / `Windows` / `WindowsContainer`).
- Optional: `worker_count`, `per_site_scaling_enabled`,
  `zone_balancing_enabled`, `maximum_elastic_worker_count`,
  `app_service_environment_id`, `timeouts`, `tags`.

## Lifecycle

| Change | Effect |
|---|---|
| `sku_name` | In-place scale up/down (no replacement) |
| `worker_count`, `per_site_scaling_enabled`, `maximum_elastic_worker_count`, `tags` | In-place update |
| `name`, `resource_group_name`, `location`, `os_type` | Replace |
| `zone_balancing_enabled`, `app_service_environment_id` | Replace |

## State exposure

Outputs: `service_plan_id`, `service_plan_kind`. No secrets.

## Migration

No breaking changes. Interface unchanged.

## Tests

`terraform test` — create + attribute wiring.
