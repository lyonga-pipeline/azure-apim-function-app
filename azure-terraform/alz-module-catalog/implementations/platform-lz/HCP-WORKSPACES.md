# HCP Terraform — Platform Landing Zone workspaces

Give the platform deployment **service principal** access to the **project**, not
each workspace, so new workspaces don't need re-provisioning.

| | |
|---|---|
| **HCP organization** | `Compeer-Financial-Services` |
| **HCP project** | `Platform-Landing-Zone` |
| **SP permission** | Project-level **Write** (plan + apply on every workspace, current and future) |
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

**Peering (template):** `platform-compeer-peering-<spoke>`.

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
| `platform-compeer-management` | management | `platform-management` | Log Analytics, Automation, Recovery Services vault + backup policies, action groups, DCR / DCE, activity-log + Entra diagnostics, **Sentinel onboarding + connectors + analytics rules**, **Defender for Cloud plans + security contacts**, **subscription-scope budgets** |
| `platform-compeer-identity` | identity | `platform-identity-security` | Platform Key Vault, user-assigned managed identities, identity-scope RBAC, KV private endpoint |
| `platform-compeer-directory-services` | directory-services | `platform-directory-services` | Domain-controller VMs + NICs + data disks, AD DS role install, DC promotion hook, DC backup protection |

### Phase 3 — Connectivity & edge

| Workspace | Component | Working dir | Deploys |
|---|---|---|---|
| `platform-compeer-connectivity` | connectivity | `platform-connectivity` | Hub VNet + all subnets, NSGs, route tables, DDoS plan, Bastion, private-link DNS zones + VNet links, private DNS resolver, route server |
| `platform-compeer-palo-alto` | palo-alto | `platform-palo-alto` | Palo Alto VM-Series firewalls (2+), NICs, trust/untrust/Sunstream internal LBs, public IPs, `azurerm_marketplace_agreement`, bootstrap storage + Key Vault (inline) or bootstrap share layout |
| `platform-compeer-cloudflare-connectors` | cloudflare-connectors | `platform-cloudflare-connectors` | Cloudflare Tunnel connector VMs in the hub (Azure side), NICs, `cloudflared` install |
| `platform-compeer-cloudflare-edge` | cloudflare-edge | `platform-cloudflare-edge` | Cloudflare zones, tunnels, tunnel configs, **public DNS records**, Access applications + policies — `cloudflare` provider, `CLOUDFLARE_API_TOKEN` env var |
| `platform-compeer-hybrid-connectivity` | hybrid-connectivity | `platform-hybrid-connectivity` | ExpressRoute circuit + gateway + connections, VPN gateway + local network gateways + connections, gateway public IPs |

### Phase 4 — Shared services

| Workspace | Component | Working dir | Deploys |
|---|---|---|---|
| `platform-compeer-shared-services` | shared-services | `platform-shared-services` | Shared-services VNet + subnets, shared platform Key Vault, shared workload resources, private endpoints |
| `platform-compeer-image-gallery` *(buffer)* | image-gallery | *new* | Azure Compute Gallery, shared image definitions + versions, build automation |
| `platform-compeer-container-registry` *(buffer)* | container-registry | *new* | Shared premium ACR with private endpoints, geo-replication, token/scope maps |

### Templates — instantiate per target

| Workspace pattern | Component | Working dir | Deploys |
|---|---|---|---|
| `platform-compeer-peering-<spoke>` | network-peering | `platform-network-peering` | Hub ↔ spoke VNet peering (both directions) + shared private-DNS VNet links. One per spoke, e.g. `platform-compeer-peering-internalapps-apim` |
| `<env>-compeer-lz-<domain>-<appcode>` | workload-spoke | `platform-workload-spoke` | A workload landing zone: spoke VNet + subnets, NSGs, route tables, workload Key Vault, private endpoints, hub connection, workload RBAC. Examples: `prod-compeer-lz-internalapps-apim`, `dev-compeer-lz-internalapps-scheduler`, `prod-compeer-lz-sharedservices-apim` |

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
| `platform-compeer-container-registry` | A shared platform ACR is required (vs per-workload ACR) | `platform-compeer-shared-services` or per-workload |
| `platform-compeer-tfe-bootstrap` | HCP itself (project, variable sets, VCS, these workspaces) is managed as code (`tfe` provider) | done once by hand |

### Not needed — the design doc capability is already covered

| Proposed workspace | Why it's not separate |
|---|---|
| `platform-compeer-cost` | Budgets are inputs on `governance` (MG scope) and `management` (subscription scope). No cost-export requirement in the design doc. |
| `platform-compeer-sentinel` | The `management` root has full Sentinel onboarding + connectors + scheduled analytics rules (incl. the Palo CEF forwarding-health rule). Split later only if the SOC team wants an independent apply cadence — an org-process choice, not a design requirement. |
| `platform-compeer-defender` | Defender for Cloud plans + security contacts are inputs on `management`; the MCSB initiative is assigned by `governance`. |
| `platform-compeer-dns` | Private DNS is centralized in the hub (`connectivity` — zones, VNet links, resolver, bidirectional hybrid forwarding). Public/external DNS is Cloudflare's authoritative zone (`cloudflare-edge`). No Azure public DNS zone in the design. |

## Count

- **Core platform workspaces to create now:** 15 with a built root (+ `platform-subscriptions` exists but is NOT deployed)
- **Buffer / conditional:** 5 (create only on the trigger above)
- **Templates:** 2 (peering, workload-spoke) — instantiated many times
- **Total platform footprint with buffer:** ~20 + templates + N workload LZs

## Deployment order

`governance → authorization → workload-identity → privileged-access →
subscription-onboarding → policy → management → connectivity → identity →
directory-services → hybrid-connectivity → palo-alto → cloudflare-connectors →
cloudflare-edge → shared-services`, then peering + workload LZs.

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
