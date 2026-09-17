# terraform-azurerm-compeer-naming

**Pure utility module** &mdash; the codified implementation of the Landing Zone
naming standard (design doc **Appendix F** / Section 10.4). No providers, no
resources, no data sources: it only computes strings and validates them.

It is deliberately **not** a single generic formula. Appendix F uses a different
token order per resource type (`platform-<region>-<env>-hub-vnet` vs
`<region>-<env>-<purpose>-nsg` vs `<appcode>-<region>-<env>-vault`), so every row
is an explicit pattern here. This trades a bit of extra code (one local + one
output per resource type) for the property that every name in this file is
provably the standard's own row, not a generic template's approximation of it.

## Usage — the front door (recommended for every new caller)

Call it **once inside the pattern (or once per root)**. Give it the root's
identity plus the map keys of every keyed resource the root deploys; it
returns every name in one shot.

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

## Two calling conventions exist in this catalog today — use the front door for anything new

There are, in practice, **two different ways** this module gets called across
the catalog, and they are not equally good:

1. **The front door (above)** — one `module "naming"` instance per root, keyed
   list inputs (`nsg_keys`, `private_endpoint_keys`, ...), map outputs
   (`nsg_names`, `private_endpoint_names`, ...). This is the only style
   documented for new use.
2. **Per-instance legacy calls** — a *separate* `module "naming_xxx"` block
   **per resource type, `for_each`'d over the resource map itself**, each
   passing one of the single-token legacy inputs (`purpose`, `destination`,
   `resource`, `instance`) and reading back a singular output
   (`module.naming_nsg[k].nsg`, `module.naming_pip[k].public_ip`, ...).

Convention 2 predates convention 1 and is still how every **workspace-level**
`naming.tf` in `implementations/platform-lz/workspaces/` calls this module
today (`platform-workload-spoke`, `platform-directory-services`,
`platform-cloudflare-connectors`, `platform-palo-alto`) — one extra module
instance per NSG, route table, private endpoint, NIC, load balancer, public IP,
domain controller, or firewall VM the root has. It still produces
standard-compliant names (the singular and keyed outputs for the same resource
type render the same string for a platform-scoped caller), so nothing there is
*wrong* — it is just the style the front door was built to replace, and it is
more module instantiations than the same root would need under convention 1.
**Do not add a new `module "naming_xxx" { for_each = ... }` block** — add the
resource's keys to the existing `module "naming"` call's `*_keys` input instead
(see "Adding a new resource type" below for the one case, keyed singleton rows,
where a `for_each` naming call is still the right tool).

The four **pattern-level** callers (`platform-management`,
`platform-connectivity`, `platform-identity`, `platform-hybrid-connectivity`)
all use the front door consistently — same `region`/`environment`/`scope`/
`component` identity block, same `storage_uniqueness` handling, keyed inputs
matched one-to-one with their actual keyed resources.

### Not every root uses this module

Several patterns currently build every resource `name` straight from tfvars
with no naming-module default at all: `global-governance`,
`platform-authorization`, `platform-policy`, `privileged-access`,
`subscription-onboarding`, `subscription-vending`, `workload-identity`,
`network-peering`, and the Cloudflare edge patterns. For most of these the
module already has the exact output they'd need
(`mg`/`mg_environment`, `subscription_platform`/`subscription_scoped`,
`policy_initiative`/`policy_assignment`, `entra_security_group`) — they simply
haven't been wired up yet. If you're touching one of these roots and adding a
computed default name is in scope, prefer wiring it to this module over hand-
rolling a `coalesce(try(x.name, null), key)` fallback, which enforces nothing
about the standard. Bumping an *already-deployed* resource's name is a
breaking, replacement-forcing change (see "Versioning contract" below) — if
the root might already be applied for real, treat this as a default for *new*
entries only, the same way `directory-services/naming.tf` already does for its
DC VM naming deviation.

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

### Keyed vs. singleton-only outputs

Most resource types have **both** a legacy singular output (single token,
`null` until supplied) and a keyed map output (`*_keys` in, `*_names` map out):
`key_vault`, `storage_account`, `user_assigned_identity`, `nsg`, `route_table`,
`public_ip`, `private_endpoint`, `network_interface`, `load_balancer`,
`virtual_machine`, `disk`, `recovery_services_vault`, `subnet`.

Two do **not**: `firewall_vm` and `domain_controller_vm`. Both are `instance`-
based (`platform-<region>-<env>-{fw,dc}-0<n>`), and no `*_keys`/`*_names` pair
exists for either today. A root that needs more than one (two firewalls, two
domain controllers) has to fall back to a `for_each`'d `module "naming_xxx"`
call today (see `platform-palo-alto/naming.tf`'s `naming_vm` and
`platform-directory-services/naming.tf`'s `naming_dc`) — this is the one
legitimate remaining use of the per-instance style, not a migration gap, unless
you also add the keyed variant (see below).

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

### The `abbr` map and `disc_abbr`

Key Vault and storage-account names are character-budget-constrained (24
chars), so they use `disc_abbr` — a short form of the root's discriminator
(`local.disc`: `component` for platform roots, `appcode`/`domain` for workload
roots) — instead of the full word. `disc_abbr` is looked up from the `abbr` map
in `main.tf`:

```hcl
abbr = {
  management = "mgmt"
  connectivity = "conn"
  # ...
}
```

**If your root's `component`/`domain`/`appcode` is not in `abbr`**, `disc_abbr`
silently falls back to `substr(replace(local.disc, "-", ""), 0, 10)` — the
discriminator itself, hyphens stripped, truncated to 10 characters. This never
errors, but it means an unlisted long or hyphenated component produces a longer
and less polished Key Vault/storage prefix than a deliberately chosen
abbreviation would (and two similarly-named unlisted components could
truncate to something less obviously distinct). **Add an entry to `abbr`
whenever you introduce a new platform `component` or workload `domain`** that
will own a Key Vault or storage account, even though the module will still run
without one.

## Extending: adding a new resource type

Appendix F doesn't cover every Azure resource type this catalog will ever
need, and the design doc's own instruction is to adapt the closest relative
rather than invent an unrelated shape. To add a new one:

1. **Find the closest existing row.** Skim `main.tf`'s `names` map for a
   resource in the same family (a load-balanced network appliance, a
   diagnostic sink, a per-key managed resource, ...). Reuse its token order
   and separators unless you have a documented reason not to.
2. **Add the pattern to `main.tf`.** A singleton goes in `local.names` next to
   its closest relative, with a one-line comment stating whether it's a
   verbatim Appendix F row or `# ADAPTED (closest: <row>)` and why. A resource
   a root may deploy more than one of goes in `local.keyed` instead, following
   the `{ for k in var.X_keys : k => "..." }` shape every other keyed row uses.
   Guard any token the pattern needs with `local.X == null ? null : "..."` so
   an unsupplied token fails loud (`null` referenced downstream) rather than
   silently baking in an empty string.
3. **Add the variable(s).** A new singleton token goes in the "Identity" or
   "Legacy single-token inputs" section of `variables.tf` with a `default =
   null` (never required — see "how roots differ" above; a root that doesn't
   need this name shouldn't have to supply anything for it). A new keyed
   resource gets a `<resource>_keys` list variable, `default = []`, in the
   "Instance keys" section.
4. **Add the output(s) in `outputs.tf`**, next to the closest relative, with a
   `description` that states the exact pattern in the same
   `<token>-<token>-...` shorthand every other description uses. If the target
   Azure resource has a real length or character-set constraint, add a
   `precondition` block like the Key Vault or Recovery Services Vault ones —
   fail at plan time with the actual computed value(s) and the reason, not a
   generic message.
5. **Update `abbr`** if the new row is character-budget-constrained and keys
   off a `component`/`domain`/`appcode` that isn't already in the map (see
   above).
6. **Add a test run** in `tests/defaults.tftest.hcl` — assert the exact string
   for at least one populated case and, if the tokens are optional, that the
   output is `null` when they're withheld (follow the existing
   `core_platform_names_region_and_env_only` / `token_dependent_names` runs as
   templates). `terraform test` is the only thing standing between "matches
   Appendix F" and "looks close enough" — don't skip it.
7. **Update this README** — add the output to the appropriate table above
   (verbatim list, ADAPTED table, or a new row if it doesn't fit either), and
   the input to the Inputs table if you added one.
8. **Call it from the front door**, not a new per-instance `module "naming_xxx"`
   block (see "Two calling conventions" above) — add the new `*_keys` input to
   the pattern's existing `module "naming"` call and read `module.naming.
   <resource>_names[key]` in the resource's `for_each`.

None of this touches an *existing* output's pattern - see the versioning
contract below for why that's a different, much more careful kind of change.

## Versioning contract

**Any change that alters an already-published name is a breaking major-version
change** &mdash; renaming a resource forces replacement downstream. Treat this
module's name outputs as a frozen interface. Adding a brand-new output/local
(the "Extending" steps above) is additive and safe; changing the string an
*existing* output produces for inputs that are already in use in a real,
applied tfvars is not — coordinate that as a deliberate, versioned migration
(new resource created alongside the old, old one decommissioned), not a silent
tfvars edit.

## Tests

`terraform test` &mdash; every Appendix F pattern, token-absent `null` behaviour,
input normalisation, region/environment rejection, and the Key Vault 24-char
guard.
