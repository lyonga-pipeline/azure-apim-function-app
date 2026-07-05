# Online Banking Consumer Repo

This directory models an application-owned Terraform repo for `online-banking`. It consumes Compeer Terraform 2.0 modules from the HCP Terraform private registry using pinned module versions.

The important design choice is that each environment is its own Terraform root. That gives `np1`, `np2`, `np3`, and `prod` separate state, separate plans, separate module pins, and separate promotion control.

For the net-new landing-zone path, these roots consume explicit platform outputs from the shared HCP workspaces instead of discovering shared infrastructure internally. Subnet IDs, Private DNS zone IDs, Log Analytics IDs, and action group IDs are provided through approved HCP variable sets, workspace outputs, or an approved environment catalog.

The `clientsync` folder is the first Function App composition pilot. It consumes the local Terraform 2.0 Function App pattern so the team can validate create/existing dependency modes, private networking, diagnostics, RBAC, and app-setting drift behavior with a representative application.

The `legacy-app` folder is a training contrast. It intentionally uses one large all-in-one Function App module and intentionally violates selected OPA guardrails so teams can compare advisory policy findings against the cleaner ClientSync composition model.

## Environment Roots

Each environment directory contains the full Terraform root needed to plan and apply that environment:

| Environment | Root | Example module pin | Purpose |
| --- | --- | --- | --- |
| `np1` | `environments/np1` | `2.2.0` | Early validation of newer module releases. |
| `np2` | `environments/np2` | `2.1.0` | Controlled non-prod validation after `np1`. |
| `np3` | `environments/np3` | `2.0.1` | Production-like non-prod validation. |
| `prod` | `environments/prod` | `2.0.0` | Stable production baseline. |
| `clientsync sandbox` | `clientsync/environments/sandbox` | local pattern | Static sandbox for the Function App composition pilot. |
| `clientsync np1` | `clientsync/environments/np1` | local pattern | First non-prod promotion root for the ClientSync pilot. |
| `clientsync np2` | `clientsync/environments/np2` | local pattern | Controlled non-prod validation after `np1`. |
| `clientsync np3` | `clientsync/environments/np3` | local pattern | Production-like non-prod validation. |
| `clientsync prod` | `clientsync/environments/prod` | local pattern | Hardened production root for the ClientSync pilot. |
| `legacy-app np1` | `legacy-app/environments/np1` | local legacy module | Training root that demonstrates tight lifecycle coupling and intentional OPA advisory findings. |

Each root includes:

- `main.tf` with HCP registry module calls and static `version` pins.
- `locals.tf` for environment-local naming, tag merge behavior, and resolved shared IDs.
- `variables.tf` for the typed environment contract.
- `outputs.tf` for the app-facing resource outputs.
- `providers.tf` and `versions.tf` for provider configuration.
- `terraform.tfvars` for environment-specific values.

## Why Not One Shared Root

Terraform module `version` arguments are static HCL. They cannot be safely driven by `tfvars`.

That means a single shared `main.tf` would force all environments to consume the same module version as soon as the shared root changes. Separate roots avoid that issue and allow controlled promotion, for example:

- Test `compeer-function-app` `2.2.0` in `np1`.
- Keep `np2` on `2.1.0`.
- Keep `np3` on `2.0.1`.
- Keep `prod` on `2.0.0` until validation is complete.

## Module Consumption Pattern

The roots intentionally resolve environment-specific platform details before calling base modules. Base modules receive explicit IDs for subnets, private DNS zones, Log Analytics, and action groups rather than discovering those values internally.

```hcl
module "function_app" {
  source  = "app.terraform.io/compeer/compeer-function-app/azurerm"
  version = "2.2.0"

  name                = var.function_app.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  service_plan_id     = module.app_service_plan.id
  storage_account_name = module.storage_account.name

  identity = {
    type         = "UserAssigned"
    identity_ids = [module.identity.id]
  }

  app_settings = merge(var.function_app.app_settings, {
    APPINSIGHTS_INSTRUMENTATIONKEY = module.application_insights.instrumentation_key
  })

  tags = local.tags
}
```

This keeps Compeer standards in the modules while keeping environment and platform intelligence visible at the root.

The root contract is intentionally typed. The module catalog owns resource behavior; the app root owns application configuration and receives exact platform IDs from the landing-zone platform layer.

## Commands

Run Terraform from the target environment directory:

```bash
cd environments/np1
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Use the same pattern for `np2`, `np3`, or `prod`.

## Secret Handling

The `key_vault_secrets` input is included to show the lifecycle boundary, but committed tfvars should not contain real secret values. Populate secrets through a secure pipeline variable source, HCP variable set, or a separate secrets workflow.

## Net-New Landing Zone Inputs

For net-new landing-zone deployments, app roots should receive these values from approved platform outputs:

| Input | Source |
| --- | --- |
| `shared.log_analytics_workspace_id` | `platform-management` workspace output |
| `shared.action_group_id` | `platform-management` workspace output |
| `shared.subnet_ids.app_integration` | workload spoke or platform connectivity output |
| `shared.subnet_ids.private_endpoint` | workload spoke or platform connectivity output |
| `shared.private_dns_zone_ids` | `platform-connectivity` workspace output |

The app root passes these values into modules explicitly. Function App, Key Vault, Storage, and Private Endpoint modules should not infer subnet or DNS placement from environment names.

## Promotion Guidance

Promote by changing the module version in the next environment root after validation, not by changing a shared root for every environment at once. This gives us controlled rollout while preserving trunk-based IaC.
