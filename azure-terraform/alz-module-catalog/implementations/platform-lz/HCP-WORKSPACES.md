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
| `platform-compeer-governance` | governance | `platform-governance` | Management-group hierarchy (enterprise → platform/workloads/sandbox/decommissioned + children), custom role definitions, policy **baseline** in Audit, MCSB assignment |
| `platform-compeer-subscription-onboarding` | subscription-onboarding | `platform-subscription-onboarding` | Places CSP-created subscriptions into their target MG, applies baseline + app RBAC at subscription scope |
| `platform-compeer-policy` | policy | `platform-policy` | Policy assignments (MG / sub / RG scope), exemptions, DeployIfNotExists remediation identities, private-only connectivity guardrail |
| `platform-compeer-cost` *(buffer)* | cost | *new* | Budgets, cost-export to storage, anomaly alerts — split from governance if a separate owner is wanted |

### Phase 2 — Management & identity

| Workspace | Component | Working dir | Deploys |
|---|---|---|---|
| `platform-compeer-management` | management | `platform-management` | Log Analytics workspace, Automation account, Recovery Services vault + backup policies, action groups, DCR / DCE, activity-log + Entra diagnostic settings |
| `platform-compeer-sentinel` *(buffer)* | sentinel | *new* | Sentinel onboarding, data connectors, scheduled analytics rules, watchlists — split from management once SOC owns content |
| `platform-compeer-defender` *(buffer)* | defender | *new* | Defender for Cloud plans, security contacts, auto-provisioning — split from management if security owns it |
| `platform-compeer-identity` | identity | `platform-identity-security` | Platform Key Vault, user-assigned managed identities, identity-scope RBAC, KV private endpoint |
| `platform-compeer-directory-services` | directory-services | `platform-directory-services` | Domain-controller VMs + NICs + data disks, AD DS role install, DC promotion hook, DC backup protection |
| `platform-compeer-entra` *(buffer)* | entra | *new* | Entra security groups (`AZ-<DOMAIN>-<Role>`), named locations, Conditional Access, break-glass, app registrations — needs `azuread` provider |

### Phase 3 — Connectivity & edge

| Workspace | Component | Working dir | Deploys |
|---|---|---|---|
| `platform-compeer-connectivity` | connectivity | `platform-connectivity` | Hub VNet + all subnets, NSGs, route tables, DDoS plan, Bastion, private-link DNS zones + VNet links, private DNS resolver, route server |
| `platform-compeer-palo-alto` | palo-alto | `platform-palo-alto` | Palo Alto VM-Series firewalls (2+), NICs, trust/untrust/Sunstream internal LBs, public IPs, `azurerm_marketplace_agreement`, bootstrap share layout |
| `platform-compeer-palo-alto-bootstrap` *(buffer)* | palo-alto-bootstrap | *new* | Phase-1 bootstrap storage account + Key Vault for firewall init-cfg / certs, if run as a separate phase before the firewalls |
| `platform-compeer-cloudflare-connectors` | cloudflare-connectors | `platform-cloudflare-connectors` | Cloudflare Tunnel connector VMs in the hub (Azure side), NICs, `cloudflared` install |
| `platform-compeer-cloudflare-edge` | cloudflare-edge | `platform-cloudflare-edge` | Cloudflare zones, tunnels, tunnel configs, DNS records, Access applications + policies — `cloudflare` provider, `CLOUDFLARE_API_TOKEN` env var |
| `platform-compeer-hybrid-connectivity` | hybrid-connectivity | `platform-hybrid-connectivity` | ExpressRoute circuit + gateway + connections, VPN gateway + local network gateways + connections, gateway public IPs |
| `platform-compeer-dns` *(buffer)* | dns | *new* | Public DNS zones, external delegation, split-horizon records — if separated from connectivity |

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

## Bootstrap (one-time, usually outside this list)

| Workspace | Deploys |
|---|---|
| `platform-compeer-tfe-bootstrap` *(buffer)* | The HCP project, variable sets, VCS connection, and the workspaces above — if you manage HCP itself as code (`tfe` provider). Often done once by hand instead. |

## Count

- **Core platform workspaces to create now:** 12 with a built root (+ `platform-subscriptions` exists but is NOT deployed)
- **Buffer workspaces** (create only if a component gets its own owner / cadence): 9
- **Templates:** 2 (peering, workload-spoke) — instantiated many times
- **Total platform footprint with buffer:** ~21 + templates + N workload LZs

## Deployment order

`governance → subscription-onboarding → policy → management → connectivity →
identity → directory-services → hybrid-connectivity → palo-alto →
cloudflare-connectors → cloudflare-edge → shared-services`, then peering +
workload LZs. `policy` can run after `management` (it reads the Log Analytics
workspace ID). See `WORKSPACES.md` for the dependency detail.
