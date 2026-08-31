# terraform-cloudflare-compeer-record-manager

A single Cloudflare DNS record (`cloudflare_record`), for provider v4.

## Contract

- Required: `name`, `type`, `zone_id`.
- `value` is used for value-style records (A, AAAA, CNAME, TXT, ...); the `data`
  map is used for structured records (MX, SRV, CAA, SSHFP, ...). The module
  routes to the right one from the record `type`.
- Optional: `ttl`, `priority`, `proxied`, `comment`, `tags`, `allow_overwrite`,
  `timeouts` (`create` / `update`).

## Lifecycle

| Change | Effect |
|---|---|
| `value` / `data`, `ttl`, `priority`, `proxied`, `comment`, `tags` | In-place update |
| `name`, `type`, `zone_id` | Replace |

## State exposure

Outputs: record `id`, `hostname`, `proxiable`. No secrets.

## Migration

No breaking changes. The dead Azure `data.tf` placeholder and pipeline YAML were
removed; the `timeouts` block no longer misfires on the empty default.

## Tests

`terraform test` (`mock_provider "cloudflare"`) — create an A record + value
wiring.
