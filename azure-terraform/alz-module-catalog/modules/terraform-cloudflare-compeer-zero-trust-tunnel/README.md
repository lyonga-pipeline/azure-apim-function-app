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
| `ingress_rules` | Update the tunnel configuration |
| Add/remove DNS or Access map keys | Create/delete those objects; this is not a pause or just a state rename |
| Retune an existing DNS/Access entry | Review the provider plan for update/replacement |
| `name` | In-place update |
| `account_id`, `tunnel_secret` | Replace the tunnel (and its dependents) |

## State exposure

`tunnel_secret` is stored in Terraform state, and the tunnel token is derived
from it. Outputs: tunnel `id`, `cname`, and maps of the created application /
policy IDs.

## Migration

DNS input/output keys are unchanged. Records now use the package's shared
`modules/dns-records` implementation, also consumed by the edge pattern.
A `moved` block maps the previous `cloudflare_record.record` collection to
`module.dns_records.cloudflare_record.record`. Run init and review the plan;
existing records should retain their IDs without recreation. Keep the moved
block for consumers upgrading older states.

## Tests

`terraform test` uses mocks to cover tunnel creation, Access/JWT wiring and DNS
ID preservation across the shared-module move. Migration tests require Terraform
1.11+; they do not contact Cloudflare or prove live deployment readiness.
