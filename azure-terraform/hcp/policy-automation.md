# HCP Policy Automation Model

This model automates OPA policy-set creation and scoping without attaching new blocking controls to current projects by accident. The policy code will ultimately live in the Azure DevOps implementation repository, and the attachment scope is driven by catalog data in that same repo.

## Target Outcome

Cloud Enablement should be able to:

- publish OPA policies from `azure-terraform/policies/opa`,
- attach the policy set to net-new landing-zone projects first,
- keep the first rollout advisory,
- promote selected scopes to mandatory through pull request review,
- and later add current/legacy landing-zone projects by remediation wave.

The important design point is that policy enforcement should be changed by editing source-controlled catalog data and running an Azure DevOps pipeline, not by manually clicking through HCP Terraform.

## Source Files

| File | Purpose |
| --- | --- |
| `azure-terraform/policies/opa/policies.hcl` | Defines the OPA query and default enforcement level used by HCP Terraform. |
| `azure-terraform/policies/opa/policies/*.rego` | Rego rules evaluated against Terraform plans. |
| `azure-terraform/policies/opa/data/*.json` | Policy data such as allowed regions, required tags, and resource type lists. |
| `azure-terraform/policies/opa/tests/*.rego` | Unit tests for policy behavior. |
| `azure-terraform/hcp/workspace-catalog.example.yaml` | Workspace/project inventory and metadata model. |
| `azure-terraform/hcp/policy-scope-catalog.example.yaml` | Policy set scope, enforcement stage, and legacy rollout waves. |

In the final implementation, these files should be moved or mirrored into the Azure DevOps repository that owns the landing-zone IaC delivery path. The GitHub copy can remain useful for design review, but the active HCP policy set should point to the Azure DevOps repo/path that the team operates.

The example catalog includes a `source_control` block for the Azure DevOps repository:

```yaml
source_control:
  provider: azure_devops
  organization: compeer
  project: cloud-enablement
  repository: azure-landing-zone-iac
  branch: main
```

Use real ADO values in the implementation catalog. The custom pipeline or sync script should read these values when building the HCP VCS policy-set configuration.

## Recommended Automation Pattern

Use two layers:

1. **Azure DevOps policy code pipeline**

   Runs on pull requests in the Azure DevOps repo when changes touch `azure-terraform/policies/opa/**` or `azure-terraform/hcp/policy-scope-catalog.yaml`.

   Required checks:

   ```bash
   opa fmt -w azure-terraform/policies/opa/policies azure-terraform/policies/opa/tests
   opa test azure-terraform/policies/opa/policies azure-terraform/policies/opa/tests azure-terraform/policies/opa/data
   ```

   The pull request should show:

   - policy files changed,
   - test result,
   - expected blast radius,
   - proposed enforcement level,
   - exception/remediation impact.

2. **Azure DevOps HCP control-plane automation**

   Runs from a protected Azure DevOps pipeline stage or custom script job with permission to manage HCP projects, workspaces, and policy sets.

   It creates or updates:

   - HCP policy set name,
   - VCS repository/policy directory,
   - project or workspace attachment list,
   - enforcement level,
   - exclusions, if needed.

## Terraform Automation Shape

Use the `tfe` provider from an Azure DevOps pipeline for the final implementation when the HCP organization, Azure DevOps VCS/OAuth integration, project IDs, and workspace IDs are known.

Suggested root:

```text
azure-terraform/hcp/control-plane/
  main.tf
  variables.tf
  outputs.tf
  terraform.tfvars.example
```

The root should:

- read a real version of `policy-scope-catalog.yaml`,
- resolve HCP project names to project IDs,
- resolve workspace names to workspace IDs,
- create a VCS-backed OPA policy set that points to the Azure DevOps repo and policy directory,
- attach it only to the catalog-approved projects/workspaces.

`policy_scope_catalog_path` is the path to the YAML scope catalog, not the Rego policy directory itself. The YAML catalog then contains `vcs_policy_directory`, which points to the actual OPA policy folder.

Example:

```hcl
variable "policy_scope_catalog_path" {
  type        = string
  description = "Path to the YAML catalog that declares HCP policy sets, ADO policy directory, enforcement level, and target projects/workspaces."
  default     = "../policy-scope-catalog.yaml"
}

locals {
  policy_catalog = yamldecode(file(var.policy_scope_catalog_path))

  # Reads source_control from the YAML catalog. The custom pipeline/script uses
  # these values to identify the Azure DevOps repo and branch that contain the policies.
  ado_source_control = local.policy_catalog.source_control

  # Reads policy_sets.net_new_lz_opa from the YAML catalog.
  net_new_policy_set = local.policy_catalog.policy_sets.net_new_lz_opa

  # This is the actual policy directory HCP should load from the Azure DevOps repo.
  opa_policy_directory = local.net_new_policy_set.vcs_policy_directory
}
```

With the current example catalog:

```yaml
source_control:
  provider: azure_devops
  organization: compeer
  project: cloud-enablement
  repository: azure-landing-zone-iac
  branch: main

policy_sets:
  net_new_lz_opa:
    vcs_policy_directory: azure-terraform/policies/opa
    enforcement_level: advisory
    project_scopes:
      - ce-lz-governance
      - ce-lz-platform
      - ce-lz-workloads
```

The flow is:

1. `policy_scope_catalog_path` reads `azure-terraform/hcp/policy-scope-catalog.yaml`.
2. Terraform or the custom script reads the Azure DevOps repo details from `source_control`.
3. Terraform or the custom script selects `policy_sets.net_new_lz_opa`.
4. `vcs_policy_directory` resolves to `azure-terraform/policies/opa`.
5. HCP Terraform loads `policies.hcl`, Rego, and data from that directory in the Azure DevOps repo.
6. `project_scopes` and `workspace_scopes` define where the policy set is attached.

Illustrative Terraform shape:

```hcl
terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.60"
    }
  }
}

provider "tfe" {
  organization = var.hcp_organization
}

locals {
  policy_catalog = yamldecode(file(var.policy_scope_catalog_path))
  ado_source_control = local.policy_catalog.source_control

  net_new_policy_set = local.policy_catalog.policy_sets.net_new_lz_opa

  opa_policy_directory = local.net_new_policy_set.vcs_policy_directory
  policy_repo_branch = try(local.ado_source_control.branch, var.policy_repo_branch)
}

data "tfe_project" "policy_projects" {
  for_each     = toset(local.net_new_policy_set.project_scopes)
  organization = var.hcp_organization
  name         = each.key
}

data "tfe_workspace" "policy_workspaces" {
  for_each     = toset(local.net_new_policy_set.workspace_scopes)
  organization = var.hcp_organization
  name         = each.key
}

resource "tfe_policy_set" "net_new_lz_opa" {
  name         = "compeer-net-new-lz-opa"
  description  = local.net_new_policy_set.description
  organization = var.hcp_organization
  kind         = "opa"

  vcs_repo {
    # For Azure DevOps, confirm the exact identifier format with the HCP VCS provider setup.
    # This commonly comes from catalog source_control values or an explicit pipeline variable.
    identifier         = var.policy_repo_identifier
    oauth_token_id     = var.hcp_oauth_token_id
    branch             = local.policy_repo_branch
    ingress_submodules = false
  }

  # This value comes from policy_scope_catalog_path -> policy_sets.net_new_lz_opa.vcs_policy_directory.
  policies_path = local.opa_policy_directory
  project_ids   = [for project in data.tfe_project.policy_projects : project.id]
  workspace_ids = [for workspace in data.tfe_workspace.policy_workspaces : workspace.id]
}
```

The exact `tfe_policy_set` attributes should be verified against the provider version used by Compeer before implementation. Keep this as the target shape until the HCP org and Azure DevOps VCS integration details are available.

## Azure DevOps Pipeline Shape

The ADO pipeline should have two separate stages: validate policy code, then sync HCP policy attachment.

Illustrative pipeline:

```yaml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - azure-terraform/policies/opa/**
      - azure-terraform/hcp/policy-scope-catalog.yaml

pr:
  branches:
    include:
      - main
  paths:
    include:
      - azure-terraform/policies/opa/**
      - azure-terraform/hcp/policy-scope-catalog.yaml

stages:
  - stage: ValidateOpa
    displayName: Validate OPA policies
    jobs:
      - job: opa_test
        steps:
          - checkout: self
          - script: |
              opa fmt -w azure-terraform/policies/opa/policies azure-terraform/policies/opa/tests
              opa test azure-terraform/policies/opa/policies azure-terraform/policies/opa/tests azure-terraform/policies/opa/data
            displayName: Run OPA tests

  - stage: SyncHcpPolicySet
    displayName: Sync HCP policy set
    dependsOn: ValidateOpa
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - job: sync_policy
        steps:
          - checkout: self
          - script: |
              ./scripts/sync-hcp-policy-set.sh \
                --org "$(HCP_TERRAFORM_ORG)" \
                --catalog azure-terraform/hcp/policy-scope-catalog.yaml \
                --policy-set net_new_lz_opa \
                --apply
            env:
              HCP_TOKEN: $(HCP_TOKEN)
            displayName: Sync policy set from catalog
```

The same shape works if the second stage runs Terraform instead of a shell script:

```bash
terraform -chdir=azure-terraform/hcp/control-plane init
terraform -chdir=azure-terraform/hcp/control-plane plan \
  -var="policy_scope_catalog_path=../policy-scope-catalog.yaml"
terraform -chdir=azure-terraform/hcp/control-plane apply \
  -var="policy_scope_catalog_path=../policy-scope-catalog.yaml"
```

For pull requests, run only validation and an HCP policy-sync dry run. For merges to `main`, run the apply/sync step from a protected environment with approvals.

## API Or Script Alternative

If the `tfe` provider is not approved for the bootstrap phase, use a small Azure DevOps pipeline script around the HCP Terraform Policy Sets API.

The script should:

1. read `policy-scope-catalog.yaml` from the Azure DevOps repo checkout,
2. resolve project/workspace names to IDs,
3. create or update the policy set,
4. set the VCS policy directory from `policy_sets.<name>.vcs_policy_directory`,
5. attach the policy set to the resolved project/workspace IDs,
6. emit a summary showing added, removed, and unchanged scopes.

Minimum command contract:

```bash
./scripts/sync-hcp-policy-set.sh \
  --org compeer \
  --catalog azure-terraform/hcp/policy-scope-catalog.yaml \
  --policy-set net_new_lz_opa \
  --dry-run
```

Then:

```bash
./scripts/sync-hcp-policy-set.sh \
  --org compeer \
  --catalog azure-terraform/hcp/policy-scope-catalog.yaml \
  --policy-set net_new_lz_opa \
  --apply
```

Use dry-run output as pull request evidence. The dry run should show the policy directory pulled from the catalog, the HCP policy set name, the resolved project/workspace IDs, and whether enforcement is `advisory` or `mandatory`.

## How Extension To Old LZ Works

Do not change Rego first. Change the scope catalog.

Recommended legacy flow:

1. Add legacy/current workspaces to `legacy-observe` or a named advisory wave.
2. Keep enforcement `advisory`.
3. Run policy impact review for at least one planning cycle.
4. Create remediation tickets for failing controls.
5. Record exceptions with owner, reason, expiry, severity, and remediation path.
6. Move remediated non-prod workspaces into a selected mandatory wave.
7. Move production only after non-prod has clean policy history and an approved exception path.

Example catalog change:

```yaml
legacy_policy_waves:
  wave_1_ready_nonprod:
    enforcement_level: advisory
    workspaces:
      - legacy-claims-np1
      - legacy-payments-np2
```

Later promotion:

```yaml
legacy_policy_waves:
  wave_2_selected_mandatory:
    enforcement_level: mandatory
    workspaces:
      - legacy-claims-np1
```

That promotion should require pull request approval from Cloud Enablement, Engineering Enablement, Security/Governance, and the application/platform owner.

## Enforcement Promotion Rules

Use these gates before moving any scope from `advisory` to `mandatory`:

- workspace owner is recorded,
- state owner is recorded,
- remediation backlog exists for current failures,
- exception register exists,
- production impact is reviewed,
- rollback path is known,
- at least one clean advisory plan has run,
- OPA tests pass,
- policy result evidence is linked to the change.

OPA in HCP Terraform supports `advisory` and `mandatory`. Use `advisory` for discovery and `mandatory` only where the team has accepted that failed policy checks can stop the run.

## Why Automate If Changes Are Infrequent

Policy-set changes may happen monthly or quarterly, but manual scope changes are high-risk because one wrong project attachment can block unrelated delivery. Automation gives:

- clear diff of which projects/workspaces are gaining policy,
- repeatable recreation during DR or org rebuild,
- peer review before enforcement changes,
- evidence for audit,
- safer legacy onboarding by wave,
- no hidden UI drift between documentation and HCP.

## References

- HCP Terraform OPA policy sets with VCS: https://developer.hashicorp.com/terraform/cloud-docs/workspaces/policy-enforcement/manage-policy-sets/opa-vcs
- HCP Terraform policy enforcement levels and publishing workflows: https://developer.hashicorp.com/terraform/cloud-docs/workspaces/policy-enforcement/manage-policy-sets
