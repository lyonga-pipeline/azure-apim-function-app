# Platform Services

**PHASE2 NEW:** v5 PLT-03 and PLT-04. Private Compute Gallery/image definitions and approved Update Manager maintenance configurations/assignments.

## Ownership And Defaults

Reuse an existing RG and approved VM IDs. Empty galleries/patch_schedules maps preserve Phase 1. Existing galleries/schedules require state-owner extension or approved import, not same-name creation.

## Inputs And Outputs

| Input | Default | Purpose |
| --- | --- | --- |
| `resource_group_name` | `Required` | Existing services RG. |
| `location / tags` | `centralus / {}` | Explicit region and ownership. |
| `galleries` | `{}` | Private gallery plus Windows/Linux Gen2 image definitions. |
| `patch_schedules` | `{}` | Change approval, OS classifications, window, VM IDs and patch-authority readiness. |


The typed [variables.tf](variables.tf) defines every nested setting and guard; [outputs.tf](outputs.tf) exposes resource IDs by caller-stable key. Required context inputs do not create resources. Optional collections are opt-in. Use an existing approved resource group; this pattern does not own its lifecycle.

Use the independent [workspace root](../../implementations/platform-lz/workspaces/platform-services) and its `terraform.tfvars.example` for inert defaults. `approved-pilot.tfvars.example` demonstrates explicit reference values, not production approvals. Replace all synthetic values and review ownership before enabling any entry.

```hcl
module "phase2" {
  source = "../../patterns/terraform-azurerm-compeer-platform-services"
  resource_group_name = "platform-cus-prod-services-rg"
  # Supply required context and explicitly approved capability maps from tfvars.
  # In deployment roots, promote to a reviewed pinned registry version.
}
```

## Operational Contract

Image versions/build/scan/promotion are external Packer/Image Builder responsibilities. Patching requires approved change, compatible guest patch mode and exclusive SCCM/Update Manager authority. Never patch both DCs together.

[Phase 2 readiness and acceptance](../../implementations/phase2/RUNBOOKS.md) distinguishes mock coverage from live acceptance. No ARM management locks are added. Terraform >=1.11.4 is required; provider constraints are in [terraform.tf](terraform.tf).

## Validation

```sh
terraform init -backend=false
terraform validate
terraform test
```

Mocks test enabled/disabled composition and guards without Azure/HCP credentials. They do not prove live permissions, service quotas, network/data delivery or business compliance. Run real speculative plans and approved pilot checks before release.
