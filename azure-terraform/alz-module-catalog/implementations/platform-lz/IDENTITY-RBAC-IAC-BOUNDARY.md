# Identity & RBAC — IaC vs. Manual Boundary

Source: **Compeer Identity & RBAC Design — Implementation Process v2.0** (10 phases).

This document records, for every step of that runbook, whether it is delivered as
Terraform (and by which workspace) or deliberately kept outside Terraform (and
why). The rule Compeer follows is the common industry one:

> **Codify the durable, declarative, blast-radius-bounded control plane. Keep out
> of IaC anything whose failure mode is "we cannot get into the tenant", anything
> whose source of truth is a person/HR/ITSM system, and anything the provider
> cannot yet express safely.**

Machine-readable form: every workspace below emits an `operational_contracts`
output (`terraform-azurerm-compeer-operational-contracts`) whose
`manual_control_keys` lists the non-codified controls with rationale and evidence
locations. Enabling a `contract-only` control without an implementation fails the
plan.

## New workspaces added for this

| Workspace | Pattern | Covers |
|---|---|---|
| `platform-authorization` | `terraform-azurerm-compeer-platform-authorization` | Entra RBAC security groups, MG-scope role assignments, custom roles |
| `platform-workload-identity` | `terraform-azurerm-compeer-workload-identity` | App registrations + SPs + federated (OIDC) credentials + SP RBAC |
| `platform-privileged-access` | `terraform-azurerm-compeer-privileged-access` | PIM **eligible** role assignments, break-glass sign-in alert |

Already present: `platform-governance` (MG hierarchy, custom roles, policy),
`platform-identity-security` (platform Key Vault, user-assigned MIs, identity-scope
RBAC), `platform-management` (Log Analytics, Sentinel, Defender plans, Entra
diagnostic settings), `platform-subscription-onboarding` / `platform-subscriptions`
(MG placement + subscription-scope RBAC), `platform-policy` (guardrails).

## Legend

- **IaC** — Terraform-managed. Workspace named.
- **Hybrid** — Terraform manages part; a tracked `operational_contract` covers the rest.
- **Manual** — deliberately outside Terraform. `implementation_state` is one of
  `manual-control` (lockout / blast-radius risk), `external-system` (owned by
  HR/IGA/ITSM/SOC/endpoint), `provider-gap` (no safe provider coverage yet).

---

## Phase 1 — Identity Foundation

| Step | Delivery | Where / why |
|---|---|---|
| 1. Identity discovery & current-state assessment | Manual (`external-system`) | Discovery exercise; output is the Identity Assessment Report. |
| 2. Define target identity architecture | Manual | Design artifact. |
| 3. Entra governance foundation (naming, ownership, review standards) | Manual | Standards document. Naming is then enforced by Azure Policy (`platform-policy`) and by the module naming conventions. |
| 4. Cloud-only administrative identities (`AZADM-*`) | **Manual** (`external-system`) | Account objects + credential/auth-method registration are provisioned through the joiner process / IGA. Their **Azure authority is granted only via groups + PIM**, never directly. Contract: `cloud_only_admin_accounts`. |
| 5. Entra security group framework (`AZ-*`) | **IaC** — `platform-authorization` | `azuread_group` per `rbac_groups` entry. |
| 6. Authorization framework (role mapping matrix) | **IaC** — `platform-authorization` | `role_assignments` = the RBAC matrix, group → role → scope. |
| 7. Identity lifecycle processes (JML) | **Manual** (`external-system`) | Joiner/mover/leaver automation is Entra ID Governance / IGA. Terraform owns the group object, not its membership. Contract: `access_lifecycle`. |
| 8. Workload identity framework | **IaC** — `platform-workload-identity` (federated) + `platform-identity-security` / `workload-spoke` (managed identities) | Standards become code. |
| 9. Identity monitoring (Entra audit / sign-in / PIM logs) | **IaC** — `platform-management` | `azurerm_monitor_aad_diagnostic_setting` → Log Analytics; Sentinel identity connectors. |
| 10. Validate & transition | Manual | Test evidence. |

## Phase 2 — Privileged Access Control Plane

| Step | Delivery | Where / why |
|---|---|---|
| 1. Inventory existing privileged access | Manual | Baseline report. |
| 2. Deploy cloud-only admin accounts | **Manual** (`external-system`) | As Phase 1 Step 4. |
| 3. Emergency access accounts (`EMERGENCY-01/02`) | **Manual** (`manual-control`) | Microsoft-recommended to keep outside automation and identity sync; credentials split and sealed; excluded from all Conditional Access. Contract: `break_glass_accounts`. **Terraform does add the sign-in alert** (`platform-privileged-access`, `break_glass_alert`). |
| 4. Administrative authentication standards (phishing-resistant MFA) | **Manual** (`manual-control`) | Authentication-methods policy + authentication strengths are tenant configuration; Graph-based management is high risk. |
| 5. Administrative Conditional Access | **Manual** (`manual-control`) | Tenant-wide, highest lockout blast radius; report-only rollout required. Contract: `conditional_access` / `admin_conditional_access`. Provider (`azuread_conditional_access_policy`) exists but Compeer keeps CA portal-managed by policy. |
| 6. Deploy Entra PIM | **Hybrid** — `platform-privileged-access` | `azurerm_pim_eligible_role_assignment` for Azure resource roles. Entra **directory-role** PIM eligibility and all **activation-policy settings** (approval, MFA-on-activation, max duration, notifications) are `provider-gap` → portal. Contract: `pim_activation_policy`. |
| 7. Convert active → eligible privileges | **IaC** — `platform-privileged-access` | Admin/Owner roles are **not** in the standing `platform-authorization` matrix; they exist only as eligible assignments here. |
| 8. Secure administration environment (PAW / secure AVD) | **Manual** (`external-system`) | Endpoint team (Intune compliance, PAW build). Referenced by the admin CA policy. Contract: `secure_admin_environment`. |
| 9. Monitoring & alerting (emergency login, new GA, Owner assignment, PIM bypass) | **IaC** — `platform-privileged-access` (break-glass) + `platform-management` (Sentinel analytics rules) | |
| 10. Validation & security testing | Manual | |

## Phase 3 — Governance, Azure RBAC, Guardrails

| Step | Delivery | Where |
|---|---|---|
| 1. Design & validate MG hierarchy | Manual (design) | |
| 2. Deploy MG hierarchy | **IaC** — `platform-governance` → `terraform-azurerm-compeer-management-groups` | |
| 3. Administrative scope model | Manual (design) → realized by Steps 4-5 | |
| 4. Azure RBAC framework / custom roles | **IaC** — `platform-authorization` (`custom_role_definitions`) + `platform-governance` | Prefer built-in roles; minimal custom roles. |
| 5. Map Entra groups → Azure roles | **IaC** — `platform-authorization` (`role_assignments`) | |
| 6. Core governance policies (naming, tags, regions, allowed types) | **IaC** — `platform-policy` / `platform-governance` (`policy_baseline`) | |
| 7. Security guardrails (identity / network / data / logging) | **IaC** — `platform-policy` | |
| 8. Compliance & monitoring policies | **IaC** — `platform-policy` + `platform-management` | |
| 9. Subscription governance framework | **IaC** — `platform-subscription-onboarding` (+ `platform-subscriptions`) | |
| 10. Validation & governance testing | Manual | |

## Phase 4 — Platform Security Services

| Step | Delivery | Where |
|---|---|---|
| 1. Security Services subscription | **IaC** — `platform-subscriptions` / `platform-subscription-onboarding` | |
| 2. Platform Key Vault (`KV-PLATFORM-*`, RBAC, private) | **IaC** — `platform-identity-security` | |
| 3. Key management framework | **Hybrid** — `platform-identity-security` (vault, RBAC, keys) | Key **values**, rotation execution, custodian ceremony stay out of state. |
| 4. Azure Bastion | **IaC** — `platform-connectivity` (hub) | |
| 5. Secure administration path | Manual (design) — composed of Phase 2 + Bastion | |
| 6. Private endpoint framework | **IaC** — `platform-connectivity` (zones) + per-service patterns | |
| 7. Managed Identity framework | **IaC** — `platform-identity-security` / `workload-spoke` (`user-assigned-identity`) | |
| 8. Federated workload identity framework | **IaC** — `platform-workload-identity` | App + SP + FIC; **20 FIC / app** limit enforced. HCP variable-set wiring: contract `hcp_variable_set_wiring` (→ `platform-iac-foundation`). GitHub/ADO side: `external-system`. |
| 9. Platform security logging | **IaC** — `platform-management` | |
| 10. Validation | Manual | |

## Phase 5 — Data Protection & Encryption

| Step | Delivery | Where |
|---|---|---|
| 1-4. Classification, encryption standards, CMK framework, Key Vault integration | **Hybrid** — standards are `platform-policy`; CMK keys are `platform-identity-security` | |
| 5-8. Storage / compute / database / in-transit encryption controls | **IaC** — `platform-policy` (enforce) + per-workload patterns (configure) | |
| 9. Azure Policy encryption guardrails | **IaC** — `platform-policy` | |
| 10. Validation | Manual | |

## Phase 6 — Microsoft Defender for Cloud

| Step | Delivery | Where |
|---|---|---|
| 1-2. Architecture & governance model | Manual (design) | |
| 3. Enable Defender at MG scope | **IaC** — `platform-policy` (DeployIfNotExists) | MG-scope enablement is via Policy; `azurerm_security_center_subscription_pricing` is subscription-scoped. |
| 4. Core Defender plans | **IaC** — `platform-management` (`defender_plan_ids`) + `platform-policy` for inheritance | |
| 5-7. CSPM, regulatory frameworks, workload protection plans | **Hybrid** — plan enablement IaC; framework assignment + attack-path review are portal/console | |
| 8-9. Remediation & operations model | **Manual** (`external-system`) | SOC / platform run process. |
| 10. Validation | Manual | |

## Phase 7 — Microsoft Sentinel / SOC

| Step | Delivery | Where |
|---|---|---|
| 2. Security monitoring subscription | **IaC** — `platform-subscriptions` | |
| 3. Log Analytics architecture | **IaC** — `platform-management` | |
| 4. Deploy Sentinel | **IaC** — `platform-management` (`sentinel_onboarding_id`) | |
| 5-7. Connect identity / Azure / security data sources | **IaC** — `platform-management` (Sentinel connectors) | |
| 8. Detection rules | **IaC** — `platform-management` (Sentinel analytics rules), incl. identity/privileged/emergency-account detections | |
| 9. Incident response framework | **Manual** (`external-system`) | SOC runbooks / playbooks. |
| 10. Validation | Manual | |

## Phase 8 — Secure Subscription Provisioning

| Step | Delivery | Where |
|---|---|---|
| 1-4. Governance model, types, workflow, request/approval | Manual (design / ITSM) | |
| 5. Subscription vending automation | **IaC** — `platform-subscriptions` (`subscription-vending`) | |
| 6. Automate MG placement | **IaC** — `platform-subscription-onboarding` | |
| 7. Automate security configuration (RBAC via Entra groups, policy) | **IaC** — `platform-subscription-onboarding` (RBAC) + `platform-policy` (inheritance) | Consumes `platform-authorization` `group_object_ids`. |
| 8. Automate monitoring & compliance config | **IaC** — `platform-policy` DINE + `platform-management` | |
| 9. Operational ownership framework | **Manual** (`external-system`) | Handover package / CMDB. |
| 10. Validation | Manual | |

## Phase 9 — Secure Workload Onboarding

Per-workload; delivered by `platform-workload-spoke` + workload service patterns
(APIM, SQL, AKS, …). Identity: managed identities (IaC), Entra app auth (IaC or
workload team), user auth to Entra (workload config). Security review gate,
production-readiness assessment, and operational handover are **Manual**
(`external-system`) governance gates.

## Phase 10 — Entra-Only Transition & Continuous Governance

| Step | Delivery | Where / why |
|---|---|---|
| 1-4. Assess & remove hybrid privileged dependencies | **Manual** (`external-system`) | Migration project; Terraform's admin RBAC already targets cloud-only groups. |
| 5. Entra identity governance operations (access reviews, lifecycle workflows, entitlement mgmt) | **Manual** (`external-system`) | Entra ID Governance features; not safely IaC-managed today. |
| 6. Continuous access governance (monthly/quarterly/annual RBAC reviews, direct-assignment detection) | **Manual** (`external-system`) + policy | Access reviews are Entra; direct-assignment *detection* is a Sentinel rule (`platform-management`) and an OPA plan guardrail. |
| 7. Conditional Access governance | **Manual** (`manual-control`) | As Phase 2 Step 5. |
| 8. Security compliance governance | **Hybrid** — compliance data is IaC (Policy, Defender); the review cadence is a process | |
| 9. Continuous security operations | **Manual** (`external-system`) | SOC. |
| 10. Operational acceptance & governance transition | Manual | |

---

## Why the "Manual" items stay manual — the short version

| Item | Reason it is not IaC |
|---|---|
| Break-glass / emergency accounts | If the pipeline, the identity sync, or the automation SP is broken or compromised, you must still be able to sign in. Automating their creation couples tenant recovery to the thing most likely to be broken. |
| Cloud-only admin account objects | Source of truth is HR / the joiner process. Terraform would fight the IGA system and could not hold the credential material. |
| Conditional Access (management plane) | One bad apply locks every administrator (including the pipeline identity) out of the portal and ARM. Report-only rollout and human verification are mandatory. |
| Authentication methods / strengths | Tenant-singleton policy; provider coverage is partial and a mistake is tenant-wide. |
| PIM activation-policy settings | `provider-gap` — the eligible *assignment* is codified; approval/MFA/duration settings are not safely expressible yet. |
| Access reviews / entitlement management / JML | Owned by Entra ID Governance / the IGA platform; these are workflow state, not declarative infrastructure. |
| SOC runbooks, remediation processes, readiness gates | Process and human judgment, not resources. |
| PAW / secure admin devices | Endpoint management (Intune) domain. |

Everything else in the runbook that creates a **durable Azure or Entra object**
— management groups, security groups, role definitions, role assignments, PIM
eligible assignments, app registrations, service principals, federated
credentials, Key Vault, managed identities, diagnostic settings, policy, Defender
plans, Sentinel, subscription placement — **is Terraform-managed** in the
workspaces above.
