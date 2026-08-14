# Platform Landing Zone Pattern Contract

This pattern records the platform component contract from the ALZ component workbook. It is intentionally no-resource: the platform landing zone is deployed by separate HCP workspaces because management groups, subscriptions, connectivity, identity, management, and workload spokes have different ownership and blast-radius boundaries.

Use this beside the workload `function-app` composition pattern to explain the distinction:

- Workload composition can safely create an application stack as one curated pattern.
- Platform composition should preserve separate lifecycle roots, then publish a contract showing how each root satisfies the required platform components.

## Spreadsheet Mapping

The contract maps workbook columns directly:

| Workbook column | Contract field |
| --- | --- |
| A `ID` | Component map key |
| B `Stack` | `stack` |
| C `Domain` | `domain` |
| D `Component` | `component` |
| G `Phase` | `phase` |
| H `Criticality` | `criticality` |

Each component also records the responsible workspace, pattern name, implementation status, and cost posture.

## Coverage Scope

The contract includes every workbook row. Phase 1 rows represent the MVP delivery baseline and must be implemented, externally governed, cost-disabled by design, or represented by an approved contract. Phase 2 rows are intentionally marked as deferred coverage so they are visible in code without deploying paid or unfinished services.

| Area | Examples covered |
| --- | --- |
| Governance | Management groups, subscription placement, Azure Policy, tagging, diagnostics policy, naming, locks, RBAC |
| Identity | Entra RBAC groups, custom roles, PIM, break-glass, workload identity federation, managed identity, AD DS and CA contracts |
| Connectivity | Hub VNet, reserved Palo Alto subnets, route tables, NSGs, Private DNS, ExpressRoute, DNS forwarding, workload spokes, Palo Alto egress/HA hooks |
| Security | Defender/SOC posture, platform Key Vault, encryption controls, privileged access contract |
| Observability and platform services | Log Analytics, diagnostics, activity logs, optional Recovery Services Vaults, optional platform storage accounts |
| IaC delivery | HCP Terraform, Azure DevOps pipelines, module registry/versioning, state/RBAC, security gates, subscription baseline, promotion workflow |
| Workload landing zone | Workload spoke and pilot Function App composition pattern |

## Status Values

| Status | Meaning |
| --- | --- |
| `implemented` | Terraform code has a deployable root/module path for the component. |
| `contract` | The repo captures the required contract, but deployment is intentionally external or pending design approval. |
| `external-governed` | The control is owned by a tenant, security, vendor, or on-prem process and is consumed by Terraform through IDs, groups, routes, or DNS inputs. |
| `cost-disabled` | The deployable hook exists, but is disabled in baseline tfvars to avoid cost until approved. |
| `advisory` | Documentation or policy warning only. Blocking and Critical components are not allowed to remain advisory-only. |
| `module-only` | A reusable module or AVM source exists, but the landing-zone root composition is not active yet. |
| `not-composed` | The workbook item is recorded in the contract, but no deployable root/module composition exists yet. |
| `documentation` | The item is an operating model, runbook, design, or testing artifact rather than Terraform-managed infrastructure. |

Run `terraform validate` in this directory after changing the contract. The validation will fail if a Phase 1 Blocking or Critical component is reduced to advisory-only or rootless coverage.

Use `implementation_overrides` only to reflect an approved change in ownership or implementation status. For example, an externally governed identity control can remain `external-governed`, and a paid control can remain `cost-disabled`, but a Blocking or Critical item should not be changed to `advisory`.
