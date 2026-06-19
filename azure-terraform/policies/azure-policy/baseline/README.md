# Azure Policy Baseline

This root deploys custom Azure Policy definitions and an initiative for the net-new landing-zone scope.

It intentionally receives management-group IDs as explicit inputs. It does not read legacy remote state or infer scope from environment names. HCP workspace variables, approved catalogs, or governance outputs should provide the IDs.

## First Rollout

Use `Audit` for the first pilot so policy impact is visible without disrupting deployment.

Promote selected controls to `Deny` only for net-new landing-zone scopes after exception handling and drift operations are operating.

## Example

```bash
terraform init
terraform plan -var-file=terraform.tfvars.example
```

Copy the example values into HCP workspace variables or a secure environment-specific variable file before applying.

