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
storage names (they must be globally unique). The suffix is appended *after*
truncating the descriptive part of the name to what's left of the 24-char
budget, specifically so a long discriminator/key can never chop the suffix
itself off (that would silently defeat the whole point of it — two
different roots' storage accounts colliding on the same truncated name).

Every other resource type this module names that has a real Azure length
limit is checked the same way, as an output `precondition` that fails the
plan with the actual computed name(s) and the limit, not a generic message:
virtual machines (64 chars), network interfaces / public IPs / load
balancers / private endpoints (80 chars), resource groups (90 chars),
automation accounts (6&ndash;50 chars, must start with a letter), and
user-assigned identities (3&ndash;128 chars), in addition to the pre-existing
Key Vault (3&ndash;24), Recovery Services Vault (2&ndash;50), and Log
Analytics workspace (4&ndash;63) checks. NSGs, route tables, subnets, and
disks have no meaningful Azure length limit at the lengths this module's
patterns can produce, so they're left unchecked.

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

### Legacy single-token inputs (deprecated for new use)

`purpose` / `destination` / `resource` still drive the singular `nsg` /
`route_table` / `public_ip` / `resource_group` (per-component) outputs, for
callers not yet migrated to the `*_keys` front door, and `purpose` remains the
only way to set `policy_initiative` and `load_balancer` (no keyed equivalent
exists for those two). A name whose tokens were not supplied is `null`. **Do
not start a new caller on these three** — see "Two calling conventions" above.

## Inputs

| Input | Required | Used by |
|---|---|---|
| `region` | yes | almost every name (validated against the approved region list) |
| `environment` | yes | almost every name (`prod\|uat\|test\|dev\|np\|sandbox\|shared`) |
| `scope` | no (default `platform`) | selects the platform vs. workload identity/resource-group/stem logic; `platform` or `workload` |
| `component` | no | platform-root discriminator (`management`, `connectivity`, ...) — `resource_group`, `disc`/`disc_abbr` (Key Vault, storage, user-assigned identity keyed names) when `scope = platform` |
| `domain` | no | workload-root discriminator — `mg_workload_domain*`, `workload_resource_group`, `workload_vnet`, `private_dns_zone`, `policy_initiative`, `disc`/`disc_abbr` when `scope = workload`; **required** when `scope = workload` (enforced by a `check` block, not a variable validation — see "Cross-input checks" below) |
| `appcode` | no | optional finer workload discriminator; also drives the legacy singular `key_vault` output |
| `purpose` | no, **deprecated** | legacy `subnet`, `nsg`, `route_table`... discriminator; still the only way to set `policy_initiative` / `load_balancer` |
| `destination` | no, **deprecated** | legacy `route_table` discriminator |
| `resource` | no, **deprecated** | legacy `public_ip` / `network_interface` / `private_endpoint` discriminator |
| `name` | no | `subscription_workload` |
| `policy`, `policy_scope` | no | `policy_assignment` |
| `instance` | no (default 1) | `firewall_vm`, `domain_controller_vm`, `cloudflare_connector` (zero-padded) |
| `entra_domain`, `entra_role` | no | `entra_security_group` (`AZ-<DOMAIN>-<Role>`) |
| `storage_uniqueness` | no (default `""`) | seeds the 4-hex uniqueness suffix on `storage_account_names` entries; pass the subscription ID |
| `key_vault_keys`, `storage_account_keys`, `user_assigned_identity_keys`, `nsg_keys`, `route_table_keys`, `public_ip_keys`, `private_endpoint_keys`, `network_interface_keys`, `load_balancer_keys`, `virtual_machine_keys`, `disk_keys`, `recovery_services_vault_keys`, `subnet_keys` | no (default `[]`) | the front door — one list per keyed resource type; produces the matching `*_names` map output |

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

## Cross-input checks (`checks.tf`)

A variable's own `validation` block can only see that one variable, so three
identity/collision problems that span multiple inputs are enforced as
module-level `check` blocks instead, each with a plan-time error naming the
actual problem:

- **`platform_scope_needs_component_for_keyed_disc_abbr_resources`** —
  `scope = "platform"` with no `component` set, requesting any of
  `key_vault_keys` / `storage_account_keys` / `user_assigned_identity_keys`,
  falls back to the generic `"platform"` discriminator (`disc_abbr` `"plat"`)
  for those names. Two different platform roots that both forget `component`
  would compute identical names. Caught here instead of silently succeeding.
- **`workload_scope_needs_domain`** — `scope = "workload"` with no `domain`
  already crashes when `local.stem` tries to interpolate a null value, but
  with an internal, unattributed Terraform error. This check gives the exact
  same situation a clear, actionable message instead.
- **`keyed_names_have_no_case_collisions`** — two keys in the same `*_keys`
  list that only differ by case (`"Primary"` vs. `"primary"`) lower-case into
  the *same* rendered name — a real Azure-side collision hiding behind two
  distinct `for_each` keys, not a Terraform-level error. Checked once, across
  every keyed collection at once, rather than repeating the same
  `distinct(values(...))` assertion in all thirteen keyed outputs.

`check` blocks (Terraform &ge;1.5, matching this module's `required_version`)
were chosen over adding these as variable `validation` blocks because a
`validation` block can only reference the variable it's declared on in
Terraform versions before 1.9, and this module supports 1.5+.

## Rules baked in

- Approved region short codes (`centralus` &rarr; `cus`, &hellip;) and the
  approved environment list live **here** &mdash; extend only via a versioned
  change, never ad hoc in a consumer.
- Lowercase + `trimspace` on every token the standard writes lowercase.
  `entra_domain` is upper-cased; `entra_role` case is preserved.
- **No silent universal truncation.** Length/character rules are applied (as
  output preconditions) per resource type — see "Length constraints" above
  for the full list. The one place this module truncates instead of failing
  is `storage_account`/`storage_account_names` (Azure storage names can't
  exceed 24 chars and there's no shorter alternative to fall back to), and
  even there the uniqueness suffix is protected from truncation - see "Length
  constraints" above.
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

1. **Confirm the approved naming standard.** Check Appendix F itself (or
   whoever owns the design doc) for a verbatim row before assuming ADAPTED is
   right. If none exists, find the closest existing relative in `main.tf`'s
   `names` map (a load-balanced network appliance, a diagnostic sink, a
   per-key managed resource, ...) and reuse its token order and separators
   unless you have a documented reason not to.
2. **Add a keyed input for anything a root may deploy more than one of.** A
   new keyed resource gets a `<resource>_keys` list variable, `default = []`,
   in the "Instance keys" section of `variables.tf`. Don't add a new singular
   `purpose`/`destination`/`resource`-style legacy token for a resource type
   that can have multiples — that's exactly the pattern this module is moving
   away from (see "Two calling conventions" above).
3. **Add the explicit formula.** A true singleton (region+env is the whole
   identity, or Appendix F names it as fixed) goes in `local.names`; anything
   keyed goes in `local.keyed`, following the `{ for k in var.X_keys : k =>
   "..." }` shape every other keyed row uses. Guard any token the pattern
   needs with `local.X == null ? null : "..."` so an unsupplied token fails
   loud (`null` referenced downstream) rather than silently baking in an
   empty string or a wrong-but-plausible name.
4. **Add a stable output** in `outputs.tf`, next to the closest relative, with
   a `description` that states the exact pattern in the same
   `<token>-<token>-...` shorthand every other description uses, and whether
   it's a verbatim Appendix F row or `ADAPTED (closest: <row>)`.
5. **Implement Azure length and character validation** as an output
   `precondition` — fail at plan time with the actual computed value(s), the
   real Azure limit, and which input to shorten, not a generic message.
   Confirm the real constraint (Microsoft's published "Naming rules and
   restrictions for Azure resources" reference, not a guess) before writing
   the check.
6. **Test at least one platform name and one workload name** (if the resource
   type applies to both scopes) — assert the exact string, not just that it's
   non-null.
7. **Test invalid input, maximum length, and normalized collisions** — a
   `run` block with `command = plan` and `expect_failures` for: a token long
   enough to blow the new precondition, and (if the row is keyed) two keys
   that only differ by case, to confirm `keyed_names_have_no_case_collisions`
   in `checks.tf` catches your new resource type too (it's generic across
   every entry in `local.keyed`, so a new keyed row is covered automatically
   — write the test to prove it, don't assume it). Follow the existing
   `rejects_*` runs in `tests/defaults.tftest.hcl` as templates.
8. **Document whether the formula is authoritative or adapted** — the
   `description` in step 4 already carries this; also add the output to this
   README's verbatim list or ADAPTED table (whichever applies), and the input
   to the Inputs table if you added one.
9. **Identify whether the change is backward compatible.** A brand-new
   output/local is additive and safe. Changing the string an *existing*
   output produces for inputs already in use in a real, applied tfvars is a
   **major-version, breaking change** (see "Versioning contract" below) — it
   is never "just a small tweak," because it forces resource replacement
   downstream.
10. **Update the consuming pattern to call the new output**, not to construct
    the name itself — add the `*_keys` input to the pattern's existing
    `module "naming"` call (front door — see "Two calling conventions" above)
    and read `module.naming.<resource>_names[key]` in the resource's
    `for_each`. Don't add a new per-instance `module "naming_xxx" { for_each =
    ... }` block, and don't hand-build the string in the consuming pattern
    even "just this once."

If your new row also needs an `abbr` entry (Key Vault/storage-account-style
character budget, keyed off a `component`/`domain`/`appcode` not already in
the map) or new `abbr` extension, add it as part of step 3 — see "The `abbr`
map and `disc_abbr`" above.

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

`terraform test` &mdash; 22 runs: every Appendix F pattern, token-absent `null`
behaviour, input normalisation, region/environment rejection, the Key Vault
24-char guard, the storage-suffix-survives-truncation fix, all three
cross-input checks (`checks.tf`), and the new resource-group /
network-interface / virtual-machine length preconditions.
