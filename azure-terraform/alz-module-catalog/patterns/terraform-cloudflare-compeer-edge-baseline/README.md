# Compeer Cloudflare Edge Baseline

## Overview

**What this deploys:** the Cloudflare-side half of the "all inbound traffic
through Cloudflare Tunnels" posture — the Azure-side connector VMs live in
`cloudflare-connectors`; this pattern owns the DNS/edge control plane those
tunnels terminate into.

| Resource | Purpose |
|---|---|
| `cloudflare_zone.zone` | The DNS zone |
| `cloudflare_record.record` | DNS records (tunnel CNAMEs, etc.) |
| `cloudflare_ruleset.ruleset` | WAF/transform rulesets |

**`terraform_data.tunnel_secret_contract` — what it enforces:** a remotely
managed tunnel needs its secret set consistently on both the Cloudflare and
Azure sides; this contract catches a half-configured tunnel (secret set on
one side but not the other) at plan time instead of a connector silently
failing to authenticate at runtime. See `tests/contracts.tftest.hcl`.

---

Creates the Cloudflare-owned edge/control-plane resources for the external-app ingress path: zones, DNS records, rulesets, Zero Trust tunnels, remotely managed tunnel ingress, and optional Access applications/policies.

Connector VMs are deployed from the Azure `platform-cloudflare-connectors` workspace. Keep tunnel secrets in HCP sensitive variables and import existing Cloudflare resources before assigning Terraform ownership.
