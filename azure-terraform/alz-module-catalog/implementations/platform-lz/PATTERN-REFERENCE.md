# Platform Pattern Reference

What each `patterns/` root deploys, why, and (where relevant) which Azure
Policies it sets and how those map to the **Azure Landing Zone Architecture &
Design Document v7** and the **Compeer Identity & RBAC Design v2.0** ("the
Identity/RBAC doc"). Written in deployment order — see
[`WORKSPACES.md`](WORKSPACES.md) for the authoritative order and dependency
detail; this file is the "what's inside and why" companion to it.

Each section lists the pattern's `module`/`resource` blocks grouped by purpose,
not file-by-file — a pattern's logic is sometimes split across multiple `.tf`
files (e.g. `platform-management`'s alerts live in `platform_alerts.tf`, not
`main.tf`).

## Deployment order

1. `global-governance` → workspace `platform-governance`
2. `platform-authorization` → workspace `platform-authorization`
3. `workload-identity` → workspace `platform-workload-identity`
4. `privileged-access` → workspace `platform-privileged-access`
5. `subscription-onboarding` → workspace `platform-subscription-onboarding`
6. `platform-policy` → workspace `platform-policy`
7. `platform-management` → workspace `platform-management`
8. `platform-connectivity` → workspace `platform-connectivity`
9. `platform-identity` → workspace `platform-identity-security`
10. `platform-hybrid-connectivity` → workspace `platform-hybrid-connectivity`
11. `palo-alto-hub` → workspace `platform-palo-alto`
12. `directory-services` → workspace `platform-directory-services`
13. `cloudflare-connectors` → workspace `platform-cloudflare-connectors`
14. `shared-services` → workspace `platform-shared-services`
15. `workload-spoke` (template) → one workspace per workload × environment
16. `network-peering` (template) → one workspace per hub↔spoke pair
17. `terraform-cloudflare-compeer-edge-baseline` → workspace `platform-cloudflare-edge`

Not deployed: `subscription-vending` (creates subscriptions; Compeer's CSP
creates them instead — kept for a future EA/MCA billing model only).

## Test coverage audit (all 17 patterns)

Before this pass, only 2 of the 17 patterns (`global-governance`,
`palo-alto-hub`) had meaningful test coverage; several with real safety-
critical `terraform_data` contracts had **zero**. All 17 now have a passing
`terraform test` suite — 86 test runs total, 0 failures — and validating
against `terraform plan` (not just `terraform validate`, which does not
evaluate resource preconditions or runtime function calls with real values)
surfaced three real, previously-latent bugs:

1. **`platform-hybrid-connectivity`** — `coalesce(x, "")` inside the
   ExpressRoute and VPN posture preconditions crashed `terraform plan` with
   *"no non-null, non-empty-string arguments"* whenever `provider_design_reference`
   / `design_reference` was left `null` — **which the real deployed
   `platform-hybrid-connectivity` tfvars does**. This broke every plan of that
   workspace, regardless of whether ExpressRoute/VPN posture was even enabled
   (HCL evaluates the whole expression eagerly; the leading `!enabled`
   short-circuit does not protect the error inside `coalesce`). Fixed with a
   null-safe ternary.
2. **`platform-directory-services`** — the same `coalesce(x, "")` pattern in
   the AD DS promotion precondition turned a missing `domain_name`/
   `domain_admin_username` into the same cryptic crash instead of the
   precondition's intended clean error message. Same fix.
3. **`platform-identity` and `workload-spoke`** (the latter also reused by
   `shared-services`) — `network_acls = coalesce(try(x.network_acls, null), {bypass=.., default_action=..})`
   crashed with *"all arguments must have the same type"* whenever
   `network_acls` was left unset, because the literal default object and the
   variable's declared object type (which also allows `ip_rules` /
   `virtual_network_subnet_ids`) are different shapes — and a ternary between
   them hits the equally well-known "Inconsistent conditional result types"
   error. **Neither `platform-identity-security`'s real tfvars nor the
   pattern's own `terraform.tfvars.example` set `network_acls`**, so this
   crashed for the real deployed workspace and for any workload spoke that
   enables its own Key Vault. Fixed by building the object attribute-by-
   attribute with `try()` per field, which sidesteps both error paths.

`terraform-azurerm-compeer-platform-management`'s `platform_key_vaults` module
call shares a related-but-safe pattern (`network_acls = try(each.value.network_acls, null)`
passed straight through, no coalesce-with-a-default) — the receiving module
gates its `dynamic` block on `== null`, so no fix was needed there; it's the
coalesce-with-a-mismatched-default idiom specifically that's dangerous, not
passing `null` itself.

Separately (not a bug fix — closing the `custom_policy_set_definitions`
placeholder gap identified while auditing `global-governance`, §1 below):
the 6 `cmp-*` baseline policies are now packaged into one custom initiative,
`compeer-landing-zone-baseline`, and assigned once instead of as 6 separate
management-group policy assignments — the first real caller of a capability
that had been wired end-to-end but never populated by anything. Same 6
controls, same Audit effect, same scope; covered by
`policy_baseline_packages_into_one_initiative` in
`terraform-azurerm-compeer-global-governance/tests/defaults.tftest.hcl`.
See §1 for the full rationale.

## Readability pass: resource naming, file layout, and READMEs

A separate, catalog-wide pass — resource labels, not behavior — requested
after review feedback that the generic Terraform default label `"this"`
made diffs and cross-references hard to follow for a team reviewing changes
across 18 patterns and 106 modules.

**1. Every `resource`/`data` block labeled `"this"` was renamed to a
purpose-specific name** (e.g. `azurerm_policy_definition.this` →
`.definition`, `azurerm_key_vault_secret.this` → `.secret`,
`azurerm_management_group_policy_assignment.this` → `.mg_assignment`),
scoped so no two resources in the same file collide (e.g. the policy
pattern's `mg_assignment` / `rg_assignment` / `subscription_assignment` /
their 3 exemption counterparts). 125 resource/data labels renamed across 68
directories (10 patterns, 58 modules) — the other 8 patterns and 48 modules
already used custom labels and needed no change.

**State safety:** renaming a label changes that resource's Terraform-state
address, which matters once a workspace has actually applied — so every
rename was first shipped with a `moved.tf` recording the old→new address, on
the defensive assumption that a real workspace might already hold state
under the old `.this` addresses. That assumption was confirmed wrong: **no
`implementations/platform-lz/workspaces/*` workspace has ever run a real
`terraform apply`** — there is no state anywhere with a `.this` address to
migrate from. All 68 `moved.tf` files were removed as a result; a plain
rename is sufficient until the first real apply happens, at which point the
new semantic names simply become the resources' addresses from day one.

While the `moved.tf` files existed, re-running `terraform test` after the
rename did catch one real, independent bug worth recording:
`terraform-azurerm-compeer-management-locks`' lock resource is consumed by 6
patterns via **pre-existing historical** `moved` blocks (from when those
patterns' inline lock resource was extracted into a shared module, well
before this rename pass). Pointing those historical blocks straight at the
final renamed address (`...azurerm_management_lock.lock`) instead of the
module's own then-current internal address broke `terraform plan` for 3
patterns (`cloudflare-connectors`, `platform-connectivity`,
`platform-management`) with "Ambiguous move statements" — a genuine
chaining-order bug, caught and fixed, unrelated to whether any workspace has
actually applied. Those 6 pre-existing historical `moved` blocks were a
separate, older piece of history that this pass didn't originally create —
but the `.resource_lock` rename below made them doubly stale (their `to`
address named the module's label from *before* either rename, which no
longer exists anywhere), and since no workspace has ever applied, they were
confirmed inert and removed (all 6, from `cloudflare-connectors`,
`directory-services`, `platform-connectivity`, `platform-identity`,
`platform-management`, `workload-spoke`). Re-verified: `terraform test`
still passes on all 6 plus `shared-services` (which wraps `workload-spoke`).
(The label mentioned in the bug account above, `.lock`, was itself later
renamed to `.resource_lock` — see the next paragraph; the bug and its cause
are otherwise unchanged.)

**Aligning with Compeer's already-published modules.** Two resource types
in this catalog overlap with modules Compeer has already defined and
published for real (`terraform-azurerm-compeer-management-group` and
`terraform-azurerm-compeer-management-group-lock`), and this catalog's
initial rename picked different labels than those published modules use.
Corrected for consistency:

- `azurerm_management_lock` → **`resource_lock`** (not `.lock`) in
  `modules/terraform-azurerm-compeer-management-locks`, matching the
  published lock module exactly.
- `azurerm_management_group_subscription_association` → **`.this`** (not
  `.association`) in `modules/terraform-azurerm-compeer-management-groups`
  and `patterns/terraform-azurerm-compeer-subscription-vending`, matching
  the published management-group module — which keeps this one resource
  labeled `.this` deliberately, since it's the single obvious
  "the association" resource in its file. `patterns/terraform-azurerm-compeer-subscription-onboarding`
  had a third, independent label for the same resource type
  (`.placement`, predating this rename pass entirely) and is now aligned
  to `.this` too, for the same reason.

This is the one deliberate exception to "always rename away from `this`":
where Compeer has already published a real module using `.this` for a
resource, matching that published precedent takes priority over the
blanket rename, since consistency with what's actually live matters more
than a blanket rule.

**Verification:** `terraform validate` passes on all 68 touched directories;
`terraform test` passes on all 67 of them that have a test suite (the 68th,
`subscription-vending`, has none — it's the explicitly-not-deployed
reference pattern).

**Every historical `moved` block in the catalog has since been removed —
none remain.** Beyond the 68 `moved.tf` files from the rename itself, this
also covers two sets of pre-existing blocks that predated this session's
work entirely and were left in place at first, on the assumption they might
still be protecting real state:

- 6 blocks (one each in `cloudflare-connectors`, `directory-services`,
  `platform-connectivity`, `platform-identity`, `platform-management`,
  `workload-spoke`) recording an old inline `azurerm_management_lock`
  resource's extraction into the shared `management-locks` module. The
  `.resource_lock` rename above made these doubly stale — their `to` address
  named a module-internal label that no longer exists anywhere.
- 4 blocks in `global-governance` recording `azurerm_management_group.root`
  / `.level_1` / `.level_2` / `.level_3`'s extraction into the shared
  `management-groups` module. These were still technically accurate (that
  module's labels never changed), just as unused as everything else here.

All removed on the same confirmed basis as the 68 `moved.tf` files: no
`implementations/platform-lz/workspaces/*` workspace has ever run a real
`terraform apply`, so there is no state anywhere for any of this
bookkeeping to protect — a plain rename/refactor is sufficient until the
first real apply happens. Re-verified: `terraform validate` and
`terraform test` pass on every affected directory (the 6 lock-consuming
patterns, `shared-services` which wraps `workload-spoke`, and
`global-governance`).

**2. File organization ("a single parameter file where useful") — already
compliant, no changes needed.** Every one of the 18 patterns and 106 modules
already has exactly one `variables.tf` and one `outputs.tf`, with no
variable/output declarations scattered across other files. Nothing to
consolidate here.

**3. Every one of the 18 patterns now has a README `## Overview` section**
stating what it deploys and why, plus — where the pattern carries a
`terraform_data` contract, a merge-into-`var.*` pattern, or another piece of
configuration that isn't self-explanatory from the code alone — a short
explanation of *why* it's shaped that way (e.g. `global-governance`'s
initiative-packaging merge pattern, `platform-connectivity`'s two routing/DNS
contracts, `platform-identity`/`workload-spoke`'s field-by-field `network_acls`
construction). Patterns whose README already had an equivalent table (e.g.
`palo-alto-hub`'s "What it composes", `platform-authorization`'s "What is
Terraform-managed here") kept that table and just gained the `## Overview`
heading and a one-line orientation above it, rather than a duplicate section.

---

## 1. `global-governance` — workspace `platform-governance`

**Purpose:** the Azure governance root — management-group hierarchy, the
policy *baseline*, custom RBAC roles, and MG/subscription-scope budgets. ALZ
Doc Phase 3 in full.

| Block | Resource(s) | Why |
|---|---|---|
| `management_groups` | `terraform-azurerm-compeer-management-groups` | MG hierarchy: `compeer-enterprise-mg` → `platform-mg`/`workloads-mg`/`sandbox-mg`/`decommissioned-mg` → capability/domain MGs → domain+env MGs. Phase 3 §1-2 |
| `policy_baseline.tf` | `azurerm_policy_definition`, `azurerm_management_group_policy_assignment` | The 6 `cmp-*` policies + MCSB initiative — see the policy table below. Phase 3 §6 |
| `azurerm_policy_definition` / `azurerm_policy_set_definition` (main.tf) | — | Generic passthrough for hand-authored custom policies/initiatives on top of the baseline (`var.custom_policy_definitions` / `var.custom_policy_set_definitions`) |
| `azurerm_management_group_policy_assignment` / `azurerm_subscription_policy_assignment` (main.tf) | — | Generic passthrough for hand-authored assignments |
| `custom_role_definitions` | `terraform-azurerm-compeer-role-definition` | Custom Azure roles when a built-in doesn't fit (kept minimal by design — Phase 3 §4) |
| `role_assignments` | `terraform-azurerm-compeer-role-assignments` | Resolves `management_group_key` → scope for any role assignment declared here (rare — standing RBAC now lives in `platform-authorization`) |
| `azurerm_consumption_budget_management_group` | — | MG-scope cost budgets |

**Policies set here — live vs. designed** (see the full cross-doc table in
section 6, `platform-policy`, below for the complete picture including
guardrails that live in that narrower workspace; this table is just what
`global-governance` itself creates):

| Policy | Effect (today) | Scope | Status |
|---|---|---|---|
| `cmp-allowed-locations` | Audit | `compeer-enterprise-mg` | **LIVE** — via `compeer-landing-zone-baseline` initiative |
| `cmp-required-tags` | Audit | `compeer-enterprise-mg` | **LIVE** — via `compeer-landing-zone-baseline` initiative |
| `cmp-deny-public-paas` | Audit | `compeer-enterprise-mg` | **LIVE** — via `compeer-landing-zone-baseline` initiative |
| `cmp-secure-storage` | Audit | `compeer-enterprise-mg` | **LIVE** — via `compeer-landing-zone-baseline` initiative |
| `cmp-deny-public-ip` | Audit | `compeer-enterprise-mg` | **LIVE** — via `compeer-landing-zone-baseline` initiative |
| `cmp-sql-private-network` | Audit | `compeer-enterprise-mg` | **LIVE** — via `compeer-landing-zone-baseline` initiative |
| Microsoft Cloud Security Benchmark (built-in initiative) | Audit (`enforce=false`) | `compeer-enterprise-mg` | **LIVE** (separate, unrelated initiative) |

**`custom_policy_set_definitions` (initiative authoring) — now in use.** It
was wired end to end (`variables.tf` → `resource "azurerm_policy_set_definition"
"this"` in `main.tf` → passed through by the `platform-governance` workspace)
but never populated — not in the real workspace `terraform.tfvars`, not even
in `terraform.tfvars.example`. `policy_baseline.tf` is now its first real
caller: the 6 `cmp-*` policies above are packaged into one initiative,
`compeer-landing-zone-baseline` (merged into the pattern's own
`azurerm_policy_set_definition.this` for_each exactly like `pb_definitions`
already merges into `var.custom_policy_definitions`), and assigned once —
`cmp-lz-baseline` — instead of as 6 separate management-group policy
assignments. This is the packaging the README always described ("approved
regions, required tags, public access, ... as one scoped package"); it had
just never been implemented until now.

Why this and not 6 standalone assignments: it's the same shape Microsoft's
own ALZ policy architecture uses at scale — author the guardrail set once,
assign the *same* initiative at as many management-group scopes as the org
grows into (a future `regulated-apps-mg`, a per-business-unit MG, etc.),
each with its own scoped parameter/`not_scopes`/exemption overrides, instead
of re-declaring 6 policy assignments per scope. Each member policy keeps its
own effect/parameter wiring via the initiative's own declared parameters
(the same `[parameters('x')]` ARM-token idiom the MCSB assignment already
uses), so a future need for a policy-specific effect is additive — expose
one more initiative parameter — not a rewrite. Today all 6 already share one
`enforce`/`effect` toggle (`var.policy_baseline.effect` / `.enforce`), so
this change is pure consolidation: same 6 controls, same Audit effect, same
scope — 1 Azure Policy/Compliance object instead of 6. Covered by a new
`terraform test` run, `policy_baseline_packages_into_one_initiative`, in
[`tests/defaults.tftest.hcl`](../../patterns/terraform-azurerm-compeer-global-governance/tests/defaults.tftest.hcl).

`custom_policy_definitions` / `management_group_policy_assignments` in
`terraform.tfvars.example` (6 defs: `allowed_locations`, `required_tags`,
`deny_public_paas`, `secure_storage`, `deny_public_ip`, `sql_private_network`,
assigned at `workloads-mg` in Deny mode) are an **illustrative duplicate** of
`policy_baseline`'s content, written before the baseline existed — the real
deployed tfvars uses only `policy_baseline`, not this block.

---

## 2. `platform-authorization` — workspace `platform-authorization`

**Purpose:** the Entra **authorization foundation** — the only principals ever
granted Azure RBAC. `User → Entra group → Azure role → scope`, never direct.
ALZ Doc Phase 1 §5, Phase 3 §4-5. Identity/RBAC doc: this *is* the codification
of "Build Entra Security Group Framework" / "Build Authorization Framework".

| Block | Resource(s) | Why |
|---|---|---|
| `rbac_groups` | `terraform-azuread-compeer-ad-group` | `AZ-PLT-*`, `AZ-SEC-*`, `AZ-NET-*`, `AZ-AUDIT-*`, `AZ-BREAKGLASS-Admins` groups. Membership deliberately left ungoverned here (see `operational_contracts.access_lifecycle`) |
| `custom_role_definitions` | `terraform-azurerm-compeer-role-definition` | Kept minimal; prefer built-ins |
| `role_assignments` (+ `terraform_data.role_assignment_contract`) | `terraform-azurerm-compeer-role-assignments` | The RBAC Assignment Matrix — group → built-in role → MG scope, standing/least-privilege only (Admin/Owner is PIM-eligible-only, not here) |
| `operational_contracts` | `terraform-azurerm-compeer-operational-contracts` | Declares what's NOT here with rationale: break-glass accounts, cloud-only admin account provisioning, Conditional Access, PIM activation policy*, JML/access reviews |

\* `pim_activation_policy` is tracked here as `codified` — the actual resource
lives in `platform-privileged-access` (see §4).

**Output `group_object_ids`** is the fan-out point every other pattern resolves
group-based RBAC against: `subscription-onboarding`, `workload-spoke`,
`platform-privileged-access`.

---

## 3. `workload-identity` — workspace `platform-workload-identity`

**Purpose:** secret-less **federated workload identities** for CI/CD and IaC
automation. ALZ Doc Phase 4 §7-8 ("Managed Identity Framework" / "Federated
Workload Identity Framework" — the CI/CD half; user-assigned managed identities
for Azure-hosted workloads are `platform-identity` / `workload-spoke`, not
here).

| Block | Resource(s) | Why |
|---|---|---|
| `application` | `terraform-azuread-compeer-ad-application` | App registration per automation identity (e.g. `platform-compeer-control-plane-oidc`) |
| `service_principal` | `terraform-azuread-compeer-service-principal` | SP for each app registration |
| `azuread_application_federated_identity_credential` | — | OIDC trust rules (issuer + subject + audience) — HCP Terraform / GitHub Actions / Azure DevOps. **No client secrets.** Enforces the 20-FIC-per-app limit |
| `azurerm_role_assignment` (SP RBAC) | — | Azure roles the SP itself holds (e.g. `User Access Administrator` on `compeer-enterprise-mg` so it can create the RBAC matrix) |
| `operational_contracts` | — | HCP variable-set wiring (codified elsewhere), GitHub/ADO service-connection config, periodic "no secrets were added" attestation |

---

## 4. `privileged-access` — workspace `platform-privileged-access`

**Purpose:** the IaC-appropriate slice of **Phase 2** (Privileged Identity
Management). "No standing privilege" end to end.

| Block | Resource(s) | Why |
|---|---|---|
| `azurerm_pim_eligible_role_assignment` | — | PIM **eligible** (never active) assignments — group → role → scope, activation only through PIM. Phase 2 §6-7 |
| `role_management_policies` | `terraform-azurerm-compeer-role-management-policy` | PIM **activation policy**: require approval, MFA-on-activation, max duration, notifications, paired per role with the eligible assignment above. Phase 2 §6 |
| `azurerm_monitor_scheduled_query_rules_alert_v2.break_glass_signin` | — | Alerts on ANY sign-in by a break-glass account. Phase 2 §9 |
| `operational_contracts` | — | Break-glass account provisioning (manual by design), admin Conditional Access, secure admin environment/PAW |

Principals for both the eligible assignments and the activation-policy
approvers are resolved from `platform-authorization`'s `group_object_ids` (the
workspace supports `principal_group_key` / `approver_group_key`).

---

## 5. `subscription-onboarding` — workspace `platform-subscription-onboarding`

**Purpose:** places CSP-created subscriptions into their target management
group and applies baseline + app RBAC. ALZ Doc Phase 3 §9 / Phase 8 §6-7. Never
creates subscriptions.

| Block | Resource(s) | Why |
|---|---|---|
| `terraform_data.onboarding_contract` | — | Precondition: every `target_management_group_key` and `principal_group_key` must resolve, before anything is placed |
| `azurerm_management_group_subscription_association.this` | — | Moves the subscription from Tenant Root Group to its target MG |
| `baseline_role_assignments` / `app_role_assignments` | `terraform-azurerm-compeer-role-assignments` | Standing RBAC at subscription scope. `principal_group_key` resolves against `platform-authorization.group_object_ids`; `principal_type = "User"` is rejected outright |

---

## 6. `platform-policy` — workspace `platform-policy`

**Purpose:** everything policy-related that needs a **narrower**, separately
approved workspace than governance: promotion to Deny, DeployIfNotExists
remediation, exemptions, and guardrail initiatives not in the baseline. ALZ Doc
Phase 3 §7-8, Phase 5 §6-9, Phase 6 §3.

| Block | Resource(s) | Why |
|---|---|---|
| `azurerm_policy_definition` / `azurerm_policy_set_definition` (main.tf) | — | Same generic custom-definition/initiative mechanism as governance, scoped to this narrower workspace |
| `azurerm_management_group_policy_assignment` / `azurerm_subscription_policy_assignment` (main.tf) | — | Assignment mechanism |
| `policy_extensions.tf` | `azurerm_resource_group_policy_assignment`, `*_policy_exemption` (MG/sub/RG) | RG-scope assignments; the exemption mechanism for all 3 scopes — mandatory before promoting any baseline policy to Deny |
| `remediation.tf` | `azurerm_management_group_policy_assignment.remediation` (+ system-assigned identity) | Generic DeployIfNotExists bundle — Defender-plan auto-enablement, diagnostic-settings auto-deployment, etc. |
| `private_only_baseline.tf` | (via the generic definition/assignment mechanism) | `deny-public-ip-address` + `deny-nic-public-ip` — Compeer forces all inbound through Cloudflare Tunnels; there's no single Azure "setting" for that, so it's a policy initiative |

**`cmp-required-tags` — two real bugs found and fixed during the client
deployment-readiness review, both in `global-governance`:**

1. **Wrong tag vocabulary.** `pb_required_tags`' default list still had the
   pre-Phase-7 tag names (`env`, `bt_owner`, `tf_workspace`, `recovery`,
   `compliance_boundary`) — the vocabulary `terraform-azurerm-compeer-platform-tags`
   was renamed *away from* in its Phase 7 rebuild (see `HARDENING_STATUS.md`).
   The real `platform-governance/terraform.tfvars` never overrides
   `required_tag_names` (its own comment says it "defaults to the platform-tags
   frozen key set" — which was false). Every resource tagged through the real,
   current tags module would have failed this guardrail on day one. Fixed to
   the module's actual `mandatory_keys`: `environment`, `application`, `owner`,
   `source_repo`, `created_on`, `criticality_tier`, `data_classification`,
   `lifecycle_state`, `cost_center`, `gl_category`.
2. **A more serious latent bug underneath it:** `variables.tf`'s
   `required_tag_names = optional(list(string))` had no type-level default, so
   it resolved to a real `null` for every caller that left it unset (i.e.
   every real tfvars). `try(local.pb.required_tag_names, [...])` does **not**
   substitute its fallback for a legitimate `null` — `try()` only catches
   evaluation *errors* — so `pb_required_tags` was silently `null`, not the
   intended default list, regardless of what that list said. Fixed by giving
   `required_tag_names` a real type-level default (the same list above); the
   `try()` fallback in `policy_baseline.tf` is now redundant but harmless.
   Covered by a new regression assertion in `tests/defaults.tftest.hcl`.

### Full policy picture — live vs. designed, cross-referenced

| Policy / guardrail | Effect (today) | Scope | Status | Where | Design-doc reference |
|---|---|---|---|---|---|
| `cmp-allowed-locations` | Audit | `compeer-enterprise-mg` | **LIVE** | `global-governance` `policy_baseline` | Phase 3 §6 "Allowed Regions" |
| `cmp-required-tags` | Audit | `compeer-enterprise-mg` | **LIVE** | `policy_baseline` | Phase 3 §6 "Tags" |
| `cmp-deny-public-paas` | Audit | `compeer-enterprise-mg` | **LIVE** | `policy_baseline` | Phase 3 §7 Guardrail Cat. 2 (Networking) |
| `cmp-secure-storage` | Audit | `compeer-enterprise-mg` | **LIVE** | `policy_baseline` | Phase 3 §7 Cat. 3 (Data Protection); Phase 5 §5/§8 |
| `cmp-deny-public-ip` | Audit | `compeer-enterprise-mg` | **LIVE** | `policy_baseline` | Phase 3 §7 Cat. 2 |
| `cmp-sql-private-network` | Audit | `compeer-enterprise-mg` | **LIVE** | `policy_baseline` | Phase 3 §7 Cat. 2; Phase 5 §7 |
| Microsoft Cloud Security Benchmark (initiative) | Audit (`enforce=false`) | `compeer-enterprise-mg` | **LIVE** | `policy_baseline` | Phase 6 §6 "Required baseline" |
| `compeer-private-only-connectivity` initiative (`deny-public-ip-address` + `deny-nic-public-ip`) | Audit | `compeer-enterprise-mg` | **LIVE** | `platform-policy` `private_only_connectivity` | Phase 3 §7 Cat. 2 |
| `cmp-allowed-res-types` (built-in "Allowed resource types", `a08ec900-254a-4555-9bf5-e42af04b5c5c`) | Audit, `enforce=false` | `compeer-enterprise-mg` | **LIVE** (report-only; catalog list needs review before `enforce=true`) | `platform-policy` | Phase 3 §6 "Approved Resource Types" |
| `cmp-disk-encrypt-win` (built-in `3dc5edcd-002d-444c-b216-e123bbfa37c0`) | AuditIfNotExists | `workloads-mg` | **LIVE** | `platform-policy` | Phase 5 §6 |
| `cmp-disk-encrypt-linux` (built-in `ca88aadc-6e2b-416c-9de2-5a0f01d1693f`) | AuditIfNotExists | `workloads-mg` | **LIVE** | `platform-policy` | Phase 5 §6 |
| `cmp-vm-backup` (built-in "Azure Backup should be enabled for Virtual Machines", `013e242c-8828-4970-87b3-ab247555486d`) | AuditIfNotExists | `workloads-mg` | **LIVE** | `platform-policy` | Phase 9 / §14 "Backup and Restore… default posture for all workloads" |
| `cmp-cis-benchmark` (built-in initiative "CIS Microsoft Azure Foundations Benchmark v2.0.0", `06f19060-9e68-4070-92ca-f15cc126059e`) | Audit (`enforce=false`, reporting only) | `compeer-enterprise-mg` | **LIVE** | `platform-policy` | Phase 6 §6 "Recommended" (alongside MCSB's "Required baseline") |
| SQL TDE required | — | `workloads-mg` (planned) | **not enabled — no current built-in GUID found** | `platform-policy` tfvars | Phase 5 §7 |
| Managed identity usage audit | — | `workloads-mg` (planned) | **not enabled — no built-in matches the design doc's literal control** | `platform-policy` tfvars | Phase 3 §7 Cat. 1 (Identity) |
| Diagnostic settings required | — | `compeer-enterprise-mg` (planned) | **not enabled — Microsoft's diagnostic-settings model is per-resource-type (dozens of built-ins), not one initiative; needs Compeer to pick target resource types** | `platform-policy` tfvars `remediation.dine_assignments` | Phase 3 §7 Cat. 4 (Logging) |
| "Configure Microsoft Defender for Cloud plans" initiative (`f08c57cd-dbd6-49a4-a85e-9ae77ac959b0`, confirmed, not deprecated) | — | `compeer-enterprise-mg` (planned) | **ID confirmed, not enabled — per-plan pricing tier/subplan (e.g. Servers P1 vs P2) is a licensing/cost decision for Compeer**; also needs `management_group_policy_assignments` (supports `policy_set_definition_id` + identity), not `remediation.dine_assignments` (single-policy only) | `platform-policy` tfvars | Phase 6 §3-4 |
| `custom_policy_set_definitions` (hand-authored custom initiative) | — | — | the **variable** is plumbing only, never populated by a caller; the **resource** it feeds is exercised internally by `private_only_connectivity`'s own initiative, so the mechanism is proven, just not used for anything hand-authored | governance + policy | not named explicitly in either doc — general capability |

**Coverage: 12 policies/initiatives live, 4 explicitly not enabled with a
concrete reason each** (no clean built-in match, a genuine licensing decision,
or a per-resource-type model too broad to default). That accounts for every
policy-shaped control named in the ALZ design doc's Phase 3/5/6/9 and the
Identity & RBAC doc's equivalent phases — nothing in either document names a
policy that isn't in this table. GUIDs were verified against the live Azure
built-in policy catalog (via `azadvertizer.net`, which mirrors the
`Azure/azure-policy` GitHub repo) on 2026-09-11 — not from memory. Every
enabled policy here is **Audit-only**: no Deny, no resource changes, no cost,
report-only-first per this repo's established convention (see Conditional
Access and the private-only-connectivity guardrail for the same principle
applied elsewhere). Flipping any of these to `Deny`/`enforce=true` is a
separate, deliberate decision this pass does not make unprompted.
See `IDENTITY-RBAC-IAC-BOUNDARY.md`'s "Known gaps" section for the ones still
not enabled and why.

Nothing in the **Identity & RBAC doc** maps to an Azure Policy directly — its
only policy-adjacent statement is "policy administration is controlled through
the RBAC group model," which is `platform-authorization`'s group→role→scope
wiring (who can touch policy), not a `Microsoft.Authorization/policyDefinitions`
resource (what the policy does).

---

## 7. `platform-management` — workspace `platform-management`

**Purpose:** the shared observability + backup + Defender/Sentinel + cost
layer. Doesn't touch RBAC groups, MG hierarchy, or policy definitions — those
live in `authorization`/`governance`/`policy`.

| Block | Resource(s) | Why |
|---|---|---|
| `log_analytics` | `azurerm_log_analytics_workspace` | **The** platform workspace — sink for every other pattern's diagnostics, Sentinel's home, Defender's data source. Phase 7 §3 |
| `action_group` | `azurerm_monitor_action_group` | Single alert-routing target reused by metric alerts, Service Health, budgets |
| `platform_storage_accounts` (`audit`) | Storage account, ZRS, no public access, OAuth-only | Long-term audit-log archive sink |
| `platform_key_vaults` (`main`) | Key Vault, RBAC, deny-by-default ACLs | Management-plane secrets — distinct lifecycle/owner from `platform-identity`'s Key Vault (Identity team's) |
| `recovery_services_vaults` (`main`) + backup policies | RSV, zone-redundant | Phase 9/§14 "Backup and Restore… via the centralized Recovery Services Vault" — the default DR posture today |
| `data_collection_endpoints` / `_rules` / `_associations` | AMA plumbing | Modern telemetry pipeline (VM Insights, custom logs) into the LAW |
| `role_assignments`, `log_analytics_contributor_role_assignments` | `terraform-azurerm-compeer-role-assignments` | RBAC on these resources — group-based, per `platform-authorization` |
| `azurerm_security_center_workspace` | — | Points a subscription's Defender findings at this LAW |
| `*_diagnostics` (storage/KV/RSV) + `*_private_endpoints` | Diagnostic settings + PEs | Storage/KV/RSV logs → LAW; private-only access |
| `sentinel` | `terraform-azurerm-compeer-sentinel` | Phase 7 — onboarding, data connectors (identity/Defender/threat-intel), scheduled detection rules |
| `azurerm_monitor_diagnostic_setting.subscription_activity_log` | — | Azure control-plane audit trail (Activity Log) → LAW |
| `azurerm_monitor_aad_diagnostic_setting.entra` | — | **Phase 1 §9** — Entra sign-in/audit/PIM logs → LAW. The identity-monitoring foundation |
| `azurerm_consumption_budget_subscription` | — | Subscription-scope cost governance |
| `management_locks` | `CanNotDelete` | Protects the durable resources above |
| `azurerm_security_center_subscription_pricing`, `security_contact`, `security_center_settings` | — | **Phase 6** — Defender plan enablement (subscription-scope), notification routing, MCAS/WDATP |
| `defender_soc_posture_contract` | `terraform_data` guard | Precondition: can't claim "Defender Standard enabled" posture without real `defender_plans` content |
| `platform_alerts.tf`: `platform_metric_alerts`, `service_health` | — | Baseline alerting + Azure Service Health, routed to the action group |

**Sentinel detection content**: the module ships 2 default rules (Palo Alto
CEF-forwarding-stopped, critical threat log). `platform-management`'s
`terraform.tfvars.example` now carries 5 additional real (commented) KQL rules
— `new_global_administrator`, `owner_role_assigned`, `pim_role_activation`,
`mg_or_policy_change`, `password_spray_suspected` — pending validation against
the tenant's connected tables before enabling.

---

## 8. `platform-connectivity` — workspace `platform-connectivity`

**Purpose:** the hub network. ALZ Doc Phase 3 §7 Cat. 2 (networking guardrails
consume this), Phase 4 §4/§6 (Bastion, private endpoints).

| Block | Resource(s) | Why |
|---|---|---|
| `hub_vnet` | VNet + typed subnets | Address space owned explicitly here; smoke-test tfvars reserve `GatewaySubnet` + Palo Alto trust/untrust/management subnets without deploying paid services by default |
| `network_security_groups` / `subnet_nsg_associations` | — | Per-subnet NSGs |
| `route_tables` / `subnet_route_table_associations` | — | UDRs — see the Palo Alto route contract below |
| `ddos_protection_plan` | — | Optional, off by default (cost) |
| `public_ips`, `route_server_public_ips`, `route_server` | — | Optional hooks for Palo Alto egress / BGP route injection |
| `private_dns_zones` / `private_dns_hub_links` / `private_dns_resolver` | — | Private DNS. Phase 1 default is `dc-forwarders` (hub VNet DNS → approved DC resolvers over ExpressRoute); `private-resolver` is switched on only after the NET-27 decision |
| `bastion_public_ip` / `bastion` / `bastion_diagnostics` | `terraform-azurerm-compeer-bastion-host` | Eliminates public admin RDP/SSH. Phase 4 §4 |
| `load_balancers` | — | Palo Alto egress / HA hooks |
| `azurerm_network_watcher` + `network_watcher_flow_logs` | — | NSG flow logs |
| `local_network_gateways` | — | On-prem VPN peer definitions (paired with `platform-hybrid-connectivity`'s VPN gateway) |
| `terraform_data.palo_alto_route_contract` | — | Precondition: when `palo_alto.enabled=true`, every `VirtualAppliance` route next-hop must match an approved Palo Alto private IP, and declared Palo Alto subnet keys must exist in the hub VNet |
| `terraform_data.dns_resolution_contract` | — | Precondition guarding the DNS mode switch above |
| `role_assignments`, `management_locks`, `diagnostic_settings` | — | RBAC (group-based), lock protection, hub-resource diagnostics → LAW |

**Verified against the real deployed `platform-connectivity` tfvars** (not just
the smoke-test example): `bastion.enabled`, `ddos_protection_plan.enabled`,
and `dns_resolution.enabled` are all `false` today. Unlike the policy pattern's
gaps, these are **deliberate, cost-driven decisions already documented in the
pattern README** ("do not deploy paid firewall, gateway, DNS resolver, or DDoS
services by default") — not something to force on.

Two contracts (`palo_alto_route_contract`, `dns_resolution_contract`) had zero
test coverage before this pass despite gating a real security architecture
decision (every egress route must point at an approved firewall IP). Added
`tests/contracts.tftest.hcl` (9 new runs: off-by-default no-op, each
precondition's failure case, and a valid-configuration pass, for both
contracts) — all green, no code changes needed, the contracts were already
correct.

**Found, not fixed — a real logging gap, left for a decision, not silently
patched:** `network_watcher_flow_logs = {}` in the real tfvars — no NSG flow
logs are actually being collected, even though `azurerm_network_watcher`
itself is created unconditionally. Design doc / Identity & RBAC doc (Phase 7
§6, "Connect Azure Platform Data Sources… Network Security: NSG Flow Logs")
calls for this. Wiring it needs a flow-log destination (the `platform_storage_accounts.audit`
storage account already created in `platform-management`, or a new
Traffic-Analytics-enabled workspace) and a per-NSG or subscription-wide scope
decision — a small real cost, so it's flagged here rather than turned on
unprompted.

---

## 9. `platform-identity` — workspace `platform-identity-security`

**Purpose:** the Identity team's shared identity + security foundations. Phase
4 §2-3/§7-8 (the managed-identity half; federated/CI-CD identity is
`workload-identity`).

| Block | Resource(s) | Why |
|---|---|---|
| `platform_identities` | `terraform-azurerm-compeer-user-assigned-identity` | User-assigned managed identities for platform components |
| `key_vault` | `terraform-azurerm-compeer-keyvault` | RBAC-first, private-by-default platform Key Vault. Phase 4 §2 |
| `disk_encryption_sets` | `terraform-azurerm-compeer-disk-encryption-set` | CMK disk encryption. Phase 5 §6 — required for `regulated-apps-mg`/Restricted data |
| `role_assignments` | `terraform-azurerm-compeer-role-assignments` | Group-based RBAC on the Key Vault/identities |
| `key_vault_private_endpoint` / `key_vault_diagnostics` | — | Private access + logging |
| `management_locks` | — | `CanNotDelete` on the vault/RG |

Certificate contacts are intentionally empty in the smoke-test tfvars (AzureRM
4.x deprecated the inline `contact` field). Live secret values, certificate
private keys, and break-glass credentials never go through this pattern's
Terraform state — Terraform manages the vault/RBAC/PE/diagnostics container,
not the secret contents.

---

## 10. `platform-hybrid-connectivity` — workspace `platform-hybrid-connectivity`

**Purpose:** on-premises connectivity — ExpressRoute (primary) + VPN (backup).
Optional/placeholder until the carrier design is approved; kept in its own
workspace because circuit activation, provider coordination, and cutover
windows have a different approval chain than the hub network baseline.

| Block | Resource(s) | Why |
|---|---|---|
| `expressroute_circuits` / `expressroute_gateway` / `gateway_public_ips` / `expressroute_connections` | — | Primary hybrid path |
| `vpn_gateway` / `vpn_gateway_public_ips` / `local_network_gateways` / `vpn_connections` | — | Backup hybrid path |
| `terraform_data.expressroute_contract` / `terraform_data.vpn_contract` | — | Preconditions: when `expressroute_posture.enabled=true`, requires at least one circuit + gateway public IP + gateway + connection, plus a provider design reference, BGP/routing approval, and cutover-window approval — so hybrid connectivity can't be half-promoted by accident |

Requires `platform-connectivity`'s hub VNet to already expose `GatewaySubnet`.
Smoke-test tfvars leave `expressroute_posture.enabled = false` (cost-free).

---

## 11. `palo-alto-hub` — workspace `platform-palo-alto`

**Purpose:** the Azure side of the Palo Alto VM-Series firewall HA pair,
**image-based, not the Marketplace solution template** — so the shape matches
Compeer's actual requirement (2 firewalls + an extra internal LB/NICs for
Sunstream, private-only edge) instead of the fixed 2-VM/1-LB template shape.
ALZ Doc §8.5 (hub firewall, default-deny, Panorama-managed).

| Block | Resource(s) | Why |
|---|---|---|
| `azurerm_marketplace_agreement.palo_alto` | — | Still required — it's the VM **image licence**, not the solution template |
| `bootstrap_key_vault` / `_rbac` / `_private_endpoint` | — | Bootstrap secrets (licenses, initial config) for the firewalls |
| `bootstrap_storage` + `azurerm_storage_share*` + `local_file` | — | Bootstrap file share (`init-cfg.txt`, `bootstrap.xml`) VM-Series reads on first boot |
| `terraform_data.bootstrap_contract` | — | Precondition guarding bootstrap completeness before VM creation |
| `public_ips` / `network_interfaces` / `load_balancers` | — | Untrust/trust/management NICs, HA internal LBs |
| `azurerm_linux_virtual_machine.this` | — | The firewall VMs themselves |

Firewall policy, routing, and NAT are managed through Panorama post-boot — not
Terraform — consistent with Compeer's existing operating model (design doc
§8.5).

---

## 12. `directory-services` — workspace `platform-directory-services`

**Purpose:** hub-hosted Active Directory domain controllers.

| Block | Resource(s) | Why |
|---|---|---|
| `network_interfaces` / `domain_controllers` | `terraform-azurerm-compeer-windows-virtual-machine` | The DC VMs |
| `azurerm_managed_disk.data` + `azurerm_virtual_machine_data_disk_attachment` | — | AD DS database/logs data disk, separate from the OS disk |
| `domain_join` | — | Optional Terraform-owned domain join, ahead of manual AD DS promotion |
| `vm_diagnostics` | — | Boot/guest diagnostics → LAW |
| `role_assignments`, `management_locks` | — | Group-based RBAC + lock protection |
| `operational_contracts` | `terraform-azurerm-compeer-operational-contracts` | Records the AD DS decision below with rationale |
| `azurerm_backup_protected_vm.dc` | — | Enrols DCs into the Recovery Services Vault from `platform-management` |
| `terraform_data.controller_contract` | — | Precondition on DC configuration completeness |

**Resolved: AD DS role install + promotion are not Terraform-owned.** The
design runbook always specified this (Ansible/PowerShell DSC instead,
domain-admin secrets never through Terraform variables). This pattern
briefly carried a Terraform-owned bridge for both
(`azurerm_virtual_machine_extension.ad_ds_role_install` / `.ad_ds_promotion`
+ `var.ad_ds_promotion_passwords`) to stand DCs up end-to-end during early
build-out. **Confirmed with the network/AD team:** Terraform stops at a
domain-joined, ready-to-promote VM; AD DS role install and promotion happen
manually (or via the approved config-management pipeline) once the VM has
joined the domain. The bridge has been removed from the pattern —
VM/NIC/disk/diagnostics/lock/domain-join stay Terraform-owned.

---

## 13. `cloudflare-connectors` — workspace `platform-cloudflare-connectors`

**Purpose:** the Azure-side hub-hosted `cloudflared` connector VMs — the
outbound-only tunnel endpoints that make external-apps workloads reachable
without any inbound public IP. Design doc §8.6.

| Block | Resource(s) | Why |
|---|---|---|
| `network_interfaces` (no public IPs) / `azurerm_linux_virtual_machine.this` | — | Connector VMs |
| `azurerm_virtual_machine_extension.this` | — | `cloudflared` install |
| `vm_diagnostics` | — | → LAW |
| `role_assignments`, `management_locks` | — | Group-based RBAC + lock protection |
| `operational_contracts` | — | Connector runtime tokens are injected via sensitive workspace variables or external config-management, not tracked here |
| `terraform_data.connector_contract` | — | Precondition on connector configuration completeness |

Does **not** own Cloudflare tunnels, DNS, Access policy, WAF, or account
settings — that's `terraform-cloudflare-compeer-edge-baseline` (§17).

---

## 14. `shared-services` — workspace `platform-shared-services`

**Purpose:** the dedicated shared-services VNet spoke for platform-adjacent
capabilities (API management, enterprise scheduling, data platform, messaging)
— design doc §6.1/§8.7, dormant until activated.

A thin wrapper: `main.tf` is a single `module "shared_services" { source =
"../terraform-azurerm-compeer-workload-spoke" ... }` call. It reuses the exact
same spoke composition as any workload (§15) — VNet, subnets, NSGs, route
tables, hub peering, private DNS links, diagnostics, RBAC, locks, identity,
optional Key Vault — under a **separate platform workspace boundary** so
shared-services lifecycle doesn't couple to any one workload team's apply
cadence.

---

## 15. `workload-spoke` (template) — one workspace per workload × environment

**Purpose:** an application landing-zone network boundary. Instantiated many
times (`prod-compeer-lz-internalapps-apim`, `dev-compeer-lz-internalapps-scheduler`, …).

| Block | Resource(s) | Why |
|---|---|---|
| `spoke_vnet` | — | Workload VNet + subnets |
| `network_security_groups` / `subnet_nsg_associations` | — | Per-subnet NSGs |
| `route_tables` / `subnet_route_table_associations` | — | UDRs (egress via hub firewall) |
| `spoke_to_hub_peering` | — | Optional here — leave `hub_connection = null` when the dedicated `network-peering` root owns the attachment, so only one state owns each peering resource |
| `private_dns_spoke_links` | — | Links the spoke VNet to the shared private DNS zones |
| `workload_identity` | `terraform-azurerm-compeer-user-assigned-identity` | App-side managed identity |
| `workload_key_vault` + `_role_assignments` + `_diagnostics` + `_private_endpoint` | — | Workload-scope secrets, RBAC-first, private |
| `private_endpoints` | — | Generic map for any other workload PaaS service |
| `role_assignments`, `management_locks`, `diagnostic_settings` | — | Group-based RBAC, lock protection, diagnostics → LAW |

For a new workload subscription, grant the HCP run identity `Contributor` at
that subscription before first apply — this root creates the RG, networking,
and locks.

---

## 16. `network-peering` (template) — one workspace per hub↔spoke pair

**Purpose:** owns the cross-subscription VNet peering + shared private-DNS
zone links between one hub and one spoke, in a dedicated workspace so exactly
one state owns each peering resource (never enable `hub_connection` in
`workload-spoke` for the same spoke).

| Block | Resource(s) | Why |
|---|---|---|
| `terraform_data.resolved_input_validation` | — | Precondition on resolved hub/spoke inputs before creating peering |
| `hub_to_spoke_peering` / `spoke_to_hub_peering` | — | Both directions of the VNet peering |
| `private_dns_spoke_links` | — | Shared private DNS zones linked to the spoke |

Consumes `platform-connectivity` and the target `workload-spoke` outputs via
`tfe_outputs` by default.

---

## 17. `terraform-cloudflare-compeer-edge-baseline` — workspace `platform-cloudflare-edge`

**Purpose:** the Cloudflare-owned control-plane resources for external-app
ingress. Design doc §8.6.

| Block | Resource(s) | Why |
|---|---|---|
| `cloudflare_zone` / `cloudflare_record` | — | DNS |
| `cloudflare_ruleset` | — | WAF/edge rules |
| `zero_trust_tunnels` | — | Zero Trust tunnel + ingress config, paired with the Azure-side connector VMs in `platform-cloudflare-connectors` |
| `terraform_data.tunnel_secret_contract` | — | Precondition — tunnel secrets come from HCP sensitive variables, not plaintext tfvars |

Cloudflare's edge WAF, DDoS protection, bot management, and access policy sit
in front of the Azure hub — traffic still passes the hub firewall's
default-deny posture once the tunnel delivers it (§8.6 in the design doc: "the
internal inspection model doesn't change, only how traffic enters").

---

## Not deployed: `subscription-vending`

Retained for reference only. Creates subscriptions directly (EA/MCA billing
model); Compeer's CSP partner creates subscriptions today, so
`subscription-onboarding` (§5) is the pattern actually used — it *places*
CSP-created subscriptions rather than creating them.
