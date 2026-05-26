# Online Banking Consumer Repo

This directory models an application-owned Terraform repo that consumes Compeer Terraform 2.0 modules from the HCP Terraform private registry.

The root intentionally resolves environment-specific shared infrastructure before calling base modules. The modules receive explicit IDs for subnets, private DNS zones, Log Analytics, and action groups rather than discovering those values internally.

## Environment Layout

- `environments/np1`
- `environments/np2`
- `environments/np3`
- `environments/prod`

Each environment owns:

- `terraform.tfvars` for environment configuration
- `backend.hcl` for isolated state storage

## Module Versioning

Module sources are pinned in `main.tf` using HCP private registry syntax:

```hcl
source  = "app.terraform.io/compeer/compeer-function-app/azurerm"
version = "2.0.0"
```

If different environments must consume different module versions at the same time, use separate environment roots or a versioned workload pattern module. Terraform module `version` values are static HCL and cannot be safely varied through `tfvars`.

## Commands

```bash
terraform init -backend-config=environments/np1/backend.hcl
terraform plan -var-file=environments/np1/terraform.tfvars
terraform apply -var-file=environments/np1/terraform.tfvars
```

Use the same commands with `np2`, `np3`, or `prod` for the other environments.

## Secret Handling

The `key_vault_secrets` input is included to show the lifecycle boundary, but committed tfvars should not contain real secret values. Populate secrets through a secure pipeline variable source, HCP variable set, or a separate secrets workflow.
