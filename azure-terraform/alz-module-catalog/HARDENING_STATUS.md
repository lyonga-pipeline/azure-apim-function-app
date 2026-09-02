# ALZ Module Catalog — Hardening Status

Branch: `harden/alz-module-catalog`. Baseline: `modules-fully-redesigned.zip` overlaid onto `modules/`.

Standard applied per module (from `Enterprise_Terraform_Module_Architecture_Review.docx` + the 10 principles):

- Single `versions.tf`: `terraform >= 1.5, < 2.0`; bounded provider (`azurerm >= 4.42, < 5.0`, `azuread >= 3.0, < 4.0`, `cloudflare >= 4.11, < 5.0`).
- Every input explicitly typed; no `any` / `map(any)`; optional nested blocks as `optional(object(...))`, repeatables as `map(object(...))` with caller-stable keys.
- `validation` blocks for enumerated / bounded inputs; `sensitive = true` on bare secret strings (not on objects feeding `for_each`).
- No blanket `ignore_changes`; no hidden Resource Group / shared-infra creation.
- Stable outputs: at least `id` + `name` + attributes a downstream module needs;
  **`description` on every output**; `for_each` resources expose caller-keyed maps
  (`subnet_ids["<key>"]`, `*_ids`) so consumers never hardcode a name or ID;
  identity `principal_id` / `tenant_id` are `try(...[0]..., null)` null-safe;
  no raw resource-object outputs. See "Phase 5" below.
- `timeouts` passthrough where the provider resource supports it.
- README: contract summary + **lifecycle matrix** (which input changes update-in-place vs replace) + state-exposure note + migration notes for any breaking change.
- `tests/*.tftest.hcl`: plan-mode `run` blocks with synthetic fixture values (create, no-op, mutate, optional-block add/remove).

## Phase 1 — correctness + baseline contract  ✅ COMPLETE

- 103/103 `terraform fmt` clean, 103/103 `terraform validate` clean.
- `versions.tf` standardised across all 100 code modules; stray `requirements.tf` / inline `terraform{}` blocks folded in.
- 16 modules had real bugs fixed (azurerm 3→4 schema drift, malformed HCL, `sensitive` objects breaking `for_each`).
- 3 empty modules implemented: `linux-web-app-slot`, `windows-web-app-slot`, `keyvault-managed-storage-account`.
- 111 untyped variables across 38 modules given explicit types.

## Phase 2 — per-module deep hardening + tests + docs

Legend: ☐ todo · ◐ in progress · ☑ done (contract + tests + README + validate/test pass)

Consumer counts (from `implementations/`) drive how aggressively each module's
interface may change: 0-consumer modules get full naming normalization + a
Migration section; consumed modules keep a backward-compatible interface and gain
capability through new optional inputs only.

### Batch A — legacy composites / boundary review
- ☑ terraform-azurerm-compeer-networking — 0 consumers; normalized `name`/`address_space`, dropped `create_*` toggles + standalone dns_servers resource, `subnets` map(object) with `optional()` + 3 validations, `id`/`name`/`subnets` outputs, `timeouts`, README lifecycle matrix + migration, `tests/defaults.tftest.hcl` (4 runs, pass)
- ☑ terraform-azurerm-compeer-private-dns — 0 consumers; single-zone → multi-zone `map(object)` keyed by zone name, per-zone `vnet_links` map with composite `zone/link` keys, `soa_record` optional object, zone-name validation, `zone_ids`/`zones`/`vnet_link_ids` outputs, README + migration (`moved` blocks documented), tests (3 pass)
- ☑ terraform-azurerm-compeer-route-tables — 0 consumers; `route_table_name`→`name`, `routes` `list(map(string))` → `map(object)` keyed by route name, `next_hop_type` + appliance-IP validations, `bgp_route_propagation_enabled` default `true`, dropped `output.routes`/`output.tags` echoes, `timeouts`, README + migration, tests (3 pass)
- ☑ terraform-azurerm-compeer-keyvault — **3 consumers; interface kept stable**. Redesign had silently broken it (list→map `access_policies`, dropped `access_policies_by_key`, `contacts` list→map). **Restored** list+keyed access policies (merged in `main.tf` locals), list `contacts`. Fixed `network_acls` null-deref validation bug. README + migration, tests (4 pass, incl. list+keyed merge)
- ☑ terraform-azurerm-compeer-key-vault — 0 consumers; added var descriptions, fixed same `network_acls == null || x.attr` null-deref validation bug (→ ternary), README + migration, tests (4 pass)
- ☑ terraform-azurerm-compeer-keyvault-assets — 0 consumers; `key_type` validation, removed "deprecated" comment, README + lifecycle matrix + state-exposure note, tests (4 pass)
- ☑ terraform-azurerm-compeer-apim — 0 consumers; embedded diagnostics already stripped by redesign; added `sku_name` regex validation, `timeouts` (1h30m defaults), `min_api_version`/`client_certificate_enabled`/`zones` inputs, richer outputs (identity/IPs/mgmt URL), renamed `security.*`/`protocols.*` to azurerm-v5-ready attribute names, removed "deprecated" banner, README + migration, tests (4 pass)
- ☑ terraform-azurerm-compeer-actiongroup — 0 consumers; interface already converged with `action-group` by redesign; `short_name` 1–12 validation, removed stale `test/` fixture + "deprecated" banner, README, tests (3 pass)
- ☑ terraform-azurerm-compeer-app-gateway — 0 consumers; redesign already typed all `any` blocks + stripped diagnostics; `enable_http2`→`http2_enabled` (v5-ready, **also fixed in `application-gateway`**), descriptions, richer outputs, README + migration, tests (2 pass)

**Batch A complete (9 modules).** Cross-batch touches: `action-group` (short_name validation + description + shared test, from Batch E), `virtual-network` (validation null-deref fix, from Batch D), `application-gateway` (`http2_enabled` rename, from Batch F).

**Catalog-wide finding — SWEPT:** `x == null || x.attr` in `validation` AND
`lifecycle.precondition` conditions throws on the null default in TF 1.7 — must be
`x == null ? true : x.attr`. Fixed in `keyvault`, `key-vault`, `virtual-network`,
`windows-vm`, `app-configuration`, `service-bus`, `storage-account`,
`linux-virtual-machine`, `windows-virtual-machine`. (Scalar `x == null || contains(...,x)`
with no `.attr` deref is safe and left as-is.)

**Catalog-wide finding — SWEPT:** azurerm 4.x deprecated `enable_http2` →
`http2_enabled` (`app-gateway`, `application-gateway`) and `enable_automatic_updates`
→ `automatic_updates_enabled` (`windows-vm`, `windows-virtual-machine`,
`test-availabilityset-sql`). `security.enable_*` / `protocols.enable_http2` on APIM
→ `*_enabled` forms (`apim`). Watch for more `enable_*` deprecations per module.

**Test convention:** `mock_provider "azurerm" {}` + `command = apply` for asserting
on resource attributes (plan-mode leaves mock attrs unknown); `command = plan` +
`expect_failures` for validation/precondition checks. `terraform test` needs
`terraform init -plugin-dir=<mirror>` first.

### Batch B — compute (VMs, web/function apps + slots)
- ☑ terraform-azurerm-compeer-windows-vm — 1 consumer (directory-services); interface kept; descriptions, `patch_mode` validation, `automatic_updates_enabled` rename, precondition null-deref fix, `computer_name`/`identity_principal_id` outputs, README + migration, tests (4 pass)
- ☑ terraform-azurerm-compeer-windows-vm-domain-join — 1 consumer; interface kept; descriptions, `join_options` 0–63 validation, README (KV-protected-settings path documented) + migration, tests (3 pass)
- ☑ terraform-azurerm-compeer-linux-virtual-machine — 0 consumers; redesign already reduced to lean single VM. Removed 5 placeholder .tf + `go.mod`/`go.sum` + Terratest `test/`. Normalized `virtual_machine_name`→`name`, `resource_group_location`→`location`, `virtual_machine_size`→`vm_size`, `availability_zone`→`zone`; outputs `virtual_machine_id`→`id` etc; `patch_mode` validation; descriptions; precondition null-deref fixed. README + migration, tests (4 pass, uses a real throwaway RSA key for the SSH-key format check)
- ☑ terraform-azurerm-compeer-windows-virtual-machine — 0 consumers; same treatment as linux-virtual-machine (removed placeholders + `data.tf` + `go.mod`/`go.sum` + `templates/formatDisk.ps1.tpl` + `test/`; naming + outputs normalized; `automatic_updates_enabled` rename). README, tests (3 pass)
- ☑ terraform-azurerm-compeer-windows-mssql-vm — 0 consumers; redesign already lean (SQL config for an existing VM). Removed placeholders + `data.tf`. `sql_connectivity_update_username`/`_password` made optional (`null`) + precondition requiring them unless connectivity is LOCAL; `sql_connectivity_type` + `sql_license_type` validation; output `mssql_virtual_machine_id`→`id`. README, tests (5 pass)
- ☑ terraform-azurerm-compeer-linux-web-app — 0 consumers; **was non-functional**: removed dead `data.azurerm_monitor_diagnostic_categories` + unused locals (caused apply failures), rewrote all `site_config` nested `dynamic` for_each from `lookup(obj,"k",null)` (returns null on typed objects) to `obj.k == null ? [] : ...`, fixed wrong `.value` chains, renamed outputs `webapp_id`→`id` etc + null-safe `identity_principal_id`, `site_config` length-1 validation. README + migration + follow-up note. tests (3 pass)
- ☑ terraform-azurerm-compeer-windows-web-app — 0 consumers; same fixes as linux-web-app (dead diag data source, site_config for_each, stray commented `variable` blocks removed, outputs). README, tests (3 pass)
- ☑ terraform-azurerm-compeer-windows-function-app — 0 consumers; fixed 2 broken `.value` chains in site_config, outputs normalized (dropped input-echoes, null-safe principal_id), `site_config` length-1 validation. `ignore_changes` already gone. README, tests (3 pass)
- ☑ terraform-azurerm-compeer-linux-web-app-slot — new module (Phase 1); README + lifecycle matrix, tests (2 pass)
- ☑ terraform-azurerm-compeer-windows-web-app-slot — new module (Phase 1); README, tests (2 pass)
- ☑ terraform-azurerm-compeer-keyvault-managed-storage-account — new module (Phase 1); README + lifecycle matrix + state-exposure note, tests (2 pass; SAS-definition path validate-only — mock provider can't parse the parent ID at plan time)
- ☑ terraform-azurerm-test-availabilityset-sql — kept per user; README rewritten to mark it clearly as a **reference composition / example, NOT a certified module** (do not `source` it). Validate-clean; intentionally no typed contract or test suite (it's a fixture).

**Batch B complete (12 modules).**

### Batch C — identity & RBAC  ✅ COMPLETE (7 modules)
- ☑ terraform-azuread-compeer-ad-application — 0 consumers; `api`/`public_client` `list`→`object`; `app_role`/`required_resource_access` `list`→`map` (stable keys); `web.implicit_grant`→optional + fixed its `for_each` (was treating an object as a bool → plan failure); `sign_in_audience` + member-type validation; removed dead data source. tests (4 pass)
- ☑ terraform-azuread-compeer-ad-group — 0 consumers; `security_enabled` default null→true; `visibility` validation; `id`/`display_name` outputs; removed dead data source. tests (3 pass)
- ☑ terraform-azuread-compeer-service-principal — 0 consumers; fixed `contains(list, null)` crash in `preferred_single_sign_on_mode` validation (also fixed same in `budget`); `id` output; descriptions. tests (2 pass)
- ☑ terraform-azuread-compeer-ad-application-certificate — (done in Phase-1 correctness: `application_object_id`→`application_id` + shim, outputs added). tests pending — add in a sweep.
- ☑ terraform-azurerm-compeer-user-assigned-identity — 2 consumers, interface kept; descriptions, `name`/`tenant_id` outputs. tests (1 pass)
- ☑ terraform-azurerm-compeer-role-definition — 1 consumer, interface kept; descriptions. tests (2 pass)
- ☑ terraform-azurerm-compeer-role-assignments — **10 consumers, interface frozen**; tests + README only. tests (3 pass)
- ☑ terraform-azurerm-compeer-apim-identity-aad-aad2bc — 0 consumers; `aad.allowed_tenants` made required (provider requires it); descriptions + output descriptions. tests (2 pass)

**New catalog-wide finding — SWEPT:** `x == null || contains(list, x)` in
validations crashes (`contains` rejects null) — same fix `x == null ? true : …`.
Fixed in `service-principal`, `budget`.

### Batch D — networking resources  ✅ COMPLETE (24 modules)
- ☑ subnet-route-table-association, nsg-subnet-association — descriptions, tests, READMEs (keep interface)
- ☑ ddos-protection-plan — descriptions, test, README
- ☑ local-network-gateway — descriptions, tests (2), README
- ☑ public-ip — 5 consumers, interface kept; `allocation_method`/`sku` validation + Standard-requires-Static precondition; tests (3)
- ☑ private-dns-zone — 1 consumer; zone-name validation; tests (2)
- ☑ private-dns-vnet-link — 3 consumers, interface kept; test + README
- ☑ private-dns-a-record — 0 consumers; `ttl`/non-empty-records validation; `names`/`fqdns` outputs; tests (2)
- ☑ vnet-peering — 3 consumers; `allow_*`/`use_remote_gateways` required → `default=false` (safe); tests (2)
- ☑ network-interface — 3 consumers; **fixed broken outputs** (`ip_configuration[*].id` — no such attr in azurerm 4.x); `≥1 ipconfig` + allocation validation; tests (3)
- ☑ virtual-network (2 consumers; `address_space` non-empty + `flow_timeout` validation; tests 3)
- ☑ network-security-group (2 consumers; `priority`/`access`/`direction` validation; removed dead data source; tests 3)
- ☑ route-table (2 consumers; `next_hop_type` + appliance-IP validation; `resource_group_name`/`subnet_ids` outputs; tests 2)
- ☑ nat-gateway (0 consumers; `nat_gateway_name`→`name`, outputs `nat_gateway_id`→`id`; `idle_timeout` validation; removed dead data.tf; tests 2)
- ☑ bastion-host (1 consumer; `sku` validation; Basic-SKU precondition already present; tests 3)
- ☑ route-server, network-watcher-flow-logs, expressroute-circuit, firewall-policy, virtual-network-gateway, virtual-network-gateway-connection, load-balancer, azure-firewall, private-dns-resolver — all keyed `map(object)` modules, already well-typed; added descriptions + create tests + READMEs (vngc test also exercises the type/target-id precondition)

**Bug fixed in `network-interface`:** outputs referenced `ip_configuration[*].id`
— that attribute does not exist on the ip_configuration block in azurerm 4.x.

### Batch E — monitoring / management / governance  ✅ COMPLETE (18 modules)
- ☑ diagnostic-settings (9 consumers, interface frozen) — tests (4) + README
- ☑ resource-group (7 consumers) — name validation; tests (2)
- ☑ platform-tags (7 consumers) — **removed drift-prone `creation_date_utc`/`last_modified_utc` inputs** (no consumer used them); `environment` + `data_classification` value validation; tag key names unchanged; tests (3)
- ☑ log-analytics (1 consumer) — `sku` + `retention_in_days` validation; tests (2)
- ☑ monitor-metric-alert, monitor-data-collection-{endpoint,rule,rule-association}, sentinel, defender-soc-posture, application-insights, management-locks, policy-baseline, operational-contracts, recovery-services-vault — descriptions + tests + READMEs
- ☑ budget — **0 consumers; fixed the always-on default**: `create_for_rg` defaulted `true` and `budget_scope_type` fell back to `"resource_group"`, so the module always tried to create an RG budget. Now `scope_type = null` (default) → true no-op via `coalesce(...,"none")`. `amount`/`rg_amount` validation → ternary. tests (2)
- ☑ management-groups — **0 consumers; fixed `try(x, "")` on a null optional** (5 sites) that broke any nested hierarchy — `try` doesn't catch null. tests (3)

**Bug class: `try(optional_attr, default)` does NOT substitute the default when
the attribute is present-but-null** (only on error). Use `x == null ? d : x`.
Watch for this in every remaining module.

### Batch F — data / app services  ✅ COMPLETE (~27 modules)
- ☑ key-vault-secret (2 consumers), key-vault-key (1), key-vault-certificate (1) — interface frozen; `map(object)` keyed contract documented; tests + READMEs (state-exposure note: secret values live in state)
- ☑ service-plan, app-configuration, automation-account, data-factory, service-bus — 0 consumers; `sku`/`os_type` validation, descriptions, tests + READMEs. service-bus README notes topics/subscriptions are now out of scope.
- ☑ ad-application-certificate — tests added (create via `application_id`; precondition failure when neither ID set); README with migration (`application_object_id` → `application_id`). Fixed `coalesce(...)` crash when both null → `try(coalesce(...), null)`.
- ☑ synapse — 0 consumers; removed dead `data.tf` + `test/` + pipeline YAML; `aad_admin` optional-object (separate `_aad_admin` resource, azurerm 4.x); tests (2) + README
- ☑ apim-service — 0 consumers; **renamed `security.enable_*` → `*_enabled` and `protocols.enable_http2` → `http2_enabled`** (azurerm 4.x); `sku_name` regex + identity-type validation; `timeouts`; enriched outputs (IPs, identity, mgmt/portal URLs); tests (3) + README + migration
- ☑ apim-api, apim-backend, apim-openid — 0 consumers; `lookup()` on typed objects left as-is (validate + plan-test clean); removed pipeline YAML; tests (1 each) + READMEs
- ☑ container-instance — 0 consumers; `subnet_ids`/`dns_config` made optional (default `[]`/`{}`), `os_type`/`ip_address_type` validation, `container_info` ≥1 validation, `tags` wired, `dns_config` for_each sliced to first entry, `fqdn` output; removed `test/`; tests (2) + README
- ☑ data-lake, event-grid (x3) — 0 consumers; removed dead `data.tf` / `gitignore` / `providers.tf` (in-module provider block) / pipeline YAML; tests + READMEs
- ☑ keyvault-managed-hsm — 0 consumers; `network_acls` `list(object)` → single `optional(object)` + value validation; `security_domain_*` pair precondition; `security_domain_key_vault_certificate_ids` passes `null` when empty; removed dead `data.tf` + `test/`; tests (1) + README
- ☑ mssql-database — 0 consumers; removed dead `data.tf`; tests (1) + README
- ☑ mssql-server, mssql-managed-instance — 0 consumers; **fixed `dynamic` blocks misfiring on null default** (`var.x != {}` → `var.x == null ? [] : [var.x]` for identity / azuread_administrator); null-safe identity outputs; identity-type validation null-guarded; removed dead `data.tf`; tests + READMEs
- ☑ storage-account — **2 consumers (platform-management, palo-alto-hub); interface frozen**; already fully typed by redesign; tests (3) + README
- ☑ storage-container-immutability-policy, storage-management-policy — 0 consumers; already lean + keyed; tests + READMEs
- ☑ app-service-environment, application-gateway — covered earlier (Batch A cross-touch / redesign); tests + READMEs present

### Batch G — cloudflare  ✅ COMPLETE (4 modules)
- ☑ record-manager — removed dead Azure `data.tf` + pipeline YAML; fixed `timeouts` `dynamic` block misfiring on empty object default; tests + README
- ☑ ruleset — **made `zone_id` / `account_id` mutually exclusive** (auto-suppress + precondition); removed dead `data.tf` / empty `locals.tf` / pipeline YAML; `rules` kept as ordered `list` (order is significant); tests (2) + README
- ☑ zone — **null-guarded `zone_plan` validation** (errored on its own null default); removed pipeline YAML; tests + README
- ☑ zero-trust-tunnel — 3 consumers, interface kept (pattern module); tests (2) + README

**Phase 2 progress: 103 / 103 modules hardened. Batches A–G complete.**
**Recurring bug class added: `dynamic` block `for_each = var.x != {} ? [var.x] : []`
misfires when `var.x` defaults to `null` (`null != {}` is true → iterates `[null]`).
Use `var.x == null ? [] : [var.x]`.**

Additional recurring finding — **dead embedded-diagnostics scaffolding**: several
modules still carry `data "azurerm_monitor_diagnostic_categories" "main"` + a
`locals.tf` computing `log_categories`/`metrics`/`log_category_groups` from it,
with nothing consuming those locals (the diag resource was removed by the
redesign). This forces a data lookup at plan and in web-apps caused apply
failures. Remove `data.tf` diag source + dead locals wherever seen.

**Recurring per-module checklist (from batches A–B):**
1. Consumer count → `scratchpad/consumers.txt` (only ~40 modules have any consumer; the rest can be normalized freely).
2. Remove "DEPRECATED" banner comments (user: keep every module working, no deprecation labels).
3. `x == null || x.attr` → `x == null ? true : x.attr` in validations AND preconditions.
4. `enable_*` → `*_enabled` where azurerm 4.x deprecated it (test surfaces the warning).
5. Untyped `name`/`rg`/`location` already typed in Phase 1 — add `description` + enum `validation`.
6. Drop input-echo outputs on 0-consumer modules; keep them on consumed modules.
7. `timeouts` object passthrough.
8. README: usage / input table / **lifecycle matrix** / state exposure / migration / tests.
9. `tests/defaults.tftest.hcl`: `mock_provider`, `command = apply` for attr asserts, `command = plan` + `expect_failures` for validations.
10. Overwrite the whole README (all are UTF-16 or stale-template).

### Batch C — identity & RBAC
terraform-azuread-compeer-{ad-application,ad-application-certificate,ad-group,service-principal},
terraform-azurerm-compeer-{user-assigned-identity,role-assignments,role-definition,apim-identity-aad-aad2bc}

### Batch D — networking resources
virtual-network, subnet-route-table-association, nsg-subnet-association, network-security-group,
route-table, nat-gateway, public-ip, private-endpoint, private-dns-zone, private-dns-vnet-link,
private-dns-a-record, private-dns-resolver, vnet-peering, virtual-network-gateway,
virtual-network-gateway-connection, expressroute-circuit, route-server, bastion-host,
load-balancer, network-interface, network-watcher-flow-logs, azure-firewall, firewall-policy,
ddos-protection-plan

### Batch E — monitoring / management / governance
log-analytics, diagnostic-settings, monitor-metric-alert, monitor-data-collection-endpoint,
monitor-data-collection-rule, monitor-data-collection-rule-association, action-group, sentinel,
defender-soc-posture, application-insights, budget, management-groups, management-locks,
policy-baseline, operational-contracts, platform-tags, resource-group, recovery-services-vault

### Batch F — data / app services
storage-account, storage-container-immutability-policy, storage-management-policy,
mssql-database, mssql-server, mssql-managed-instance, service-bus, event-grid,
event-grid-namespace, event-grid-system-topic, data-factory, data-lake, synapse,
app-configuration, container-instance, automation-account, apim-service, apim-api,
apim-backend, apim-openid, application-gateway, key-vault-secret, key-vault-key,
key-vault-certificate, keyvault-managed-hsm, keyvault-managed-storage-account, service-plan,
app-service-environment

### Batch G — cloudflare
cloudflare-compeer-{record-manager,ruleset,zero-trust-tunnel,zone}

## Resume procedure (per module)

1. `grep -rl "modules/terraform-…-<name>\b" implementations patterns` → consumer count.
2. Read `variables.tf` / `*.tf` / `outputs.tf`; cross-check the module's section in
   `Enterprise_Terraform_Module_Architecture_Review.docx` §6 ("Required updates").
3. Apply the standard (top of this file). 0 consumers → normalize freely + Migration
   section. >0 consumers → additive optional inputs only; keep existing names.
4. `terraform fmt`; `terraform init -backend=false -plugin-dir=<mirror>`; `terraform validate`.
5. Write `tests/defaults.tftest.hcl` (`mock_provider`, `command = plan`); `terraform test`.
6. Rewrite `README.md`: usage, input summary, **Lifecycle contract** table, State exposure,
   Migration, Tests. (Existing READMEs are UTF-16 — overwrite whole.)
7. Tick the box here.

Provider mirror for offline validate/test:
`terraform providers mirror -platform=darwin_arm64 <dir>` from a seed with
azurerm/azuread/cloudflare/local, then `-plugin-dir=<dir>`.
`terraform test` needs `terraform init` first even with `mock_provider`.


## Phase 3 — patterns + implementations alignment (commit ce8318b)

All 14 `patterns/` and 14 `implementations/platform-lz/workspaces/` now
`terraform validate` clean against the hardened modules (offline, provider
mirror). `network-peering` validates only via its implementation wrapper
(standalone it needs `azurerm.hub` / `azurerm.spoke` passed for its
`configuration_aliases`).

Interface-drift fixes (redesign renamed a consumed module input; the pattern
was never updated — all caught by `terraform validate`, none by tests):
- `platform-connectivity` → `bastion-host`: module is now a pure resource
  module (external public IP, no diagnostics). Pattern now composes
  `public-ip` + `bastion-host` + `diagnostic-settings`. `var.bastion` contract
  unchanged.
- `platform-management` → `keyvault`: removed stale `enable_rbac_authorization`
  (superseded by `rbac_authorization_enabled`).
- `directory-services` → `windows-vm`: `enable_automatic_updates` →
  `automatic_updates_enabled`; deprecated alias kept on the pattern input.

Provider pins: every azurerm root/pattern normalized to `>= 4.42.0, < 5.0.0`
(was a mix of `~> 4.0`, `>= 4.42.0, < 5.0.0`, `>= 3.100.0, < 5.0.0`).

Mirror now also carries `tfe`, `random`, `tls`, `null` (needed by the
implementations).

**Not done (needs live Azure):** `terraform plan` of the implementations —
would surface any `precondition` / cross-field `validation` that only fires at
plan time. Module `tests/` cover create + validation-rejection; full lifecycle
(no-op → in-place → replace → destroy, principle 10) is documented in each
module README matrix but not executed offline.

## Phase 4 — LZ security guardrails (commits 6ae65b6, 94f2c9c, d2e4635)

### Subscription onboarding (6ae65b6)
- `subscription-vending` pattern + `platform-subscriptions` workspace: **NOT
  DEPLOYED** banners added. Code kept intact for a future EA/MCA billing model.
- New `subscription-onboarding` pattern + `platform-subscription-onboarding`
  workspace: takes CSP-created subscription GUIDs, moves each to its target MG
  (`azurerm_management_group_subscription_association`), applies a consistent
  baseline RBAC set + inline app RBAC at subscription scope. Stable for_each
  keys `<sub>::baseline::<name>` / `<sub>::app::<name>`. `scripts/move-subscription.sh`
  break-glass. tests (4) pass. MG hierarchy + MG-scope RBAC stay in
  `global-governance`.

### Private-only connectivity guardrail (94f2c9c)
- `platform-policy` pattern: new `var.private_only_connectivity` — 2 custom deny
  policies (no Public IP outside an allow-list of RGs; no Public IP on NICs),
  an initiative, and an MG assignment. `effect` defaults to `Audit`. Built-in
  PaaS "disable public network access" policies are opt-in (GUIDs tenant-
  verifiable). Merges into the pattern's existing policy maps. tests (4) pass.
- README call-out: enabling Deny is a program — per-resource-type required
  changes + blast radius (App Gateway internal-only; APIM Internal VNet =
  replace; App Service/Storage/KV/SQL public access off + Private Endpoint; VM
  PIPs removed; Bastion/Route Server/VPN-GW/Palo stay public in allow-listed
  RGs). Cloudflare-side review is out of repo scope.
- Module defaults flipped private-by-default: `event-grid`,
  `automation-account`, `keyvault-managed-hsm` (`public_network_access_enabled`
  true→false), `event-grid-namespace` (`"Enabled"`→`"Disabled"`).

### Palo Alto — Terraform-native VM-Series bootstrap (d2e4635)
- `palo-alto-hub`: added `virtual_machines[*].bootstrap` (none /
  azure-file-share / custom-data → `custom_data`), `virtual_machines[*].identity`
  (SystemAssigned), `bootstrap_share_layout` (share dir/file layout via
  `azurerm_storage_share_directory` / `_file` / `local_file`). Switched
  `azurerm_storage_share` to `storage_account_id`. `local` provider added.
  Marketplace *agreement* (image licence) kept; Marketplace *solution template*
  not used. 2-VM / 2-LB / Sunstream example in the workspace tfvars. tests (2)
  pass.

## Phase 5 — output contract cleanup (all 104 modules)

Design principle 8 ("stable, composition-ready outputs; consumers should not
reconstruct IDs or reach into implementation details") swept across the whole
catalog.

- **`description` added to every output** — ~40 modules had descriptionless
  outputs (e.g. `virtual-network`, `keyvault`/`key-vault`, `load-balancer`,
  `public-ip`, `service-bus`, `azure-firewall`, `automation-account`,
  `role-definition`, `private-dns-*`, `monitor-data-collection-*`,
  `zero-trust-tunnel`). Now 104/104 fully described.
- **Stable `id` / `name` on every single-resource module** — modules that only
  exposed a prefixed alias (`app_config_id`, `data_factory_id`,
  `application_insights_id`, `eventgrid_id`, `synapse_workspace_id`,
  `mssql_database_id`, `service_plan_id`, `key_vault_hsm_id`, `api_id`,
  `openid_id`, `onboarding_id`, `zone_id`, `record_resource_id`,
  `budget_id`, `data_lake_gen2_fs_id`) gained a canonical `id` (and `name`
  where the resource has one). Prefixed names kept as documented aliases —
  **additive, non-breaking**.
- **Null-safe identity outputs** — `event-grid` / `event-grid-system-topic`
  `principal_id` switched to `try(...identity[0].principal_id, null)` so they
  don't crash when no managed identity is configured. `app-configuration` and
  `event-grid-namespace` gained `identity_principal_id`.
- **`for_each` map outputs confirmed** across the catalogue — every collection
  module already keys its `*_ids` maps by the caller's stable key
  (`subnet_ids`, `backend_pool_ids`, `inbound_endpoint_ids`, `ids`, …). No
  hardcoded resource names or IDs anywhere in a consumer.
- File hygiene: `apim-backend` outputs moved from `main.tf` → `outputs.tf`;
  `event-grid-namespace/output.tf` → `outputs.tf`.
- **`resource_group_name` output REMOVED from `virtual-network` and
  `networking`** (the reported concern, resolved on the ownership-contract
  argument). These modules receive the RG name as an *input* — they do not own
  the resource group — so re-emitting it made the VNet module a pass-through
  source for a value it isn't authoritative for, and a needless transit
  dependency in the graph. (The current Microsoft AVM `virtual-network` module
  likewise does **not** expose a dedicated `resource_group_name` output.)
  - RG identity is published by the **`resource-group` module** (`name`, `id`).
  - The **composition layer** assembles the consumer-facing network bundle:
    `platform-connectivity` and `workload-spoke` both already output
    `hub_resource_group_name` / `spoke_resource_group_name` (from
    `module.resource_group.name`) alongside `hub_virtual_network_id`,
    `..._name`, and `subnet_ids`.
  - Also dropped `resource_group_name` from the per-entry `subnets` map in
    `virtual-network` (same rationale; `virtual_network_name` kept — the module
    owns that VNet). No consumers referenced either.
  - `subnet_ids` map is unchanged — the "reference by key, never hardcode"
    pattern.

Verification: `terraform fmt` clean; **104/104 `terraform validate`**; all
changed modules that ship tests pass `terraform test` (no assertion touched a
changed output).

## Phase 6 — naming module = codified Appendix F

`terraform-azurerm-compeer-naming` rewritten from a single generic
`<abbr>-<org>-<workload>-<env>-<region>-<instance>` formula into the **explicit
per-resource-type implementation of design-doc Appendix F** (token order differs
per row).

- Pure / provider-less (no `required_providers`, no resources/data sources).
- `region` + `environment` required and **validated centrally** (approved region
  short-code table + environment enum live in the module). Every other token
  (`domain`, `purpose`, `destination`, `resource`, `appcode`, `name`, `policy`,
  `scope`, `instance`, `entra_domain`, `entra_role`) optional — a name whose
  tokens aren't all supplied is `null`, so a wrong reference fails fast.
- One flat output per Appendix F row (`hub_vnet`, `firewall_vm`, `nsg`,
  `key_vault`, `subscription_platform`, `mg_workload_domain_environment`,
  `entra_security_group`, `policy_assignment`, …).
- Normalises `lower(trimspace())`; `entra_domain` upper-cased, `entra_role` case
  preserved (`AZ-PLT-Admins`).
- **No universal truncation** — length/charset rules are output preconditions
  only where the resource needs them (Key Vault 3–24, RSV 2–50, LAW 4–63).
- **Adapted rows** (per the standard owner: "anything not in the list, adjust to
  a closely related resource"): `resource_group` (per-capability platform RG,
  `platform-<region>-<env>-<purpose>-rg`), `workload_resource_group`
  (`<domain>-<env>-rg`), `workload_vnet`, `subscription_scoped`,
  `automation_account`, `action_group`, `bastion`, `nat_gateway`,
  `route_server`, `ddos_protection_plan`, `private_dns_resolver`,
  `network_interface`, `private_endpoint`, `domain_controller_vm`,
  `expressroute_circuit/_connection`, `vpn_local_network_gateway`,
  `vpn_connection`, `storage_account`, `user_assigned_identity`. Each output's
  description names the F row it was adapted from. `mg` + `mg_environment`
  generalise `<domain>-mg` to any node token (platform child, workload domain,
  sandbox/decommissioned child).
- Consumed via a **`naming.tf` in the composition root** — wiring added to
  **8 workspaces**: `platform-connectivity` (RG + `hub_vnet`),
  `platform-management`, `platform-identity-security`,
  `platform-hybrid-connectivity`, `platform-directory-services`,
  `platform-cloudflare-connectors` (per-capability RG),
  `platform-shared-services` + `platform-workload-spoke` (RG + spoke VNet from
  a new `workload_domain` variable). `module.naming` → `local.std_names` →
  `merge()`-ed into the pattern inputs so tfvars still overrides. Patterns and
  resource modules keep taking an explicit `name`; they never call the module.
- `platform-governance` MG names, `platform-policy` / `platform-subscription-
  onboarding` names are **already Appendix-F-compliant or system-generated** in
  the examples — no wiring needed.
- Name outputs are a **frozen interface** — any change to an already-published
  name is a breaking major-version bump (forces resource replacement).
- tests: 8 `run` blocks — every verbatim + adapted pattern, token-absent `null`,
  normalisation, region/env rejection, Key Vault 24-char guard. validate + test
  pass; all 8 wired workspaces validate.

### Phase 6 — per-key names wired

`network_security_groups`, `route_tables`, `public_ips`,
`route_server_public_ips` (connectivity) and `network_security_groups`,
`route_tables`, `private_endpoints` (shared-services + workload-spoke) now get
their default name from a per-key naming-module instance:

```hcl
module "naming_nsg" {
  source   = ".../terraform-azurerm-compeer-naming"
  for_each = try(var.connectivity.network_security_groups, {})
  region = var.location  environment = var.environment  purpose = each.key
}
# then: merge({ name = module.naming_nsg[k].nsg }, v)  -- tfvars still wins
```

The map key carries the F token (`purpose` for NSG, `destination` for route
table, `resource` for PIP / private endpoint). All wired workspaces validate.

### Phase 6 — still open

- **`platform-palo-alto`** firewall VM / NIC / LB / public-IP names — deferred:
  the workspace has no `environment` variable, and VM/NIC names are ForceNew, so
  this waits for the "Palo hub approved for deployment" gate. Add `environment`
  + the same per-key wiring then.
- **Subnets are not renamed.** Reserved names (`GatewaySubnet`,
  `AzureBastionSubnet`, `RouteServerSubnet`, `AzureFirewallSubnet`, …) are an
  Azure hard constraint. Subnet name = the operator's map key; the `naming.nsg`
  / `.subnet` outputs exist if a non-reserved subnet wants one.
- **`domain_controller_vm`** adapted pattern (`platform-<region>-<env>-dc-0<n>`)
  differs from the current `AZR-SRV-ADDS-01` convention — an AD-team-visible
  rename; not wired into `platform-directory-services` yet, pending their
  sign-off (tracks with the existing A2 DC-promotion deviation).

**Provider mirror also carries:** `tfe`, `random`, `tls`, `null`, `local`.
