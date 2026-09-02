# terraform-azurerm-compeer-naming

**Pure utility module** &mdash; the codified implementation of the Landing Zone
naming standard (design doc **Appendix F** / Section 10.4). No providers, no
resources, no data sources: it only computes strings and validates them.

It is deliberately **not** a single generic formula. Appendix F uses a different
token order per resource type (`platform-<region>-<env>-hub-vnet` vs
`<region>-<env>-<purpose>-nsg` vs `<appcode>-<region>-<env>-vault`), so every row
is an explicit pattern here.

## Usage

Call it once in the composition root's `naming.tf`, pass only the tokens the
names you need require, then feed the outputs into the resource/pattern modules.

```hcl
module "naming" {
  source  = "../../modules/terraform-azurerm-compeer-naming"

  region      = "centralus"
  environment = "prod"
  purpose     = "hub"       # only needed for subnet / nsg / policy_initiative
  instance    = 1           # only needed for firewall_vm / cloudflare_connector
}

# module.naming.hub_vnet                # platform-cus-prod-hub-vnet
# module.naming.platform_resource_group # platform-cus-prod-rg
# module.naming.firewall_vm             # platform-cus-prod-fw-01
# module.naming.nsg                     # cus-prod-hub-nsg
```

When published to the private registry, **pin the version** in every consumer.

A name whose required tokens were not supplied is `null` &mdash; reference it and
Terraform stops, which is the intended behaviour.

## Inputs

| Input | Required | Used by |
|---|---|---|
| `region` | yes | almost every name (validated against the approved region list) |
| `environment` | yes | almost every name (`prod\|uat\|test\|dev\|np\|sandbox\|shared`) |
| `domain` | no | `mg_workload_domain*`, `private_dns_zone`, `policy_initiative` |
| `purpose` | no | `subnet`, `nsg`, `policy_initiative` |
| `destination` | no | `route_table` |
| `resource` | no | `public_ip` |
| `appcode` | no | `key_vault` |
| `name` | no | `subscription_workload` |
| `policy`, `scope` | no | `policy_assignment` |
| `instance` | no (default 1) | `firewall_vm`, `cloudflare_connector` (zero-padded) |
| `entra_domain`, `entra_role` | no | `entra_security_group` (`AZ-<DOMAIN>-<Role>`) |

## Outputs

Verbatim Appendix F rows: `mg_enterprise/platform/workloads/sandbox/decommissioned`,
`mg` + `mg_environment` (`<domain>-mg` / `<domain>-<env>-mg`, for any node token),
`subscription_platform/identity/connectivity/management/workload`,
`hub_vnet`, `shared_vnet`, `subnet`, `nsg`, `route_table`, `public_ip`,
`firewall_vm`, `firewall_ilb`, `expressroute_gateway`, `vpn_gateway`,
`cloudflare_connector`, `log_analytics_workspace`, `monitor_workspace`,
`recovery_services_vault`, `key_vault`, `platform_resource_group`,
`policy_initiative`, `policy_assignment`, `entra_security_group`,
`private_dns_zone`, `region_short`.

**ADAPTED** (closest F relative, marked in the output description) — for rows the
table doesn't carry:

| Output | Adapted from | Pattern |
|---|---|---|
| `resource_group` | platform RG | `platform-<region>-<env>[-<purpose>]-rg` (per-capability) |
| `workload_resource_group` | `mg_environment` | `<domain>-<env>-rg` |
| `workload_vnet` | `shared_vnet` | `<domain>-<region>-<env>-vnet` |
| `subscription_scoped` | platform subs | `sub-<purpose>-<env>-<region>` |
| `automation_account` / `action_group` | `monitor_workspace` | `platform-<region>-<env>-{aa,ag}` |
| `bastion` / `nat_gateway` / `route_server` / `ddos_protection_plan` / `private_dns_resolver` | `monitor_workspace` | `platform-<region>-<env>-{bas,natgw,rtsrv,ddos,dnspr}` |
| `network_interface` / `private_endpoint` | `public_ip` | `<region>-<env>-<resource>-{nic,pe}` |
| `domain_controller_vm` | `firewall_vm` | `platform-<region>-<env>-dc-0<n>` |
| `expressroute_circuit` / `expressroute_connection` / `vpn_local_network_gateway` / `vpn_connection` | the gateway rows | `platform-<region>-<env>-{erc,erconn,lng,vpnconn}` |
| `storage_account` | no-separator resource | `st<purpose><region><env>` (lower, ≤24) |
| `user_assigned_identity` | `key_vault` | `<purpose>-<region>-<env>-id` |

## Rules baked in

- Approved region short codes (`centralus` &rarr; `cus`, &hellip;) and the
  approved environment list live **here** &mdash; extend only via a versioned
  change, never ad hoc in a consumer.
- Lowercase + `trimspace` on every token the standard writes lowercase.
  `entra_domain` is upper-cased; `entra_role` case is preserved.
- **No universal truncation.** Length/character rules are applied (as output
  preconditions) only where the resource needs them: Key Vault 3&ndash;24,
  Recovery Services vault 2&ndash;50, Log Analytics 4&ndash;63.
- Management groups, subscriptions, policy and Entra names are handled as their
  own explicit patterns, not derived from an Azure-resource formula.

## Versioning contract

**Any change that alters an already-published name is a breaking major-version
change** &mdash; renaming a resource forces replacement downstream. Treat this
module's name outputs as a frozen interface.

## Tests

`terraform test` &mdash; every Appendix F pattern, token-absent `null` behaviour,
input normalisation, region/environment rejection, and the Key Vault 24-char
guard.
