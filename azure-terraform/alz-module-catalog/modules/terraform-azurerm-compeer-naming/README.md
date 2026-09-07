# terraform-azurerm-compeer-naming

**Pure utility module** &mdash; the codified implementation of the Landing Zone
naming standard (design doc **Appendix F** / Section 10.4). No providers, no
resources, no data sources: it only computes strings and validates them.

It is deliberately **not** a single generic formula. Appendix F uses a different
token order per resource type (`platform-<region>-<env>-hub-vnet` vs
`<region>-<env>-<purpose>-nsg` vs `<appcode>-<region>-<env>-vault`), so every row
is an explicit pattern here.

## Usage — the front door

Call it **once inside the pattern**. Give it the root's identity plus the map
keys of every keyed resource the root deploys; it returns every name.

```hcl
module "naming" {
  source      = "../../modules/terraform-azurerm-compeer-naming"

  # identity - what makes this root's names differ from another root's
  region      = var.naming.region        # "centralus"
  environment = var.naming.environment    # "prod"
  scope       = "platform"                # platform | workload
  component   = "management"              # platform discriminator
  # for workloads instead:  scope = "workload", domain = "internal-apps", appcode = "orders"

  # instance keys - one list per keyed resource type the root deploys
  key_vault_keys              = keys(var.key_vaults)          # ["primary", "secrets"]
  storage_account_keys        = keys(var.storage_accounts)    # ["audit", "diag"]
  recovery_services_vault_keys = keys(var.recovery_vaults)
}

# singletons
module.naming.resource_group          # platform-cus-prod-management-rg
module.naming.log_analytics_workspace # cus-prod-loganalytics-workspace
module.naming.action_group            # platform-cus-prod-ag

# keyed - one name per map key
module.naming.key_vault_names           # { primary = "mgmt-cus-prod-primary-kv", secrets = "mgmt-cus-prod-secrets-kv" }
module.naming.storage_account_names     # { audit = "stmgmtauditcusprod", diag = "stmgmtdiagcusprod" }
```

The pattern then does `coalesce(try(each.value.name, null), module.naming.key_vault_names[each.key])`
so a `name` set in tfvars still wins.

### How roots differ, same region + environment

| Root | identity | resource group | KV key `primary` |
|---|---|---|---|
| management | `component = "management"` | `platform-cus-prod-management-rg` | `mgmt-cus-prod-primary-kv` |
| connectivity | `component = "connectivity"` | `platform-cus-prod-connectivity-rg` | &mdash; |
| workload internal-apps | `domain = "internal-apps"` | `internal-apps-cus-prod-rg` | `intapps-cus-prod-primary-kv` |
| workload orders | `domain = "internal-apps", appcode = "orders"` | `internal-apps-orders-cus-prod-rg` | `orders-cus-prod-primary-kv` |

`component` / `domain` / `appcode` distinguishes **roots**; the map key
(`primary`, `audit`) distinguishes **instances inside a root**.

### Length constraints

Key Vault and storage-account names are &le;24 chars. The module fails the plan
with a clear message (and the exact character budget) if a computed name is too
long &mdash; **keep Key Vault / storage map keys short** (`sec`, `app`, `hsm`,
`audit`). Set `storage_uniqueness = <subscription id>` for a 4-hex suffix on
storage names (they must be globally unique).

### Legacy single-token inputs

`purpose` / `destination` / `resource` still drive the singular `nsg` /
`route_table` / `public_ip` / `resource_group` (per-component) outputs, for
callers not yet migrated to the `*_keys` front door. A name whose tokens were
not supplied is `null`.

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
