# Net-New Landing Zone IaC Work Items

All work items are intentionally sized at five points or less. Larger outcomes should be split across these items instead of tracked as one large ticket.

| ID | Work item | Output | Dependency | Estimate |
| --- | --- | --- | --- | ---: |
| LZ-001 | Create HCP project structure | `ce-lz-governance`, `ce-lz-platform`, `ce-lz-workloads`, `legacy-observe` | None | 3 |
| LZ-002 | Configure HCP workspace naming and VCS roots | Workspace catalog aligned to `hcp/workspace-catalog.example.yaml` | LZ-001 | 3 |
| LZ-003 | Configure HCP variable sets | Tenant, auth, standards, platform shared IDs | LZ-001 | 5 |
| LZ-004 | Attach OPA policy set in advisory mode | OPA checks report on net-new LZ workspaces only | LZ-001 | 3 |
| LZ-005 | Create global governance workspace | HCP workspace for `global-governance` root | LZ-002 | 2 |
| LZ-006 | Deploy management group scaffold | Management group IDs and subscription placements | LZ-005 | 5 |
| LZ-007 | Deploy Azure Policy baseline from global governance | Runtime guardrails scoped to net-new LZ management groups | LZ-006 | 5 |
| LZ-009 | Create platform management workspace | HCP workspace for `platform-management` | LZ-002 | 2 |
| LZ-010 | Deploy Log Analytics and action group | Shared observability outputs | LZ-009 | 3 |
| LZ-011 | Create platform connectivity workspace | HCP workspace for `platform-connectivity` | LZ-002 | 2 |
| LZ-012 | Deploy hub VNet and subnets | Hub VNet with typed subnet map outputs | LZ-011 | 5 |
| LZ-013 | Deploy NSG and route table attachments | NSG/route table associations outside VNet module | LZ-012 | 5 |
| LZ-014 | Deploy Private DNS zones and hub links | Private DNS outputs for app roots | LZ-012 | 5 |
| LZ-015 | Create platform identity workspace | HCP workspace for `platform-identity` | LZ-002 | 2 |
| LZ-016 | Deploy platform Key Vault and identities | RBAC-first vault and managed identities | LZ-010, LZ-015 | 5 |
| LZ-017 | Attach Key Vault private endpoint and diagnostics | Private endpoint and diagnostic setting evidence | LZ-014, LZ-016 | 5 |
| LZ-018 | Create workload spoke workspace | HCP workspace for first pilot workload spoke | LZ-002 | 2 |
| LZ-019 | Deploy pilot workload spoke network | Spoke VNet, subnet map outputs, NSG/route attachments | LZ-012, LZ-018 | 5 |
| LZ-020 | Link workload spoke to Private DNS | Spoke VNet DNS links to approved zones | LZ-014, LZ-019 | 3 |
| LZ-021 | Establish platform output contract | Documented output names and HCP variable-set mapping | LZ-010, LZ-014, LZ-019 | 3 |
| LZ-022 | Update consumer repo pattern | Typed app root inputs and explicit platform ID consumption | LZ-021 | 5 |
| LZ-023 | Enable HCP drift detection | Drift detection on net-new workspaces | LZ-001 | 3 |
| LZ-024 | Publish drift classification model | `operations/drift/classification.md` adopted by teams | None | 2 |
| LZ-025 | Publish drift and exception registers | Register templates and ownership fields | LZ-024 | 2 |
| LZ-026 | Run first policy impact review | Advisory policy findings categorized and assigned | LZ-004, LZ-007 | 3 |
| LZ-027 | Promote selected controls to Deny in non-prod | High-confidence controls block net-new non-prod violations | LZ-026 | 5 |
| LZ-028 | Define legacy extension criteria | Readiness checklist before applying controls to current projects | LZ-024, LZ-026 | 3 |
| LZ-029 | Create import/remediation backlog for pilot gaps | Gaps split into five-point or smaller work items | LZ-019, LZ-022 | 5 |
| LZ-030 | Capture landing-zone evidence package | Outputs, policy results, drift status, and decision record | LZ-010, LZ-014, LZ-017, LZ-022 | 3 |
