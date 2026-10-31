# Phase 2 Landing Zone Delivery

This directory contains the **Phase 2 delivery index, engineering handoff, coverage and acceptance evidence**. It is not a separate deployment control plane. Deployable roots are under their platform/workload owners.

Source: v5 **Phase 2 Deployment Order**, cross-checked against **Component List**. All 49 source activity rows remain accounted for: 45 Phase 2 activities and four explicit Phase 3 exclusions. Four additional Phase 2 components are mapped from Component List. [coverage.json](coverage.json) records source rows, reusable code and canonical implementation paths.

## Where Engineering Makes Changes

Start with [ENGINEERING-HANDOFF.md](ENGINEERING-HANDOFF.md). It lists exact files, ownership boundaries, release prerequisites and adoption steps. [implementation-map.json](implementation-map.json) is the machine-readable index used by tests.

| Existing workspace | Phase 2 additions |
| --- | --- |
| `platform-management` | Alerts and workbooks reuse its existing LAW, RG, action group and tags. DCR/DCE definitions stay in existing management inputs. |
| `platform-connectivity` | Connection Monitor probes remain network-owned. Existing Bastion/Watcher/flow-log controls are reused. |
| `platform-directory-services` | Windows AMA/inventory configured by DC logical key; VM IDs come from its own module outputs. |
| `platform-cloudflare-connectors` | Linux AMA/inventory configured by connector key; no arbitrary external VM targets. |
| `platform-policy` | Audit rollout, expiring exemptions and sandbox expiry. No FinOps resources. |

Each of these roots has a visible **PHASE 2 CHANGES** section in `main.tf`, typed `phase2_variables.tf`, `phase2_outputs.tf`, a non-auto-loaded `phase2.tfvars.example` and real-child mock composition tests. Existing `terraform.tfvars` values and core module addresses are retained; its new footer points engineering to the opt-in inputs.

## Separate Canonical Roots

| Root | Parent directory | Boundary |
| --- | --- | --- |
| `platform-log-archive` | `implementations/platform-lz/workspaces` | Long-lived immutable retention/export/audit lifecycle. |
| `platform-finops` | Same platform directory | One target subscription; budgets/anomalies/exports, never MG policy. |
| `platform-security-automation` | Same platform directory | Privileged event/rotation delivery. |
| `platform-hcp-governance` | Same platform directory | Existing HCP workspace health assessments only. |
| `platform-services` | Same platform directory | Compute-owner private image gallery and approved patch schedules. |
| `platform-identity-external` | Same platform directory | Dedicated external forest/subscription/backup owner, with explicit legacy-owner check. |
| `workload-external-apps-prod` | `implementations/workload-lz/workspaces` | Independently promoted application/environment. |
| `workload-sandbox` | Same workload directory | Isolated sandbox and explicit expiry; same inspected baseline. |

The former `implementations/phase2/workspaces` roots were confirmed **unapplied**. They were moved into these canonical locations or absorbed into existing owners; redundant deployable wrappers were removed. No state move, import or apply was performed. Older and additional reusable patterns remain available.

## Compatibility And Rollout

- New optional inputs default empty/null/false. Do not migrate deployed resources solely to relabel them Phase 2.
- Reuse central LAW/DNS/action groups/DCR/DCE and existing VM identities. Verify sole ownership of extensions, associations, alerts, budgets, pricing, exemptions and HCP settings.
- Publish reviewed releases of the four existing patterns' additive `resource_tags` output and new capabilities before switching Compeer roots to exact HCP registry versions. Local catalog sources are for integration testing, not independently pinned production deployment.
- Use Terraform >=1.11.4, <2 and retain existing provider lockfiles. Production roots need their own release pin, state, scoped identity, main-branch working directory, trigger paths and approvals.
- New attachments centrally own both directions; existing split-owner identity peering remains a documented exception. Production/non-production grouping follows [PEERING-STANDARD.md](../platform-lz/PEERING-STANDARD.md); the new AzAPI batch/two disabled roots retain the old single-pair APIs. Publish/pin and complete protected gate/OIDC/live adoption before rollout. CSP onboarding remains governance-owned; vending stays disabled. No new ARM management locks or Phase 3 code is introduced.
- Replace synthetic inputs/approval references, review a real-state plan and reject unintended deletes/replacements. Enable one approved pilot at a time.

Archive selected-network ingress permits Azure Monitor's trusted service under a reviewed exception; it is not anonymous public access. Unlocked immutability is only a pilot; irreversible locking/retention requires GRC approval.

See [TESTING.md](TESTING.md), [REVIEW.md](REVIEW.md) and [RUNBOOKS.md](RUNBOOKS.md). Mock/structural tests do not establish live Azure/HCP acceptance, carrier/vendor connectivity, query validity, retention, replication or recovery. [ON-HOLD.md](ON-HOLD.md) tracks the explicit Phase 3 exclusions and unresolved decisions.

## Activity Index

| Step | Activity | Implementation status |
| --- | --- | --- |
| 1.2 | SolarWinds coexistence | [MANUAL](../../implementations/phase2/RUNBOOKS.md) |
| 1.3 | SCCM reachability | [MANUAL](../../implementations/phase2/RUNBOOKS.md) |
| 1.4 | State management and workspace RBAC | [EXCLUDED_PHASE3](ON-HOLD.md) |
| 1.5 | ExpressRoute Gateway | [EXISTING](../../patterns/terraform-azurerm-compeer-platform-hybrid-connectivity/main.tf) |
| 1.6 | Circuit connection and routing validation | [EXISTING_MANUAL](../../patterns/terraform-azurerm-compeer-platform-hybrid-connectivity/main.tf) |
| 1.7 | NCUS-to-CUS cross-environment path | [MANUAL](../../implementations/phase2/RUNBOOKS.md) |
| 2.1 | Baseline alerts and action groups | [NEW_EXTENDS_EXISTING](../../patterns/terraform-azurerm-compeer-platform-observability/main.tf) |
| 2.2 | Azure Monitor Agent and data collection rules | [NEW_EXTENDS_EXISTING](../../patterns/terraform-azurerm-compeer-platform-observability/main.tf) |
| 2.3 | Log archive storage account | [NEW](../../patterns/terraform-azurerm-compeer-log-archive/main.tf) |
| 2.4 | Application Insights | [EXISTING](../../patterns/terraform-azurerm-compeer-spoke-landing-zone/main.tf) |
| 2.5 | Palo log pipeline to Sentinel | [EXTERNAL](../../implementations/phase2/RUNBOOKS.md) |
| 2.7 | Defender plans - workload specific | [EXISTING](../../patterns/terraform-azurerm-compeer-platform-policy/main.tf) |
| 2.8 | Workbooks and dashboards | [NEW](../../patterns/terraform-azurerm-compeer-platform-observability/main.tf) |
| 2.9 | ITSM / ticketing integration | [NEW_PENDING_DESIGN](../../modules/terraform-azurerm-compeer-actiongroup/actiongroup.tf) |
| 3.1 | Customer-managed keys and rotation | [EXISTING](../../modules/terraform-azurerm-compeer-key-vault-key/main.tf) |
| 3.2 | Secrets rotation automation | [NEW_MANUAL](../../patterns/terraform-azurerm-compeer-security-automation/main.tf) |
| 3.3 | Just-in-time VM access | [MANUAL](../../implementations/phase2/RUNBOOKS.md) |
| 3.4 | Regulatory compliance initiative | [NEW_EXTENDS_EXISTING](../../patterns/terraform-azurerm-compeer-phase2-governance/main.tf) |
| 3.5 | Compliance evidence and audit reporting | [NEW_MANUAL](../../implementations/phase2/RUNBOOKS.md) |
| 3.6 | Policy exemption workflow | [NEW_EXTENDS_EXISTING](../../patterns/terraform-azurerm-compeer-phase2-governance/main.tf) |
| 3.7 | NSG flow logs and traffic analytics | [EXISTING](../../patterns/terraform-azurerm-compeer-platform-connectivity/main.tf) |
| 3.8 | Network Watcher and connection monitors | [NEW_PENDING_DESIGN](../../patterns/terraform-azurerm-compeer-platform-observability/main.tf) |
| 3.9 | DDoS Network Protection | [EXISTING](../../patterns/terraform-azurerm-compeer-platform-connectivity/main.tf) |
| 4.1 | Cloudflare connector subnet | [EXISTING](../../patterns/terraform-azurerm-compeer-platform-connectivity/main.tf) |
| 4.2 | External-apps spoke VNet template | [NEW_EXTENDS_EXISTING](../../implementations/workload-lz/workspaces/workload-external-apps-prod/main.tf) |
| 4.3 | Cloudflare Tunnel connectors | [EXISTING_MANUAL](../../patterns/terraform-azurerm-compeer-cloudflare-connectors/main.tf) |
| 4.4 | Cloudflare Zero Trust configuration | [EXISTING_EXTERNAL](../../patterns/terraform-cloudflare-compeer-edge-baseline/main.tf) |
| 4.5 | Application Gateway + WAF (failover path) | [EXCLUDED_PHASE3](ON-HOLD.md) |
| 4.6 | Ingress failover design and runbook | [EXCLUDED_PHASE3](ON-HOLD.md) |
| 5.1 | PartnerSubnet | [EXISTING_MANUAL](../../patterns/terraform-azurerm-compeer-palo-alto-hub/main.tf) |
| 5.2 | Internal Load Balancer - Partner | [EXISTING_MANUAL](../../patterns/terraform-azurerm-compeer-palo-alto-hub/main.tf) |
| 5.3 | Sunstream partner hub peering | [EXISTING_MANUAL](../platform-lz/workspaces/platform-network-peering-prod/README.md); approved same-tenant v3 producer required |
| 6.1 | External identity subscription, VNet and RG | [NEW_EXTENDS_EXISTING](../../implementations/platform-lz/workspaces/platform-identity-external/main.tf) |
| 6.2 | External identity VNet to hub peering | [EXISTING](../platform-lz/workspaces/platform-network-peering-prod/README.md); [identity v3 producer](../platform-lz/workspaces/platform-identity-external/README.md) |
| 6.3 | External forest domain controllers | [NEW_EXTENDS_EXISTING_MANUAL](../../implementations/platform-lz/workspaces/platform-identity-external/main.tf) |
| 6.4 | External identity backup vault | [NEW_EXTENDS_EXISTING](../../implementations/platform-lz/workspaces/platform-identity-external/main.tf) |
| 7.1 | ExpressRoute Metro Resiliency (second MSEE) | [EXISTING_MANUAL](../../patterns/terraform-azurerm-compeer-platform-hybrid-connectivity/main.tf) |
| 8.1 | Compute gallery and golden images | [NEW_MANUAL](../../patterns/terraform-azurerm-compeer-platform-services/main.tf) |
| 8.2 | Azure Update Manager | [NEW_PENDING_DESIGN](../../patterns/terraform-azurerm-compeer-platform-services/main.tf) |
| 8.3 | Change tracking and inventory | [NEW_PENDING_DESIGN](../../patterns/terraform-azurerm-compeer-platform-observability/main.tf) |
| 9.1 | Subscription vending automation | [EXISTING_PENDING_APPROVAL](../../patterns/terraform-azurerm-compeer-subscription-vending/main.tf) |
| 9.2 | Budgets and cost alerts | [NEW_EXTENDS_EXISTING](../../patterns/terraform-azurerm-compeer-phase2-governance/main.tf) |
| 9.3 | Drift detection | [NEW_PENDING_DESIGN](../../patterns/terraform-azurerm-compeer-hcp-governance/main.tf) |
| 9.4 | Repo-seed workload onboarding | [EXCLUDED_PHASE3](ON-HOLD.md) |
| 10.1 | Sandbox spoke VNet | [NEW_EXTENDS_EXISTING](../../implementations/workload-lz/workspaces/workload-sandbox/main.tf) |
| 10.2 | Sandbox peering and routing | [EXISTING](../platform-lz/workspaces/platform-network-peering-nonprod/README.md); blueprint retains UDR ownership |
| 10.3 | Sandbox policy scope and guardrails | [NEW_EXTENDS_EXISTING](../../patterns/terraform-azurerm-compeer-phase2-governance/main.tf) |
| 10.4 | Sandbox subscription placement | [EXISTING](../../patterns/terraform-azurerm-compeer-subscription-onboarding/main.tf) |
| 11.1 | DR Framework, strategy and guidelines | [NEW_DESIGN](../../implementations/phase2/DR-FRAMEWORK.md) |

## Additional Phase 2 Components

These Phase 2 entries are absent from the deployment-order sheet; they are not silently omitted from this delivery.

| Component | Existing owner | Coverage / release gate |
| --- | --- | --- |
| GOV-01 management groups | `global-governance` / platform-governance | Hierarchy-map regression without Phase 3 expansion. Preserve existing dormant MGs; never remove deployed branches just to narrow this delivery. |
| IAM-05 OIDC CI/CD | `workload-identity` | Exact issuer/subject/audience federation and scoped roles; tests separate prod/nonprod and plan/apply identities. Review actual trust tokens and role scope. |
| SEC-04 Sentinel content | `sentinel-content` | Analytics, workbooks, automation, connectors and source guards already exist. SOC validates ingestion, detection quality and incident/playbook delivery. |
| SEC-12 privileged access | `platform-connectivity` | Central Bastion supports existing PIP and central audit routing; enabled/disabled composition is tested. Approve subnet/NSG, PIP policy exception and access model before deployment. |

## References

- [Azure Monitor data export: region, trusted services, supported tables and immutable destinations](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/logs-data-export).
- [VNet flow logs and NSG flow-log retirement](https://learn.microsoft.com/en-us/azure/network-watcher/nsg-flow-logs-overview).
- [Azure Update Manager scheduled patching prerequisites](https://learn.microsoft.com/en-us/azure/update-manager/scheduled-patching).
- [Key Vault secret rotation requires a handler and backing-service update](https://learn.microsoft.com/en-us/azure/key-vault/secrets/tutorial-rotation).
- [Secure action-group webhooks](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups).
- [HCP workspace settings ownership and import](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/workspace_settings).
