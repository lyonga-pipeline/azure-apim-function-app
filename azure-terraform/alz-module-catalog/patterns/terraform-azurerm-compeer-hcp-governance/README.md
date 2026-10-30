# HCP Drift Detection

**PHASE2 NEW: IAC-06 only.** Enable health assessments on explicitly approved existing HCP Terraform workspaces. Phase 3 team/workspace RBAC (IAC-04) and repo/workspace onboarding (IAC-11) are excluded, not disabled scaffolding.

## Ownership

Use this pattern only when no other state owns these workspace settings. Import/adopt the existing settings with an approved handoff; do not overlap properties managed by `tfe_workspace`. Empty `workspace_settings = {}` creates nothing and performs no workspace lookups. TFE credentials belong in the execution environment, never tfvars.

| Input | Default | Purpose |
| --- | --- | --- |
| `organization` | Required | Existing HCP organization. |
| `workspace_settings` | `{}` | Stable caller key to existing workspace name/ID, execution mode, agent pool, assessment intent and ownership approval. |
| `workspace_settings.*.remote_state_consumer_ids` | `null` | Optional assertion of existing consumers, not a permission override. |

The pattern reads actual workspace apply/sharing settings and carries them through unchanged. ID/name and execution mode must match the lookup. For agent execution, supply the **actual** agent pool ID; the workspace data source does not expose it, so verify it separately against HCP before adoption. Settings omitted as optional/computed remain provider/state-owned. Do not use this change to migrate execution mode, change auto-apply or broaden state access.

Output `settings_ids` returns adopted settings IDs by stable caller key. Full types and guards: [variables.tf](variables.tf).

## Example

Use the isolated [root](../../implementations/platform-lz/workspaces/platform-hcp-governance) and its inert `terraform.tfvars.example`. The synthetic `approved-pilot.tfvars.example` demonstrates an existing agent workspace, not authorization to adopt it.

```hcl
module "drift" {
  source = "../../patterns/terraform-azurerm-compeer-hcp-governance"
  organization = var.organization
  workspace_settings = var.workspace_settings
}
```

Publish and pin an approved registry release before real deployment. Confirm HCP entitlement, working dynamic credentials, a supported remote/agent execution mode and an initial successful run. Health assessments detect drift; they do not authorize automatic remediation. Panorama-owned guest configuration remains outside Terraform expectations.

## Validation

```sh
terraform init -backend=false
terraform validate
terraform test
```

Mock tests cover inert defaults, enabled adoption, preservation of apply/sharing settings and rejected context/consumer changes. Real-state speculative plans and an observed HCP assessment remain release gates. See [workspace settings ownership/import](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/workspace_settings) and the [Phase 2 runbooks](../../implementations/phase2/RUNBOOKS.md).
