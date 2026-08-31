# terraform-cloudflare-compeer-zone

A Cloudflare zone (`cloudflare_zone`) and, optionally, a settings override
(`cloudflare_zone_settings_override`), for provider v4.

## Contract

- Required: `account_id`, `zone` (the domain name).
- `zone_plan` is optional and validated against the known plan slugs when set.
- `enable_zone_settings` (default `false`) gates the settings-override resource;
  `settings` is the list of override blocks applied when it is on.
- Optional: `zone_jump_start`, `zone_paused`, `zone_type` (default `full`).

## Lifecycle

| Change | Effect |
|---|---|
| `zone_plan`, `zone_paused`, `zone_jump_start`, `settings` | In-place update |
| `enable_zone_settings` false->true | Creates the settings-override resource |
| `zone`, `account_id`, `zone_type` | Replace |

## State exposure

Outputs: zone `id`, `name_servers`, `status`, `verification_key`. No secrets.

## Migration

No breaking changes. `zone_plan` validation now tolerates the `null` default
(previously errored on the default); pipeline YAML removed.

## Tests

`terraform test` (`mock_provider`) — create + settings-override off by default.
