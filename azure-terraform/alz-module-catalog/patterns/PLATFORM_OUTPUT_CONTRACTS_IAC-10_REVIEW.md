# Platform Output Contracts (IAC-10 v0.1) — review against this catalog

Source document: `Platform_Output_Contracts_IAC-10_v0.1.docx` (7 root contracts:
platform-bootstrap, platform-governance, platform-identity, platform-connectivity,
platform-management, platform-security, workload-spoke).

## Verdict

**Not complete before this review — genuinely missing outputs existed, both as
outputs never computed and as outputs computed at the pattern level but never
wired through to the workspace wrapper other roots actually read via
`tfe_outputs`.** Most of the document's fields were already covered, several
under a different name or in a different root than the document assumes
(a real, deliberate architecture difference explained below, not a defect).
The concrete gaps have been closed in this pass — see "What was added."

One whole contract is legitimately **not applicable**: **platform-bootstrap**.
This catalog has no HCP-Terraform-as-code root (`platform-compeer-tfe-bootstrap`
is listed in `HCP-WORKSPACES.md` as a conditional/buffer workspace — "done once
by hand" until Compeer decides to manage HCP itself as code). None of
bootstrap's 10 outputs (org/project/workspace/variable-set/policy-set IDs,
registry namespace, naming module version, deployment identity client IDs)
exist anywhere in this catalog today. This is a scope decision already made
elsewhere in the repo, not a gap this pass fabricated a root to fill.

## The one structural difference that matters most

The document assumes a **7-root topology**: bootstrap, governance, identity,
connectivity, management, security, workload-spoke. This catalog uses a
**16-pattern topology** that splits several of those roots by lifecycle and
blast radius — the same reasoning this catalog already documents for why
`platform-policy` is separate from `global-governance`. Concretely:

| Document's root | Split across these patterns in this catalog |
|---|---|
| platform-identity | `platform-authorization` (RBAC groups, custom roles — IAM-01/02) + `directory-services` (domain controllers — IAM-07) + `platform-identity-security` (shared managed identities — IAM-06) |
| platform-security | `platform-management` (Sentinel, Defender — SEC-01/05) + `platform-connectivity` (Bastion — SEC-12) + `platform-identity-security` (Key Vault — SEC-07) + `platform-hybrid-connectivity` (VPN certificates — SEC-15) |
| platform-governance (subscription placement) | `subscription-onboarding` (a separate pattern in this catalog; governance owns the MG hierarchy and policy, not subscription placement) |

This is not a defect. A single "platform-identity" or "platform-security" root
publishing all of those outputs would mean one HCP workspace, one blast
radius, and one set of credentials across domain-controller VMs, Key Vault,
Sentinel, and VPN certificates — exactly the kind of coupling this catalog's
own architecture already avoids everywhere else. Every review item below
notes which of *our* patterns actually owns the document's field.

---

## Table-by-table assessment

Legend: ✅ present and wired through · 🔧 **added in this pass** · 🏗️ present,
but the document's field maps to a different pattern in our topology (see
above) · ❌ genuine gap, flagged not fabricated · N/A out of scope by design.

### platform-bootstrap

All 10 fields: **N/A** — no bootstrap-as-code root exists in this catalog
(see "Verdict" above).

### platform-governance

| Field | Status | Note |
|---|---|---|
| `governance_contract_version` | 🔧 added | `implementations/.../platform-governance/outputs.tf` → `contract_version` |
| `governance_management_group_ids` | ✅ | `management_group_ids` |
| `governance_platform_subscription_ids` | ❌ | Platform subscription IDs are HCP **workspace variables** on each platform workspace (`subscription_id`/`execution_subscription_id`, per `WORKSPACES.md`'s "tenant_id / subscription_id" section), not something governance computes — governance runs *before* those workspaces even exist in deployment order, so it structurally cannot publish their IDs. Each platform pattern already publishes its own `resource_group_name`/`hub_resource_group_name` instead; there is no single catalog of "which subscription is which platform capability in" today. Flagged, not built — assembling one would mean either reordering governance after every platform workspace (breaks the documented deployment order) or hand-maintaining a static map in tfvars.
| `governance_workload_subscription_ids` | 🏗️ | `subscription-onboarding` pattern → `onboarded_subscription_ids` / `onboarded_subscription_resource_ids`, keyed by logical subscription name. Different pattern, same information.
| `governance_sandbox_subscription_ids` | ❌ | No sandbox-specific subscription catalog exists yet; sandbox subscriptions (if any) would flow through the same `subscription-onboarding` pattern as workload subscriptions today, with no separate `ops`/`developer`/`data`/`architect` keying. Flag for whoever stands up the sandbox spoke (WKL-08 in the doc's own numbering).
| `governance_policy_initiative_ids` | 🏗️ (partial) | `custom_policy_set_definition_ids` exists, but this catalog bundles the whole baseline into **one** initiative (`compeer-landing-zone-baseline`), not three separately-keyed initiatives (`security_baseline`/`tagging_mandatory`/`diagnostics_dine`). See `PATTERN-REFERENCE.md` §1 for why one initiative was chosen over six-then-three separate ones. The MCSB initiative is tracked as a separate assignment, not initiative-per-topic.
| `governance_policy_assignment_ids` | ✅ | `management_group_policy_assignment_ids` + `subscription_policy_assignment_ids` |
| `governance_platform_resource_group_ids` | 🏗️ | Each platform pattern publishes its own resource group name/id already (connectivity's `hub_resource_group_name`, management's/identity-security's/directory-services' `resource_group_name`) — governance doesn't aggregate them, and structurally can't for the same before-they-exist reason as the subscription IDs above.
| `governance_mandatory_tag_keys` | 🔧 added | `patterns/terraform-azurerm-compeer-global-governance/outputs.tf` → `mandatory_tag_keys` (re-publishes `local.pb_required_tags`, which already tracks `terraform-azurerm-compeer-platform-tags`' `mandatory_keys` exactly — see the `cmp-required-tags` bug fix in `PATTERN-REFERENCE.md` §1). Wired through to the workspace and on to `workload-spoke`'s `spoke_mandatory_tag_keys` passthrough (see below).
| `governance_subscription_baseline_version` | ❌ | No "IAC-07 subscription baseline module" concept exists in this catalog; subscription onboarding is a pattern, not a versioned baseline module with drift reporting. Not built — would need a real design decision first, not just an output.

### platform-identity *(split — see structural note above)*

| Field | Status | Note |
|---|---|---|
| `identity_contract_version` | 🔧 added | Added to **all three** contributing workspaces (`platform-authorization`, `platform-directory-services`, `platform-identity-security`) since each independently versions its own output surface; each output's description says which slice of the document's contract it covers. |
| `identity_rbac_group_object_ids` | ✅ | `platform-authorization` → `group_object_ids` |
| `identity_custom_role_definition_ids` | ✅ | `platform-authorization` → `custom_role_definition_ids` |
| `identity_domain_controller_private_ips` | 🔧 added | `directory-services` had `domain_controller_private_ips` (map keyed per-controller); added `domain_controller_private_ip_list` — a flat `list(string)` matching the document's exact shape, for VNet DNS server configuration. |
| `identity_ad_domain_fqdn` | 🔧 added (currently null) | `directory-services` → `ad_domain_fqdn`, derived from any `domain_controllers[*].domain_join.domain_name` entry with `domain_join.enabled = true`. Resolves to `null` today because the real tfvars has no `domain_join` block populated yet (AD DS promotion is manual by design — see the AD DS decision in `PATTERN-REFERENCE.md`) — this is the expected, honest value until the AD team confirms the real domain and a `domain_join` entry is set. |
| `identity_shared_user_assigned_identity_ids` | 🔧 added (id/principal_id halves already existed) | `platform-identity-security` had `platform_identity_ids` and `platform_identity_principal_ids` but never `client_id` — added `platform_identity_client_ids` (pattern + workspace) so all three pieces the document's `object({id, principal_id, client_id})` needs now exist, even though this catalog publishes them as three parallel maps rather than one combined object map (simpler HCL, same information, no behavior difference for a consumer that reads all three). VPN certificate access (SEC-15) additionally needed `platform-hybrid-connectivity`'s `vpn_certificate_identity_id`/`_principal_id`/`_client_id` — these existed at the pattern level since the certificate Key Vault + identity were built, but were never wired through to the workspace; **added** (see platform-security below). |

### platform-connectivity

| Field | Status | Note |
|---|---|---|
| `connectivity_contract_version` | 🔧 added | `contract_version` |
| `connectivity_hub_vnet_id` | ✅ | `hub_virtual_network_id` |
| `connectivity_hub_vnet_name` | ✅ | `hub_virtual_network_name` |
| `connectivity_hub_vnet_address_space` | 🔧 added | Was **entirely missing** — no output surfaced the hub's address prefixes anywhere, pattern or workspace. Added `hub_virtual_network_address_space` (pattern + workspace), sourced from `module.hub_vnet.address_space`. |
| `connectivity_hub_subnet_ids` | ✅ | `subnet_ids` |
| `connectivity_shared_services_vnet_id` | N/A by design | The separate-VNet option (NET-43) was **not adopted** — the `terraform-azurerm-compeer-shared-services` pattern that would have built it was deleted from the catalog entirely after network/LZ architect review corrected the design: domain controllers and shared services live directly in the hub, confirmed by `directory-services` already wiring DCs to the hub's own subnets. See `PATTERN-REFERENCE.md`'s "Deployment order" section for the full account. This output is conditional in the document's own words ("only where the separate-VNet option is adopted") — correctly absent here. |
| `connectivity_firewall_ilb_private_ip` | 🔧 added | Was **entirely missing**. The load-balancer module already exposes `frontend_ip_configurations` (with `private_ip_address` per frontend); added a generic `load_balancer_frontend_private_ip_addresses` map, keyed `"<load_balancer_key>.<frontend_key>"`, rather than guessing which caller-defined key is "the" Trust ILB — this pattern's `load_balancers` map has no hardcoded key names, so a consumer picks its own real entry out of the map. |
| `connectivity_spoke_route_table_ids` | 🔧 wired through | `route_table_ids` already existed at the pattern level but was **never exposed at the workspace level** — added to `implementations/.../platform-connectivity/outputs.tf`. |
| `connectivity_private_dns_zone_ids` | ✅ | `private_dns_zone_ids` |
| `connectivity_private_dns_resource_group_id` | 🔧 added (currently null) | Added `private_dns_zones_resource_group_id`, sourced from the dedicated-RG module (`module.private_dns_zones_resource_group`). Resolves to `null` today because the real deployment reuses every catalogue zone from the existing landing zone (`existing = true`) rather than creating any fresh — `private_dns_zone_resource_group_names` (already existed, per-zone) is the correct output to use in that case, and is called out in the new output's own description. |
| `connectivity_dns_server_ips` | 🔧 added | Was **entirely missing** as a *consumable* output — `var.dns_resolution.dns_server_ips` existed only as an input feeding the `dns_resolution_contract` precondition, never republished. Added `dns_server_ips`, sourced from `module.hub_vnet.dns_servers` — the value that actually flows into Azure DNS resolution, not the separate decision-record variable (see the new output's description for why those two aren't automatically the same value in this pattern today). |
| `connectivity_nsg_baseline_ids` | 🔧 wired through | `network_security_group_ids` already existed at the pattern level, not exposed at the workspace — added. |
| `connectivity_expressroute_gateway_id` | 🏗️ | `platform-hybrid-connectivity` → `expressroute_gateway_id` (ExpressRoute lifecycle is a separate pattern in this catalog). |
| `connectivity_vpn_gateway_id` | 🏗️ | `platform-hybrid-connectivity` → `vpn_gateway_id`. |

### platform-management

| Field | Status | Note |
|---|---|---|
| `management_contract_version` | 🔧 added | `contract_version` |
| `management_log_analytics_workspace_ids` | 🔧 added | Only a singular `log_analytics_workspace_id` existed. Added `log_analytics_workspace_ids`, a `map(string)` keyed by `var.environment` — exactly the forward-compatible shape the document itself recommends for the still-unresolved v7 §9.2 vs. component-list conflict ("a map absorbs either outcome... with one workspace, the map has one key"). The original singular output is untouched. |
| `management_log_analytics_workspace_guids` | 🔧 added | Same treatment as above, from `log_analytics_workspace_guid`. |
| `management_diagnostic_profile` | ❌ | No single "default diagnostic settings profile" object exists as a reusable, named contract in this catalog — each pattern's `diagnostic_settings` map is caller-authored per resource, not derived from one shared profile object. Flagged; building this would mean introducing a new shared convention across every pattern's diagnostic-settings inputs, a larger change than an output addition. |
| `management_action_group_ids` | 🔧 added | Only a singular `action_group_id` existed. The document describes this as *"Published as an empty map until delivered"* (OBS-04 is Phase 2 in the design doc) — but this catalog already has a real action group, so added `action_group_ids = { primary = ... }` rather than an empty placeholder map. True severity/audience keying is still Phase 2 per the document's own framing; not fabricated here. |
| `management_recovery_services_vault_ids` | ✅ | `recovery_services_vault_ids` (keyed by vault/purpose in this catalog, not literally "region" — same information). |
| `management_backup_policy_ids` | ✅ | `backup_policy_vm_ids` (keyed `<vault>.<tier>`) + `backup_policy_file_share_ids`. |
| `management_platform_storage_account_ids` | ✅ | `platform_storage_account_ids`. |

### platform-security *(split — see structural note above)*

| Field | Status | Note |
|---|---|---|
| `security_contract_version` | 🔧 added | Added to `platform-identity-security` (the Key Vault piece), noting in its description that Sentinel/Defender/Bastion/VPN-certs live elsewhere. |
| `security_platform_key_vault` | 🏗️ | `platform-identity-security` → `key_vault_id` + `key_vault_uri` as two flat outputs, not a `map(object)` keyed by environment (this catalog deploys one identity-security workspace, not one per environment) — same information, simpler shape for the current single-environment reality. |
| `security_sentinel_workspace_id` | 🏗️ | `platform-management` → `sentinel_onboarding_id` (the actual Sentinel-onboarding resource's ID, arguably more precise than re-using the LAW ID). |
| `security_bastion_host_id` | 🏗️ | `platform-connectivity` → `bastion_id`. |
| `security_defender_enabled_plans` | 🔧 wired through | `platform-management`'s pattern-level `defender_plan_ids` existed but wasn't exposed at the workspace level — added. |
| `security_vpn_certificate_ids` | 🔧 wired through | `platform-hybrid-connectivity`'s pattern-level `vpn_certificate_key_vault_id` / `_uri` and `vpn_certificate_identity_id` / `_principal_id` / `_client_id` existed (built when the VPN certificate Key Vault + managed identity were added) but were **never exposed at the workspace level** — the exact gap the document's own SEC-15 consumer note describes ("consumed by the connectivity root"). Added all five to `implementations/.../platform-hybrid-connectivity/outputs.tf`. |

### workload-spoke

| Field | Status | Note |
|---|---|---|
| `spoke_contract_version` | 🔧 added | `contract_version` |
| `spoke_vnet_id` | ✅ | `spoke_virtual_network_id` |
| `spoke_subnet_ids` | ✅ | `subnet_ids` |
| `spoke_resource_group_ids` | 🏗️ | This catalog runs one `workload-spoke` **workspace per application** (per `WORKSPACES.md`'s template-root model: `<env>-compeer-lz-<domain>-<appcode>`), each with its own single resource group (`spoke_resource_group_name`) — the document's "map keyed by app + component" naturally happens across the *catalog* of workspace instances, not inside any one of them. Not a gap, a different (arguably more isolated) way of getting the same coverage. |
| `spoke_key_vault` | 🔧 added | `workload_key_vault_id` existed; `vault_uri` was **missing entirely** (pattern + workspace) — added `workload_key_vault_uri`, reference only, matching the document's own "identifiers only, never secret values" rule. |
| `spoke_user_assigned_identity_ids` | 🔧 wired through | Pattern already had `workload_identity_id` / `_client_id` / `_principal_id`; only `_principal_id` was exposed at the workspace level — added `workload_identity_id` and `workload_identity_client_id`. |
| `spoke_log_analytics_workspace_id` | 🔧 added | Was **entirely missing** as a republished output, even though the workspace already computes `local.log_analytics_workspace_id` internally (used for the workload Key Vault's diagnostic settings). Added the passthrough output — exactly the mechanism the document recommends *("giving [an application root] a state-sharing grant on platform-management... would put an application team inside a platform boundary for the sake of two strings")*. |
| `spoke_mandatory_tag_keys` | 🔧 added | Was **entirely missing**, and required new plumbing: added a `data "tfe_outputs" "governance"` block, a `governance_workspace_name` variable, and a `mandatory_tag_keys` local to `implementations/.../platform-workload-spoke/main.tf`, then republished it as `spoke_mandatory_tag_keys`. Depends on `governance_mandatory_tag_keys` (added above) actually being populated by the governance workspace's next apply. |

---

## What was added, by file

**Patterns** (`patterns/…/outputs.tf`, all additive — no resource or variable
schema changes, verified with `terraform validate`/`terraform test` per
pattern):

- `terraform-azurerm-compeer-global-governance`: `mandatory_tag_keys`
- `terraform-azurerm-compeer-platform-connectivity`: `hub_virtual_network_address_space`, `dns_server_ips`, `load_balancer_frontend_private_ip_addresses`, `private_dns_zones_resource_group_id`
- `terraform-azurerm-compeer-platform-management`: `log_analytics_workspace_ids`, `log_analytics_workspace_guids`, `action_group_ids`
- `terraform-azurerm-compeer-platform-identity`: `platform_identity_client_ids`
- `terraform-azurerm-compeer-directory-services`: `domain_controller_private_ip_list`, `ad_domain_fqdn`
- `terraform-azurerm-compeer-workload-spoke`: `workload_key_vault_uri`

**Workspaces** (`implementations/platform-lz/workspaces/…/outputs.tf` — the
pass-through consumers actually read via `tfe_outputs`):

- `platform-governance`: `subscription_placement_ids` (wired through), `mandatory_tag_keys`, `contract_version`
- `platform-authorization`: `contract_version`
- `platform-connectivity`: `hub_virtual_network_address_space`, `dns_server_ips`, `network_security_group_ids` (wired through), `route_table_ids` (wired through), `load_balancer_frontend_private_ip_addresses`, `private_dns_zones_resource_group_id`, `contract_version`
- `platform-management`: `log_analytics_workspace_ids`, `log_analytics_workspace_guids`, `action_group_ids`, `defender_plan_ids` (wired through), `contract_version`
- `platform-identity-security`: `platform_identity_client_ids`, `contract_version`
- `platform-directory-services`: `domain_controller_private_ip_list`, `ad_domain_fqdn`, `contract_version`
- `platform-hybrid-connectivity`: `vpn_certificate_key_vault_id`, `vpn_certificate_key_vault_uri`, `vpn_certificate_identity_id`, `vpn_certificate_identity_principal_id`, `vpn_certificate_identity_client_id` (all wired through), `contract_version`
- `platform-workload-spoke`: `workload_identity_id`, `workload_identity_client_id` (wired through), `workload_key_vault_uri`, `spoke_log_analytics_workspace_id`, `spoke_mandatory_tag_keys` (new `tfe_outputs.governance` data source + `governance_workspace_name` variable), `contract_version`

## What was flagged but not built

These are genuine gaps against the document, left as decisions rather than
fabricated:

1. **`governance_platform_subscription_ids` / `governance_platform_resource_group_ids`** — structurally can't be governance's own output in this catalog's deployment order (governance runs before the workspaces it would need to aggregate even exist). If a single "where does everything live" catalog is wanted, it would need to be assembled *after* every platform workspace has applied at least once — a new, later root, not an addition to governance.
2. **`governance_sandbox_subscription_ids`** — no sandbox subscription catalog exists yet; revisit when the sandbox spoke (WKL-08) is built.
3. **`governance_subscription_baseline_version`** — no "subscription baseline module" concept exists in this catalog to version.
4. **`management_diagnostic_profile`** — would require a new shared diagnostic-profile convention across every pattern, not just an output.
5. **platform-bootstrap, all 10 fields** — out of scope until HCP itself is managed as code (a deliberate, already-documented decision in `HCP-WORKSPACES.md`).

## Verification

Every pattern and workspace touched: `terraform validate` clean,
`terraform test` clean (no test file needed changes — every addition is a
new, additive output, not a behavior change), and a `terraform plan` against
real tfvars (dummy credentials) for `platform-connectivity`,
`platform-directory-services`, and `platform-workload-spoke` built the whole
graph successfully, failing only on Azure/TFE auth as expected. A full
repo-wide sweep after all changes shows zero regressions in any other
pattern or workspace (the one pre-existing `network-peering` standalone-validate
limitation — it needs its provider aliases supplied by its own workspace
wrapper — is unrelated and already documented).
