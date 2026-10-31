# Compeer Phase 2 Engineering Handoff

## Deployment Ownership

Phase 2 is a delivery milestone, not a separate infrastructure control plane. Reusable code remains in `patterns/` and `modules/`; canonical deployment roots live alongside their existing platform or workload owners. [implementation-map.json](implementation-map.json) is the machine-readable test/deployment index.

### Existing Workspaces: Additive Sections

Every changed root has a clearly delimited **PHASE 2 CHANGES** section in `main.tf`, plus `phase2_variables.tf`, `phase2_outputs.tf`, `phase2.tfvars.example` and `phase2-tests/`. Keep existing files/inputs and module addresses; add the marked sections rather than replacing deployed configuration.

| Existing root under `implementations/platform-lz/workspaces/` | Phase 2 inputs | Resource ownership |
| --- | --- | --- |
| `platform-management` | `phase2_log_alerts`, `phase2_metric_alerts`, `phase2_workbooks`, optional additional `phase2_action_group_ids` | Alerts/workbooks reuse the existing RG, LAW, primary action group and effective tags. No second LAW/action group. |
| `platform-connectivity` | `phase2_connection_monitors` | Watcher-based probes in the connectivity subscription; central LAW is consumed through the existing public-output mechanism. |
| `platform-directory-services` | `phase2_agents`, `phase2_agent_ownership_confirmed` | Windows AMA/inventory/associations keyed by this root's DC keys. VM IDs are resolved internally. |
| `platform-cloudflare-connectors` | Same agent inputs | Linux AMA/inventory/associations keyed by this root's shared connector keys. VM IDs are resolved internally. |
| `platform-policy` | `phase2_audit_initiatives`, `phase2_exemptions`, `phase2_sandbox_scope` | Approved audit rollout, expiring exemptions and sandbox expiry. FinOps inputs are not exposed. |

Shared DCR/DCE definitions still belong in the existing `management.data_collection_rules` / `management.data_collection_endpoints` inputs. Existing DCR associations, extensions, alerts, policy assignments, exemptions and budgets **retain their original addresses/owner**. Do not copy a resource from an old input into a new Phase 2 map merely to relabel it.

Agent installation requires the declared UAMI to be assigned through the existing VM identity input, appropriate OS/network readiness and explicit state-ownership review. Use `install_agent=false` plus `existing_agent_confirmed=true` when another retained extension owner manages AMA. A VM's DCE configuration association and each DCR association must have only one owner. Do not enable a duplicate association against an unchanged management-owned association; complete an approved handoff first.

Connection Monitor remains under network ownership. The management extension does not expose agent/probe collections, and VM extensions do not create central alerts/workbooks.

### Network Attachment Standard Update

The [peering standard](../platform-lz/PEERING-STANDARD.md), revised 2026-10-28,
selects environment-and-hub/network-boundary attachment states for multiple approved
spokes, with dedicated-state exceptions. It supersedes a per-application attachment
workspace default, not the separate per-application workload foundation states.
The retained peering adapter still handles one pair. The new AzAPI batch pattern
and two disabled prod/nonprod roots implement the map-based alternative without
subscription alias growth. [Gate tooling and adoption](../platform-lz/network-attachments/README.md)
still require external protected checks, scoped OIDC/RBAC, a published/pinned release
and live pilot evidence. No HCP workspace or grant is created by these code changes.

Hub/spoke VNets and routes retain their original owners. The split-owned legacy
identity peering remains an explicit exception until a reviewed handoff; it is not
silently centralized. Do not add standalone routes to current inline-managed tables.
Network-approved Git inventory authorizes attachment; public producer contracts
must match it. Review aggregate environment permissions, shared-hub residual access,
exact plan/apply federation and serialization within and across runs before enabling.

Phase 2 peering activities 5.3/6.2 use `platform-network-peering-prod`; sandbox
activity 10.2 uses `platform-network-peering-nonprod`. Retain the single-pair root
only for existing legacy states, not as the default for new Phase 2 attachments.
Partner tenant/topology approval remains mandatory; cross-tenant partners are not
supported by this single-tenant batch and need a separately approved design.

`platform-identity-external` now accepts optional `central_attachment` metadata and
publishes `network_attachment_contract` v3.0.0 using its actual VNet outputs.
Set the approved tenant/hub/DNS intent in its example, then merge the matching
platform-v3 entry into the complete production attachment inventory. The metadata
creates no peerings/DNS links and retains the older `central_attachment_inputs`
output. `central_attachment=null` preserves existing callers; disabled roots do
not read provider context for this handoff. See the identity root's README for
the complete inventory entry and explicit no-zone/optional-zone behavior.

### Separate Canonical Roots

| Root | Location | Reason for distinct state |
| --- | --- | --- |
| `platform-log-archive` | `implementations/platform-lz/workspaces/` | Long-lived retained data, independent retention approval and careful destructive-change control. |
| `platform-finops` | Same platform location | Subscription-scoped financial controls; independent permissions from MG policy administration. |
| `platform-security-automation` | Same platform location | Privileged event/rotation workflow ownership. |
| `platform-hcp-governance` | Same platform location | HCP administrative API/credentials, not ordinary Azure deployment. |
| `platform-services` | Same platform location | Compute-owner gallery and patch schedules. Split further only if real owner/privilege/lifecycle differences justify it. |
| `platform-identity-external` | Same platform location | Separate external identity subscription/forest/backup boundary. |
| `workload-external-apps-prod` | `implementations/workload-lz/workspaces/` | Independent application/environment state and release selection. |
| `workload-sandbox` | Same workload location | Isolated sandbox subscription, expiry and approvals; not a runtime selector for production. |

Instantiate a separate FinOps/app root for each independently managed subscription/environment. Inventory budgets in management/onboarding states before adding a FinOps budget; `ownership_confirmed` and `existing_budget_names` guard this boundary. No policies/exemptions are passed to the FinOps pattern call.

**External DC caution:** legacy `platform-directory-services/terraform.tfvars` contains `extdc01/extdc02`. They have not been deleted or moved. The new external root requires `existing_identity_owner_checked=true` and deployment approval. Verify the live legacy state and intended subscription before enabling it; never deploy the same forest/controllers through both roots.

## Patterns And Release Dependencies

All older and additional reusable patterns are retained. The existing `phase2-governance` pattern remains a compatibility composition: platform-policy calls only its policy capabilities; platform-finops calls only financial capabilities. A shared pattern does not imply shared state or shared credentials.

The management, connectivity, directory-services and Cloudflare-connector patterns now expose the additive `resource_tags` output. Directory-services also exposes `identity_vnet_address_space` for the external identity v3 contract. **Publish reviewed patch releases of those patterns before using the new root sections with HCP registry sources.** Older published releases lacking these outputs cannot be used with the new composition unchanged. Publish/pin the attachment package including its output-only `producer` submodule. This repository validates the actual local pattern interfaces; it does not assume an unpublished HCP release exists.

The five extended existing roots explicitly require Terraform >=1.11.4, <2 to match the capability modules. Set their HCP/VDI toolchain accordingly. Do not silently upgrade providers: retain existing provider lockfiles unless a provider upgrade is separately reviewed. New roots also require reviewed registry pins and committed provider lockfiles before deployment.

## Safe Adoption

1. Keep existing HCP workspace/state/subscription and original core module addresses. New capability defaults are empty; committed deployed `terraform.tfvars` values are unchanged.
2. Share each existing root's marked `main.tf` section, all `phase2_*.tf` files, its non-auto-loaded example and tests. Include the reusable pattern/helper changes and publish required releases first.
3. Merge only the NEW top-level inputs from `phase2.tfvars.example` into that owner's configuration. Never replace a complete existing `management`, `policy` or VM object with a partial example: Terraform replaces whole objects.
4. Confirm one owner per Azure/HCP resource. Test, run a real-state speculative plan and reject unintended replacements/deletions. Enable one approved capability at a time.
5. Configure HCP working directories, main-branch trigger paths, scoped credentials, output-read access and manual production approvals per owner. Composition is not a reason to grant every run identity project-wide or cross-subscription write access.
6. Complete [live acceptance](RUNBOOKS.md). Mock tests do not prove connectivity, query validity, backup recovery or event delivery.

The user confirmed the former `implementations/phase2/workspaces` roots were **not applied**. Their files were moved into canonical owner paths or absorbed into existing roots; redundant deployment roots were removed. No state move/import/apply was performed. Existing deployed workspaces and caller interfaces are preserved except for the explicitly documented toolchain minimum and additive optional inputs/outputs.

Phase 3 remains excluded. No new ARM management locks, subscription vending enablement or automatic teardown is introduced.
