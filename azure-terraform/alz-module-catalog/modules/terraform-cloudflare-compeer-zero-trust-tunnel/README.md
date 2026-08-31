# terraform-cloudflare-compeer-zero-trust-tunnel

**Pattern module** (provider v4): a Cloudflare Zero Trust tunnel
(`cloudflare_zero_trust_tunnel_cloudflared`) with its configuration, DNS
records, and optional Access applications + policies composed together.

## Contract

- Required: `account_id`, `name`, `tunnel_secret` (sensitive, base64).
- `ingress_rules` is an ordered list; a catch-all rule using
  `catch_all_service` is always appended.
- `dns_records`, `access_applications`, `access_policies` are keyed
  `map(object)` and default to `{}` — nothing extra is created when omitted.
- **Interface is consumed** by downstream patterns; changes are additive.

## Lifecycle

| Change | Effect |
|---|---|
| `ingress_rules`, `dns_records` add/remove, `access_applications` / `access_policies` add/remove/retune | In-place update |
| `name` | In-place update |
| `account_id`, `tunnel_secret` | Replace the tunnel (and its dependents) |

## State exposure

`tunnel_secret` is stored in Terraform state, and the tunnel token is derived
from it. Outputs: tunnel `id`, `cname`, and maps of the created application /
policy IDs.

## Migration

No breaking changes. Interface unchanged.

## Tests

`terraform test` (`mock_provider`) — create the tunnel, and "no Access resources
by default".
