# Phase 2 Governance And FinOps

**PHASE2 NEW:** v5 GOV-08, GOV-11, GOV-13 and GOV-14. Audit-first initiative assignments, narrow expiring exemptions, separately owned subscription budgets/anomalies/cost exports and sandbox expiry presence policy.

## Ownership And Defaults

Reuse existing policy definitions, CSP subscription and approved export container. Empty maps/null sandbox scope create nothing. Extend existing assignment/budget owners rather than duplicate their objects. No Modify tag policy or spoke-owned budget is introduced.

## Inputs And Outputs

| Input | Default | Purpose |
| --- | --- | --- |
| `subscription_id` | `Required` | Existing CSP subscription UUID for FinOps resources. |
| `audit_initiatives` | `{}` | Verified initiative ID, MG scope, optional JSON parameters and approval. |
| `exemptions` | `{}` | Resource/RG/subscription scope, assignment, approver, ticket and future expiry. |
| `budgets` | `{}` | Positive approved currency amount, dates and notification routes. |
| `cost_exports / cost_anomalies` | `{} / {}` | Existing ARM container destination/access confirmation and anomaly recipients. |
| `sandbox_scope` | `null` | Approved MG, initial Audit effect and expiry-tag policy name. |
| `location` | `centralus` | Reserved context; governance/cost resources are not region-scoped. |


The typed [variables.tf](variables.tf) defines every nested setting and guard; [outputs.tf](outputs.tf) exposes resource IDs by caller-stable key. Required context inputs do not create resources. Optional collections are opt-in. Use an existing approved resource group; this pattern does not own its lifecycle.

Use the existing policy [workspace root](../../implementations/platform-lz/workspaces/platform-policy) and its `phase2.tfvars.example` for policy inputs. The separate [FinOps root](../../implementations/platform-lz/workspaces/platform-finops) passes only budgets/cost controls. Shared pattern code does not imply shared state or credentials. See the [engineering handoff](../../implementations/phase2/ENGINEERING-HANDOFF.md); examples are not production approvals. Replace all synthetic values and review ownership before enabling any entry.

```hcl
module "phase2" {
  source = "../../patterns/terraform-azurerm-compeer-phase2-governance"
  subscription_id = "11111111-1111-1111-1111-111111111111"
  # Supply required context and explicitly approved capability maps from tfvars.
  # In deployment roots, promote to a reviewed pinned registry version.
}
```

## Operational Contract

Verify actual initiative IDs/versions/applicability with GRC. DoNotEnforce prevents blocking/mutation; set supported effect parameters to Audit. Exemptions require approver/ticket/expiry; renewal is explicit. Budgets notify, not cap spend. Cost exports require actual supported billing/RBAC/firewall access. Expiry tags do not auto-delete resources.

[Phase 2 readiness and acceptance](../../implementations/phase2/RUNBOOKS.md) distinguishes mock coverage from live acceptance. No ARM management locks are added. Terraform >=1.11.4 is required; provider constraints are in [terraform.tf](terraform.tf).

## Validation

```sh
terraform init -backend=false
terraform validate
terraform test
```

Mocks test enabled/disabled composition and guards without Azure/HCP credentials. They do not prove live permissions, service quotas, network/data delivery or business compliance. Run real speculative plans and approved pilot checks before release.
