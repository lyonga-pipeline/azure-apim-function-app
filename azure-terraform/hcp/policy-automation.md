# HCP Policy Automation Model

This model automates OPA policy-set creation and scoping without attaching new blocking controls to current projects by accident. The policy code remains in VCS, and the attachment scope is driven by catalog data.

## Target Outcome

Cloud Enablement should be able to:

- publish OPA policies from `azure-terraform/policies/opa`,
- attach the policy set to net-new landing-zone projects first,
- keep the first rollout advisory,
- promote selected scopes to mandatory through pull request review,
- and later add current/legacy landing-zone projects by remediation wave.

The important design point is that policy enforcement should be changed by editing source-controlled catalog data, not by manually clicking through HCP Terraform.

## Source Files

| File | Purpose |
| --- | --- |
| `azure-terraform/policies/opa/policies.hcl` | Defines the OPA query and default enforcement level used by HCP Terraform. |
| `azure-terraform/policies/opa/policies/*.rego` | Rego rules evaluated against Terraform plans. |
| `azure-terraform/policies/opa/data/*.json` | Policy data such as allowed regions, required tags, and resource type lists. |
| `azure-terraform/policies/opa/tests/*.rego` | Unit tests for policy behavior. |
| `azure-terraform/hcp/workspace-catalog.example.yaml` | Workspace/project inventory and metadata model. |
| `azure-terraform/hcp/policy-scope-catalog.example.yaml` | Policy set scope, enforcement stage, and legacy rollout waves. |

## Recommended Automation Pattern

Use two layers:

1. **Policy code pipeline**

   Runs on pull requests that change `azure-terraform/policies/opa/**`.

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

2. **HCP control-plane automation**

   Runs from a controlled workspace or bootstrap job that has permission to manage HCP projects, workspaces, and policy sets.

   It creates or updates:

   - HCP policy set name,
   - VCS repository/policy directory,
   - project or workspace attachment list,
   - enforcement level,
   - exclusions, if needed.

## Terraform Automation Shape

Use the `tfe` provider for the final implementation when the HCP organization, OAuth client, project IDs, and workspace IDs are known.

Suggested root:

```text
azure-terraform/hcp/control-plane/
  main.tf
  variables.tf
  outputs.tf
  terraform.tfvars.example
```

The root should:

- read a real version of `policy-scope-catalog.example.yaml`,
- resolve HCP project names to project IDs,
- resolve workspace names to workspace IDs,
- create a VCS-backed OPA policy set,
- attach it only to the catalog-approved projects/workspaces.

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

  net_new_policy_set = local.policy_catalog.policy_sets.net_new_lz_opa
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
    identifier         = var.policy_repo_identifier
    oauth_token_id     = var.hcp_oauth_token_id
    branch             = var.policy_repo_branch
    ingress_submodules = false
  }

  policies_path = local.net_new_policy_set.vcs_policy_directory
  project_ids   = [for project in data.tfe_project.policy_projects : project.id]
  workspace_ids = [for workspace in data.tfe_workspace.policy_workspaces : workspace.id]
}
```

The exact `tfe_policy_set` attributes should be verified against the provider version used by Compeer before implementation. Keep this as the target shape until the HCP org details are available.

## API Or Script Alternative

If the `tfe` provider is not approved for the bootstrap phase, use a small script around the HCP Terraform Policy Sets API.

The script should:

1. read `policy-scope-catalog.yaml`,
2. resolve project/workspace names to IDs,
3. create or update the policy set,
4. set the VCS policy directory to `azure-terraform/policies/opa`,
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

Use dry-run output as pull request evidence.

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
