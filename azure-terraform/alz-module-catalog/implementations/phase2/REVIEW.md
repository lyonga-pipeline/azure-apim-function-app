# Phase 2 Completion Review

Reviewed 2026-10-27 against the v5 **Phase 2 Deployment Order** and **Component List**. The workbook is unchanged. [coverage.json](coverage.json) preserves source row numbers and distinguishes implemented, manual, external, decision-gated and excluded work.

## Scope Reconciliation

- All 49 deployment-order activities are accounted for: **45 Phase 2 activities** and **four Phase 3 exclusions** (1.4/IAC-04, 4.5/NET-35, 4.6/NET-40, 9.4/IAC-11).
- GOV-01, IAM-05, SEC-04 and SEC-12 are additionally marked Phase 2 in Component List but omitted from the deployment-order sheet. Their existing governance, OIDC, Sentinel and central Bastion implementations are now mapped and regression-tested.
- Phase 3 HCP teams/RBAC and repo/workspace bootstrap scaffolding has been removed from this delivery, not merely disabled. No new App Gateway/WAF/failover implementation is included.
- Existing dormant management-group branches are not removed: deleting deployed groups to narrow scope would violate backward compatibility. This delivery adds no Phase 3 hierarchy; a separate Phase 2-only hierarchy fixture proves that it is not required.

## Second-Pass Corrections

| Area | Correction | Why it matters |
| --- | --- | --- |
| Private AMA | Explicit DCE configuration association, AMPLS/readiness inputs and create/reuse ownership; inventory DCR key is required for Change Tracking. | A DCR association alone does not configure private agent access. A VM has only one configuration DCE association. |
| Baseline alerts | Native metric composition and pilot examples for ER BGP, Palo ILB probes and LAW export failure; KQL dimensions supported. | Alerts about ingestion/export failures must not depend solely on healthy log ingestion. Backend probes are not full firewall/HA health. |
| Archive | Explicit blob versioning, blob audit plus account metrics; no empty lifecycle policy when deletion is omitted. | Account-level WORM requires versioning. An empty management policy is not a usable retention implementation. |
| Shared audit LAW | Reuse allowed only when the export excludes its own StorageBlobLogs/AzureMetrics. | Avoid creating an unnecessary workspace while preventing an export/ingestion feedback loop. |
| External identity | Explicit inspected hub/on-premises routes, BGP suppression, NSG/route associations, no bypass next hops, immutable image requirement and bounded AD-port examples. | A default route alone does not beat more-specific system/BGP routes. Approval must cover both DCs, backup and the AD design. |
| HCP drift | Actual workspace lookup and ID/mode checks; preserve existing auto-apply/state sharing; consumers are optional assertions, not replacements. | Enabling assessments must not reset an agent workspace or revoke/broaden existing output access. Verify the actual agent pool separately before import. |
| Federation | Exact-subject/HTTPS issuer validation and separate environment/plan/apply fixtures. | Do not turn CI/CD trust into a wildcard or a single shared privileged principal. Existing resource addresses and RBAC defaults remain unchanged. |
| Verification | Source-sheet name/relationship resolution, independent Component List comparison, Phase 3 exclusion checks, enabled pilot root tests and CI integration. | A mapped file or an empty default plan is not acceptance evidence for an enabled capability. |

## Compatibility And Ownership

New optional capabilities default empty/null/false. Deployed Phase 1 resources are not automatically adopted, renamed, replaced or moved. Existing resource addresses and default ownership remain intact. There are no new ARM management locks. WORM retention approval is a different control from resource locks.

Reuse central LAW/DNS, existing notification routes, DCR/DCE, VM identities, Watcher and approved HCP workspaces. Use the current state owner for extensions, associations, pricing, budgets, policies and exemptions. If ownership must change, review import/state handoff separately and reject any unexpected delete/replacement plan.

Both directions of new attachments are centrally owned. The split-owned existing platform identity peering remains a documented legacy exception until an approved handoff. Application and external-identity roots do not obtain hub-write permissions. CSP subscription onboarding remains governance-owned; vending stays disabled pending CSP approval. FinOps budgets are separate Phase 2 resources, not part of the spoke blueprint. The 2026-10-29 [peering standard](../platform-lz/PEERING-STANDARD.md) selects environment/hub-boundary grouping. The new AzAPI batch and four disabled roots implement that API; the retained adapter stays single-pair. Protected gate setup, OIDC/RBAC, registry pinning and live acceptance remain external adoption gates.

## Production Release Gates

The implementation is locally verified; **the estate is not declared production-accepted**. Before enabling each component:

1. Replace every synthetic UUID, IPAM range, image version, contact, date and approval reference. Publish and independently pin reviewed registry releases in each deployment root.
2. Confirm existing state ownership, least-privilege execution identities, provider registration, quota/SKU/region support, subscription placement and required policy exceptions. Run a speculative plan against real state; require no unintended Phase 1 replacements/deletions.
3. Close the workbook's open decisions with named owners: regulatory applicability/retention, ITSM endpoint/schema, CMK requirement, monitoring overlap, SCCM vs Update Manager, golden-image pipeline, DDoS applicability, partner topology and external-forest trust/DNS design.
4. Complete manual/vendor work: SolarWinds/SCCM paths, carrier/Equinix/BGP/static routes, Panorama/SNAT, Cribl/Cloudflare delivery, MDE onboarding, AD promotion, ITSM integration and a tested backing-service secret-rotation handler. Terraform cannot manufacture these approvals or business-specific workflows.
5. Prove live ingestion, alert-to-incident delivery, export/retention, both-direction routing, AD replication, backup restore, patching and approved failover. Record actual results using [RUNBOOKS.md](RUNBOOKS.md) and [DR-FRAMEWORK.md](DR-FRAMEWORK.md).

One pre-existing compatibility warning remains: the Sentinel Fusion resource's `name` argument is deprecated under AzureRM 4.81.0. The pattern is pinned below v5. Migrate that existing detection resource as a separately reviewed provider upgrade; removing it here could change deployed detection identity.

See [TESTING.md](TESTING.md) for reproducible mock results and boundaries. No Azure/HCP apply, import, remediation, rotation, patching or failover was performed.

## Technical References

- [Microsoft: private AMA requires DCE/AMPLS configuration](https://learn.microsoft.com/en-us/azure/azure-monitor/fundamentals/private-link-vm-kubernetes).
- [Microsoft: version-level WORM and creation-time/versioning requirements](https://learn.microsoft.com/en-us/azure/storage/blobs/immutable-version-level-worm-policies).
- [Microsoft: LAW export limitations](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/logs-data-export) and [native export metrics](https://learn.microsoft.com/en-us/azure/azure-monitor/reference/supported-metrics/microsoft-operationalinsights-workspaces-metrics).
- [Microsoft: ER availability metrics](https://learn.microsoft.com/en-us/azure/azure-monitor/reference/supported-metrics/microsoft-network-expressroutecircuits-metrics) and [ILB health metrics](https://learn.microsoft.com/en-us/azure/azure-monitor/reference/supported-metrics/microsoft-network-loadbalancers-metrics).
- [HashiCorp: Azure dynamic credentials and separate plan/apply identities](https://developer.hashicorp.com/terraform/cloud-docs/dynamic-provider-credentials/azure-configuration).
- [HashiCorp: workspace-settings ownership/import](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/workspace_settings).


## Ownership Integration Update

The Phase 2 roots were confirmed unapplied and have now been reorganized by owner. Five existing workspaces gain marked, optional sections; eight separate roots live under the canonical platform/workload trees. No deployable `implementations/phase2/workspaces` wrappers remain. Patterns are retained and composed, not copied into roots.

Management owns alerts/workbooks and existing LAW/action groups/DCR/DCE. Connectivity owns network probes. DC/connector owners resolve VM IDs for AMA/inventory and verify assigned identities/sole association ownership. Policy owns audit rollout/exemptions/sandbox policy; a separate subscription FinOps root exposes financial controls only. Archive, security automation, HCP administration and external identity retain justified state boundaries.

Existing deployed input values and core resource/module addresses are preserved. The new `resource_tags` output on four older patterns is an additive release dependency, and the five extended roots explicitly require Terraform >=1.11.4. Existing provider selections are retained. Legacy external-DC entries were not removed; the separate external root now requires explicit existing-owner review. See [ENGINEERING-HANDOFF.md](ENGINEERING-HANDOFF.md) for exact files, release dependencies and safe adoption steps.
