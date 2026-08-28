# Compeer Platform ALZ Control-Plane Bootstrap

This project is adapted from the existing Compeer workload repo/workspace bootstrap pattern, but refactored for the **new platform Azure Landing Zone**.

## What was retained from the client implementation

- map-driven `for_each` scaling from tfvars
- reuse of the existing ADO project and HCP organization
- lookup/reuse of the existing HCP Azure DevOps OAuth connection
- lookup/reuse of existing HCP agent pools
- `tfe_workspace_settings` for execution mode / agent pool
- project / workspace variable-set associations
- VCS-backed HCP workspaces
- validation pipeline model based on the existing `IAC-Build-Validation.yml`

## What was intentionally changed for platform ALZ

- ADO and HCP are separate Terraform roots/states and should run from separate bootstrap HCP workspaces.
- The ADO project is **not** created or imported; the existing project is reused.
- Existing project-level branch policies are inherited, not duplicated.
- Repositories use **main only**. No `development` branch is created.
- Workspaces represent platform domains, not NP1/NP2/NP3/Prod environments.
- No `null_resource`, `timestamp()`, Azure CLI pipeline trigger, or PAT shell injection is used.
- Repository baseline files are managed declaratively with `azuredevops_git_repository_file`.
- A dedicated OPA repo and project-scoped HCP OPA policy set are included.
- Persistent control-plane objects use `prevent_destroy`.

## Layout

```text
compeer-alz-platform-bootstrap-v2/
├── modules/
│   ├── ado-repository/
│   └── hcp-workspace/
├── stacks/
│   ├── ado/      # alz-bootstrap-ado HCP workspace/state
│   └── hcp/      # alz-bootstrap-hcp HCP workspace/state
└── docs/
```

## Default deployment

The ADO stack creates two repos by default:

- `compeer-alz-platform-iac`
- `compeer-alz-policy-as-code`

The HCP stack creates a new HCP project and five minimum platform-domain workspaces:

- subscriptions
- connectivity
- management
- identity
- governance

All platform workspaces use `main` and a dedicated working directory under `platform/`.

## Scaling repositories

Add another entry to `stacks/ado/terraform.tfvars`:

```hcl
repositories = {
  platform = { ... }
  policy   = { ... }

  image_factory = {
    name             = "compeer-alz-image-factory"
    description      = "Platform image factory IaC"
    repository_type  = "terraform"
    create_pipeline  = true
    pipeline_name    = "ALZ Image Factory - Validation"
    seed_directories = ["image-factory"]
  }
}
```

Then declare any new HCP workspace in `stacks/hcp/terraform.tfvars` with `repository_key = "image_factory"`.

## Validation pipeline

For Terraform repos, the seeded YAML follows the client workload-bootstrap pattern: it references `Core/Pipelines`, runs the existing Orca IaC scan template, and runs the existing Terraform IaC scan template. It is adapted to `main` only.

For the OPA repo, a self-contained validation YAML formats and tests Rego. The HCP policy set is non-global and scoped to the new ALZ project.

## Bootstrap sequence

1. Create `alz-bootstrap-ado` and `alz-bootstrap-hcp` manually one time, both bound to this repo's `main` branch.
2. `alz-bootstrap-ado` working directory: `stacks/ado`.
3. `alz-bootstrap-hcp` working directory: `stacks/hcp`.
4. Apply ADO first.
5. Apply HCP second.

See `docs/bootstrap-runbook.md` for exact prerequisites and sequence.

## Important configuration before first apply

Update the example tfvars with the real:

- existing ADO project name
- existing HCP organization name
- existing HCP ADO OAuth client name
- existing HCP agent pool name(s)
- approved Terraform version
- Core/Pipelines ref/tag approved for production

The example preserves `1.9.5` and the `iac_scan_templates` ref because those are present in the supplied Compeer workload implementation. Pin to the production-approved central template release before rollout.
