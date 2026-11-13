# Cloudflare Edge Workspace

This root configures Cloudflare, not Azure connector VMs. The deployable
`terraform.tfvars` stays disabled until approved tenant values are supplied.
[example.tfvars](example.tfvars) shows a final-publication enterprise configuration:
one shared nonprod tunnel, one prod tunnel, protected hostnames, a zone, Access
applications/policies, and custom plus managed WAF rulesets.

## Adapt the Example

1. Replace example hostnames/origins, account IDs, team slug, IdP/Access-group and
   posture IDs, managed-WAF ID and change approvals with approved values. Session
   durations and policy requirements are examples, not an approved Compeer policy.
2. Establish ownership before changing zones/rulesets. Import existing owned
   resources and their complete configuration; do not overwrite other teams'
   rules. If the zone stays externally owned, use `zones = {}` and replace each
   `zone_key` with its existing `zone_id`.
3. Keep `records = {}`: the enterprise root deliberately rejects generic records.
   Populated application CNAMEs belong in each tunnel's `dns_records` instead.
4. Omit the placeholder `cloudflare_tunnel_secrets` assignment from deployed
   tfvars. Supply independent creation secrets as a sensitive Terraform-category
   HCP input; supply `CLOUDFLARE_API_TOKEN` as a sensitive environment input.
   Neither real creation secrets nor runtime tokens belong in Git.
5. Start with both tunnel `dns_records` maps empty. Apply security configuration,
   synchronize runtime tokens to the approved vault secrets, then deploy/verify
   connectors and private origins. Add DNS only after release acceptance.

`example.tfvars` is not automatically loaded. Merge reviewed non-secret values
into the deployed tfvars, or explicitly select it using `-var-file` in an isolated
test workspace. Do not apply its placeholders. The default disabled tfvars and a
populated example must not be confused with a ready-to-apply tenant configuration.

## Diagram and Azure Handoff

| Cloudflare tunnel key | Windows replicas | Runtime-token secret |
|---|---|---|
| `external_nonprod` | `np01`, `np02`, zones 1 and 2 | `cloudflare-nonprod-token` |
| `external_prod` | `prod01`, `prod02`, zones 1 and 2 | `cloudflare-prod-token` |

The supplied diagram's initial layout puts all four replicas in the existing
Central US hub's `prod-cftagent-subnet`. The connector root resolves its subnet
from the hub producer workspace outputs. Confirm IPAM and permits before rollout.
The hub's production label does not turn a nonprod tunnel into a prod tunnel;
token assignment and approved network reachability establish the boundary.

Origin owners must provide private App Gateway/API Management/App Service or
other HTTPS endpoints, disable/restrict public access as appropriate for each
Azure service, and verify firewall/DNS/return paths. This Cloudflare root cannot
disable Azure public access. Multiple replicas are HA, not application-aware
load balancing or automatic multi-region recovery.

See the [edge pattern guide](../../../../patterns/terraform-cloudflare-compeer-edge-baseline/README.md)
for security wiring and controls, and the
[connector pattern guide](../../../../patterns/terraform-azurerm-compeer-cloudflare-connectors/README.md)
for Windows installation, token retrieval and rollout.

The mocked test in `example-tests/example.tftest.hcl` expects a sanitized copy of the
populated example with synthetic valid IDs/secrets. It checks topology and
security composition, not live Cloudflare, Windows or origin readiness.

After `terraform init -backend=false`, run `python3 example-tests/verify_example.py`.
It reads the actual example through Terraform's parser, substitutes only synthetic
placeholder IDs/creation secrets in a temporary file, and runs the mocked plan.
It does not use a Cloudflare API token or apply infrastructure.
