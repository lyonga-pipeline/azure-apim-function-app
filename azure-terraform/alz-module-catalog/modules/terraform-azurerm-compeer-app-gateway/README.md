# terraform-azurerm-compeer-app-gateway

Azure Application Gateway (resource module). WAF policy is passed by ID
(`firewall_policy_id`); diagnostics are composed via
`terraform-azurerm-compeer-diagnostic-settings` at the pattern layer.

Interface mirrors `terraform-azurerm-compeer-application-gateway`; both are
maintained to the same standard. Every repeatable block
(`gateway_ip_configurations`, `frontend_ports`, `http_listeners`,
`backend_address_pools`, `backend_http_settings`, `request_routing_rules`,
`url_path_maps`, `probes`, `ssl_certificates`, `rewrite_rule_sets`, ...) is a
`map(object)` keyed by a stable caller name.

## Inputs (required)

`name`, `resource_group_name`, `location`, `sku` (`{name, tier, capacity?}`),
`gateway_ip_configurations`, `frontend_ports`, `frontend_ip_configurations`,
`http_listeners`, `request_routing_rules`. Everything else is optional with
sensible defaults.

## Outputs

`id`, `name`, `frontend_ip_configuration`, `backend_address_pool_ids`
(name → id), `identity_principal_id`.

## Lifecycle contract

| Change | Result |
|---|---|
| add / remove / edit any keyed block (`backend_*`, `http_listeners`, `request_routing_rules`, `probes`, `ssl_certificates`, `url_path_maps`, ...) | **update in place** — all inline blocks |
| `sku` capacity / `autoscale_configuration` / `firewall_policy_id` / `waf_configuration` / `tags` / `ssl_policy` | update in place |
| `name`, `resource_group_name`, `location` | **replace** |
| moving a `gateway_ip_configuration` to a different subnet | **replace** (Azure ForceNew) |

State exposure: inline `ssl_certificates[*].data` / `password` and
`key_vault_secret_id` values are stored in state — prefer `key_vault_secret_id`
references over inline `data`.

## Migration

Embedded `azurerm_monitor_diagnostic_setting` removed. `create_resource_group` /
`virtual_network_name` / `app_gateway_subnet` name-lookup inputs removed — pass
`gateway_ip_configurations[*].subnet_id` directly. `enable_http2` renamed to
`http2_enabled` (azurerm-v5-ready). All previously `any`-typed blocks are now
concrete `map(object)` types.

## Tests

`terraform test` (offline): minimal valid gateway, additive backend-pool add.
