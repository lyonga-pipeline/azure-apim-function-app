# Platform ALZ bootstrap runbook

## One-time bootstrap

Create one small bootstrap repository manually (or place this code in an existing trusted control-plane repo), then create **two HCP Terraform workspaces manually** outside the new ALZ project:

1. `alz-bootstrap-ado` -> working directory `stacks/ado`
2. `alz-bootstrap-hcp` -> working directory `stacks/hcp`

Bind both to `main`. This one-time manual step is intentional: the management workspaces should not bootstrap or mutate themselves.

## Credentials

`alz-bootstrap-ado` requires provider environment variables:

- `AZDO_ORG_SERVICE_URL`
- `AZDO_PERSONAL_ACCESS_TOKEN`

`alz-bootstrap-hcp` requires:

- `TFE_TOKEN`

Do not commit either token to tfvars.

## Apply sequence

1. Copy `stacks/ado/terraform.tfvars.example` to `terraform.tfvars`, adjust values, plan and apply through `alz-bootstrap-ado`.
2. Confirm the platform and policy repositories exist on `main`, the validation YAML has been seeded, and the ADO pipeline definitions point to it.
3. Copy `stacks/hcp/terraform.tfvars.example` to `terraform.tfvars`, replace the agent-pool placeholder, adjust names, then plan and apply through `alz-bootstrap-hcp`.
4. Confirm the new HCP project contains the five domain workspaces and that each workspace points to the correct `main` branch + working directory.
5. Confirm the OPA policy set is scoped to the new ALZ project only.
6. Populate approved variable-set values / dynamic credential IDs only after identity ownership is confirmed.

## Expected HCP workspace map

| Workspace | Repo | Branch | Working directory |
|---|---|---|---|
| alz-platform-subscriptions | compeer-alz-platform-iac | main | platform/subscriptions |
| alz-platform-connectivity | compeer-alz-platform-iac | main | platform/connectivity |
| alz-platform-management | compeer-alz-platform-iac | main | platform/management |
| alz-platform-identity | compeer-alz-platform-iac | main | platform/identity |
| alz-platform-governance | compeer-alz-platform-iac | main | platform/governance |

There is no `develop` branch and no environment-to-branch mapping for these platform workspaces.
