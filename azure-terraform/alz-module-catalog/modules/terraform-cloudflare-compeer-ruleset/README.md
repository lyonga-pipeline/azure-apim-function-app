# terraform-cloudflare-compeer-ruleset

A single Cloudflare ruleset (`cloudflare_ruleset`), for provider v4 — a phase
entrypoint plus its ordered rules.

## Contract

- Required: `ruleset_kind`, `ruleset_name`, `ruleset_phase`.
- Scope: set **exactly one** of `zone_id` or `cloudflare_account_id` (enforced by
  a precondition). `account_id` is suppressed automatically when `zone_id` is
  set.
- `rules` is a `list(object)` — order is significant to Cloudflare, so this is a
  list, not a map. Each rule has `expression`, `action`, optional `description`,
  `enabled`, `ref`, and an `action_parameters` object.

## Lifecycle

| Change | Effect |
|---|---|
| `rules` add/remove/reorder/retune, `ruleset_name`, `description` | In-place update |
| `ruleset_kind`, `ruleset_phase`, scope (`zone_id` / `account_id`) | Replace |

## State exposure

Outputs: ruleset `id`. No secrets.

## Migration

No breaking changes to inputs. The resource now sets `account_id` / `zone_id`
mutually exclusively and a precondition rejects setting both; the dead Azure
`data.tf` / empty `locals.tf` / pipeline YAML were removed.

## Tests

`terraform test` (`mock_provider`) — zone-scoped create, and both-scopes
rejection.
