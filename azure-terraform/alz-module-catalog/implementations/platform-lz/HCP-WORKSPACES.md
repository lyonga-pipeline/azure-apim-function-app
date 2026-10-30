# HCP Terraform — Platform Landing Zone workspaces

Align HCP project/workspace roles with infrastructure ownership. Scope each Azure
OIDC run identity independently to its required resources. Do not grant project-wide
Write access merely to consume another workspace's public outputs.

| | |
|---|---|
| **HCP organization** | `Compeer-Financial-Services` |
| **HCP project** | `Platform-Landing-Zone` |
| **HCP access** | Owner-scoped plan/apply roles; production approvals and least-privilege output-read access across owners |
| **VCS repo** | `Compeer-financial-cloud/InfrastructureAutomation/<this repo>` |
| **Auth** | HCP dynamic credentials / OIDC to Azure; `tenant_id` in a shared **variable set** (category Terraform), `subscription_id` a workspace variable (category Terraform) |

## Naming convention

**Platform workspaces:** `platform-compeer-<component>`

- `platform` is the scope token — it replaces the `prod` / `sb1` slot in Compeer's
  existing names (`prod-online-olb-resource-groups`). The platform LZ is a single
  control plane, not an environment, so it does not carry `prod`.
- `compeer` is the org marker Compeer's convention already uses
  (`…-compeer-patch-maintenance-olb`, `secrets-rotation-compeer-base-infrastructure`).
- `<component>` is the platform building block — the component reads straight off
  the name. It matches the `component` token the pattern's naming module uses, so
  workspace ↔ resource names line up (`platform-compeer-connectivity` deploys
  `platform-cus-prod-connectivity-rg`).

**Workload landing zones:** `<env>-compeer-lz-<domain>[-<appcode>]` — these *are*
environment-specific, so they keep the `prod` / `dev` / `test` prefix
(`prod-compeer-lz-internalapps-apim`).

**Peering target:** `platform-network-peering-<env>[-<hub-boundary>]`, grouped by
environment/hub under [PEERING-STANDARD.md](PEERING-STANDARD.md). Existing
per-spoke workspace names are compatibility owners until an approved handoff;
do not rename HCP workspaces or federation subjects implicitly.

## Platform workspaces

Working directory = `azure-terraform/alz-module-catalog/implementations/platform-lz/workspaces/<dir>`.

### Phase 1 — Governance & subscriptions

| Workspace | Component | Working dir | Deploys |
|---|---|---|---|
| `platform-compeer-governance` | governance | `platform-governance` | Management-group hierarchy (enterprise → platform/workloads/sandbox/decommissioned + children), custom role definitions, policy **baseline** in Audit, MCSB assignment, **MG-scope budgets** |
| `platform-compeer-authorization` | authorization | `platform-authorization` | **Entra RBAC security groups** (`AZ-*`), **MG-scope role assignments** (the RBAC matrix), custom roles, identity/RBAC `operational_contracts` — needs directory write + User Access Administrator |
| `platform-compeer-workload-identity` | workload-identity | `platform-workload-identity` | **Federated (OIDC) workload identities** — app registrations + service principals + federated credentials + SP RBAC for HCP / GitHub / ADO. No client secrets. |
| `platform-compeer-privileged-access` | privileged-access | `platform-privileged-access` | **PIM eligible role assignments** (no standing admin/Owner), break-glass sign-in alert, privileged-access `operational_contracts` |
| `platform-compeer-subscription-onboarding` | subscription-onboarding | `platform-subscription-onboarding` | Places CSP-created subscriptions into their target MG, applies baseline + app RBAC at subscription scope (consumes `authorization` group IDs) |
| `platform-compeer-policy` | policy | `platform-policy` | Policy assignments (MG / sub / RG scope), exemptions, DeployIfNotExists remediation identities, private-only connectivity guardrail |

Identity / RBAC IaC boundary (what is codified vs. deliberately manual across all
10 design-doc phases): see `IDENTITY-RBAC-IAC-BOUNDARY.md`.

### Phase 2 — Management & identity

| Workspace | Component | Working dir | Deploys |
|---|---|---|---|
| `platform-compeer-management` | management | `platform-management` | Log Analytics, platform diagnostics/artifact storage accounts, action groups, DCR / DCE, activity-log + Entra diagnostics, **Sentinel onboarding + connectors + analytics rules**, **Defender for Cloud plans + security contacts**, **subscription-scope budgets** |
| `platform-compeer-sentinel` | sentinel-content | `platform-sentinel` | Sentinel **content as code** on the central workspace: data connectors, analytics rules (scheduled, NRT, Microsoft incident creation, template, anomaly), automation rules, watchlists, opt-in baseline detections. Deploy AFTER `platform-management` (which owns onboarding); ships disabled. Subscription = the management subscription. Needs output-read access to `platform-management` (`tfe_outputs`; no remote state sharing needed). |
| `platform-compeer-identity` | identity | `platform-identity-security` | Platform Key Vault, user-assigned managed identities, identity-scope RBAC, Key Vault diagnostics. Platform Key Vault private endpoint remains on hold and must be connectivity-owned when approved. |
| `platform-compeer-directory-services` | directory-services | `platform-directory-services` | Domain-controller VMs + NICs + data disks, identity-subscription Recovery Services vault + backup protection. AD DS installation/promotion is a separately approved AD workflow |

### Phase 3 — Connectivity & edge

| Workspace | Component | Working dir | Deploys |
|---|---|---|---|
| `platform-compeer-connectivity` | connectivity | `platform-connectivity` | Hub VNet + subnets, NSGs, route tables, optional DDoS/Bastion/Watcher, private-link DNS zones + VNet links. Existing DC forwarders provide DNS; no new Private Resolver |
| `platform-compeer-palo-alto` | palo-alto | `platform-palo-alto` | Palo Alto VM-Series firewalls (2+), NICs, trust/untrust/Sunstream internal LBs, public IPs, `azurerm_marketplace_agreement`, bootstrap storage + Key Vault (inline) or bootstrap share layout, connectivity-subscription firewall Recovery Services vault + backup protection |
| `platform-compeer-cloudflare-connectors` | cloudflare-connectors | `platform-cloudflare-connectors` | Cloudflare Tunnel connector VMs in the hub (Azure side), NICs, `cloudflared` install |
| `platform-compeer-cloudflare-edge` | cloudflare-edge | `platform-cloudflare-edge` | Cloudflare zones, tunnels, tunnel configs, **public DNS records**, Access applications + policies — `cloudflare` provider, `CLOUDFLARE_API_TOKEN` env var |
| `platform-compeer-hybrid-connectivity` | hybrid-connectivity | `platform-hybrid-connectivity` | ExpressRoute circuit + gateway + connections, VPN gateway + local network gateways + connections, gateway public IPs |

### Phase 4 — Platform buffers

**Retired: `platform-compeer-shared-services`.** Its whole premise — a
dedicated VNet spoke, peered to the hub, for domain-controller-adjacent
"shared services" — was corrected in design review: those services belong
directly in the hub, not a separate peered VNet. A shared-services *workload*
(e.g. a shared APIM instance) is now just an ordinary `workload-spoke`
instantiation like any other spoke — see the `prod-compeer-lz-sharedservices-apim`
example under Templates below — not a dedicated pattern. See
`PATTERN-REFERENCE.md`'s "Deployment order" section for the full writeup.

| Workspace | Component | Working dir | Deploys |
|---|---|---|---|
| `platform-compeer-image-gallery` *(buffer)* | image-gallery | *new* | Azure Compute Gallery, shared image definitions + versions, build automation |
| `platform-compeer-container-registry` *(buffer)* | container-registry | *new* | Shared premium ACR with private endpoints, geo-replication, token/scope maps |

### Templates — instantiate per target

| Workspace pattern | Component | Working dir | Deploys |
|---|---|---|---|
| `platform-network-peering-prod` | production attachments | `platform-network-peering-prod` | Both directions + approved DNS links for prod only. Disabled, complete tfvars example. |
| `platform-network-peering-nonprod` | non-production attachments | `platform-network-peering-nonprod` | Both directions + approved DNS links for allowlisted actual environments, initially np1/np2/np3. Disabled, complete tfvars example. |
| Existing legacy workload workspaces | workload-spoke (legacy) | `platform-workload-spoke` | Compatibility implementation for existing states. Superseded for NEW internal-applications deployments by the Step 11 roots below; do not repoint an existing state without a reviewed migration. |

The authoritative [peering standard](PEERING-STANDARD.md), revised 2026-10-30,
supersedes per-spoke and four-stage defaults with two independent prod/nonprod
attachment roots. Non-production stages share one state, release, approval and
permission scope; their real producer labels are preserved and allowlisted.
The unapplied np1/np2/np3 examples were consolidated, not deployed states migrated.
Copy [the generic root template](templates/network-attachments/README.md) only
for another justified hub/security/lifecycle boundary. The batch supports
generic platform/workload v3 and existing workload v2. The gate inventory lists
only actual hub writers; omit nonexistent examples and include all real writers.
Each has an independent root/state/trigger path; publish/pin its approved batch
release before deployment. The retained `platform-network-peering` is a single-pair compatibility root;
do not repoint an applied legacy backend to either new root without a handoff. The new batch uses one AzAPI provider with full resource IDs, not dynamic
AzureRM aliases. OIDC principals are environment/boundary scoped, preferably
separate plan/apply, with exact resource grants and federation subjects rather
than one identity per application. Shared-hub grants and concurrency remain shared
risks; enforce a hub gate across relevant runs and serialize pairs inside each run.

### Step 11 workload templates

These working directories are under
`azure-terraform/alz-module-catalog/implementations/workload-lz/workspaces/`,
not the platform-lz directory above. Instantiate a separate HCP workspace/state
per approved application and actual environment; the names below are examples.
For independently promoted applications/environments, also instantiate a distinct
root directory with its own exact blueprint release pin and VCS trigger path.
Do not share one working directory and choose the deployment with runtime tfvars.
Both roots call independently pinned blueprint releases directly; the unused
workload shared adapter has been removed.
See [isolation and same-state migration](../workload-lz/ISOLATION.md) for the
required main-branch workspace settings and promotion sequence.

| Workspace pattern | Working dir | Profile |
|---|---|---|
| `prod-compeer-lz-internalapps-<appcode>` | `workload-internal-apps-prod` | Production; WKL-01 blueprint, mandatory private vault/UAMI and central diagnostics; Phase 2 telemetry/alerts/data services held; budget stays with governance unless handed off |
| `<env>-compeer-lz-internalapps-<appcode>` | `workload-internal-apps-nonprod` | dev/test/uat/approved np aliases; same security baseline with different cost/resilience/alerting defaults |

Both committed examples are disabled placeholders. Select Terraform **1.11.4**
in HCP and on the VDI: the new patterns require >=1.11.4 and <2, and catalog CI
uses exactly 1.11.4. Newer versions need a reviewed test run before adoption.
AzureRM remains on 4.x; the Application Insights module requires >=4.81.
Keep workload provisioning permissions scoped to the workload subscription.
Only the separate central attachment identity receives approved hub VNet/DNS
and spoke attachment permissions; do not grant workload teams platform-project
Write access merely to consume published resource IDs.

For HCP output access, exact producer names must match the actual organization,
for example platform-compeer-management, platform-compeer-connectivity and
platform-compeer-governance. The last supplies mandatory_tag_keys, which the
spoke validates and republishes with the LAW/RG IDs for application consumers.
The roots use tfe_outputs.nonsensitive_values, not terraform_remote_state.
Configure the TFE provider with a valid, approved token with **Read outputs**
access on those producer workspaces; keep the token sensitive and out of Git.
Azure OIDC credentials do not authenticate the HCP API. Remote-state-sharing
controls do **not** apply to tfe_outputs; do not enable full-state sharing or
organization-wide access to fix an empty output map. First check token access,
exact organization/workspace names, a completed producer apply, and non-sensitive
root outputs. The deployment contract fails closed if required outputs are
unreadable. Approved explicit platform_inputs remain an alternative.
See [HashiCorp's state-access distinction](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/state#data-source-configuration)
and [tfe_outputs](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/outputs).

Subscription creation/placement stays outside these spokes: CSP creation,
governance hierarchy, dedicated subscription onboarding and authorization/policy
owners remain unchanged. Future vending stays separate and disabled.
For deployment gates and actual NET-22 evidence, see
[the workload acceptance runbook](../workload-lz/ACCEPTANCE.md).

### Not deployed / reference only

| Workspace | Why |
|---|---|
| ~~`platform-compeer-subscription-vending`~~ | CSP creates subscriptions; vending code kept for a future EA/MCA model only. Working dir `platform-subscriptions` — do **not** create a workspace. |

## Buffer / conditional — create only if the trigger applies

| Workspace | Create it when | Otherwise it lives in |
|---|---|---|
| `platform-compeer-entra-config` | The Identity team wants Conditional Access / authentication-method / PIM-policy settings under change control via the `azuread` provider once coverage + lockout guardrails are approved | portal-managed today; tracked in `platform-authorization` / `platform-privileged-access` `operational_contracts` |
| `platform-compeer-palo-alto-bootstrap` | The network team wants the bootstrap storage/KV provisioned **and validated** before the firewall VMs boot (two-phase) | `platform-compeer-palo-alto` (the pattern creates bootstrap storage + KV inline) |
| `platform-compeer-image-gallery` | Shared golden-image pipeline is in scope for this phase | not needed for the base LZ |
| `platform-compeer-container-registry` | A shared platform ACR is required (vs per-workload ACR) | per-workload |
| `platform-compeer-tfe-bootstrap` | HCP itself (project, variable sets, VCS, these workspaces) is managed as code (`tfe` provider) | done once by hand |

### Original Baseline Ownership

These baseline owners are retained. The workbook v5 Phase 2 additions below
extend them and add distinct FinOps/archive/services owners where justified.

| Proposed workspace | Why it's not separate |
|---|---|
| `platform-compeer-cost` | Existing budgets remain with governance/management. Phase 2 uses the distinct `platform-finops` root for approved new budgets, exports and anomaly notifications after an ownership inventory; it must not recreate retained budgets. |
| `platform-compeer-sentinel` | The `management` root has full Sentinel onboarding + connectors + scheduled analytics rules (incl. the Palo CEF forwarding-health rule). Split later only if the SOC team wants an independent apply cadence — an org-process choice, not a design requirement. |
| `platform-compeer-defender` | Defender for Cloud plans + security contacts are inputs on `management`; the MCSB initiative is assigned by `governance`. |
| `platform-compeer-dns` | Private DNS is centralized in the hub (`connectivity` — zones, VNet links, resolver, bidirectional hybrid forwarding). Public/external DNS is Cloudflare's authoritative zone (`cloudflare-edge`). No Azure public DNS zone in the design. |

## Count

- **Core platform workspaces to create now:** 14 with a built root (+ `platform-subscriptions` exists but is NOT deployed)
- **Buffer / conditional:** 5 (create only on the trigger above)
- **Templates:** 2 Step 11 workload foundation examples, 4 optional attachment examples and a generic platform/custom-environment root template. Instantiate only needed boundaries; all new examples are disabled and legacy roots remain compatibility-only.
- **Total platform footprint with buffer:** ~19 + templates + N workload LZs

Those are baseline counts, not approval to create one attachment workspace per
application. The environment/hub attachment count follows PEERING-STANDARD.md;
the new batch roots are disabled until their publication/adoption gates are completed.

## Deployment order

`governance → authorization → workload-identity → privileged-access →
subscription-onboarding → policy → management → connectivity → identity →
directory-services → hybrid-connectivity → palo-alto → cloudflare-connectors →
cloudflare-edge`, then workload foundation, central attachment, and live acceptance
(including a shared-services
workload spoke, if/when one is instantiated — see the retirement note above).

- `authorization` runs right after `governance` — its role assignments target the
  MG scopes `governance` creates, and every downstream RBAC consumer reads its
  `group_object_ids`.
- `workload-identity` can run any time after `governance`; in a bootstrapped
  world it is what mints the SPs the other workspaces authenticate as (chicken-
  and-egg for the very first apply is broken with a temporary admin identity).
- `privileged-access` runs after `authorization` (principals) and `management`
  (Log Analytics for the break-glass alert).
- `policy` can run after `management` (it reads the Log Analytics workspace ID).

See `WORKSPACES.md` for the dependency detail.

## Workbook v5 Phase 2 Owner Integration

**PHASE 2 CHANGES:** the legacy design-phase headings above are not the workbook's rollout phases. No workbook Phase 3 resources are enabled here. Use the [engineering handoff](../phase2/ENGINEERING-HANDOFF.md) and [implementation map](../phase2/implementation-map.json) as the current adoption index.

Existing HCP workspaces retain their current state and core module addresses. The management, connectivity, directory-services, Cloudflare-connector and policy roots now contain visibly marked optional Phase 2 sections. Their extra inputs default empty; do not create parallel Phase 2 workspaces for those capabilities.

| New workspace example | Canonical working-directory suffix | Ownership |
| --- | --- | --- |
| `platform-compeer-log-archive` | `platform-lz/workspaces/platform-log-archive` | Retention/export/audit lifecycle; existing LAW/DNS reused. |
| `platform-compeer-finops-<subscription>` | `platform-lz/workspaces/platform-finops` | One independently instantiated root/state per subscription; no MG policy. |
| `platform-compeer-security-automation` | `platform-lz/workspaces/platform-security-automation` | Approved rotation event delivery. |
| `platform-compeer-hcp-governance` | `platform-lz/workspaces/platform-hcp-governance` | Existing HCP health assessments only. |
| `platform-compeer-services` | `platform-lz/workspaces/platform-services` | Private Compute Gallery and approved maintenance schedules. |
| `platform-compeer-identity-external` | `platform-lz/workspaces/platform-identity-external` | Dedicated external-forest infrastructure; explicit legacy-owner check. |
| `prod-compeer-lz-externalapps-<appcode>` | `workload-lz/workspaces/workload-external-apps-prod` | Independent external-app environment. |
| `<env>-compeer-lz-sandbox-<appcode>` | `workload-lz/workspaces/workload-sandbox` | Isolated sandbox. |

Prefix working-directory suffixes with `azure-terraform/alz-module-catalog/implementations/`. Clone a distinct root directory and pin for each independently promoted subscription/application/environment; do not point independently promoted workspaces at one runtime-selected root.

The former phase-based roots were confirmed unapplied. No HCP workspace/state migration, resource import or deployment was performed. Before enabling, publish the documented pattern releases, set Terraform >=1.11.4, retain reviewed provider locks, configure root-specific main-branch trigger paths/credentials and review a real-state plan. Older deployed resource owners remain unchanged.
