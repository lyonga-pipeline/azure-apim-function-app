# Function App Module

This module is the Terraform 2.0 replacement pattern for the reviewed Function App configuration. It keeps the Function App resource complete enough for broad application use cases while avoiding the mixed lifecycle problems that caused teams to stitch custom variants together.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Operating system support | Focused on `azurerm_windows_function_app` only. | Supports both Windows and Linux through one module contract using `os_type`. |
| Input contract | Uses list-wrapped dynamic blocks and many `lookup()` calls, which makes singleton settings harder to validate and understand. | Uses typed `object(...)`, `map(object(...))`, and `null` for optional singleton blocks. This makes the consumer contract clearer and easier to validate. |
| Secure defaults | Passes many security-sensitive settings directly from variables, so every consumer must remember the right values. | Applies safer defaults such as `public_network_access_enabled = false`, `https_only = true`, disabled FTP/WebDeploy basic auth, HTTP/2 enabled, and TLS/SCM TLS `1.2` minimums. |
| Storage configuration | Allows storage account name, access key, managed identity, and Key Vault secret patterns without clear conflict rules. | Uses one `storage` object and preconditions to prevent invalid combinations, such as access key and managed identity at the same time. |
| Authentication | Uses legacy `auth_settings`. | Supports `auth_settings_v2`, including Entra ID, Microsoft, GitHub, Google, Facebook, Apple, custom OIDC, and token/login options. |
| Drift handling | Ignores important fields such as `app_settings`, `functions_extension_version`, `storage_account_access_key`, and `tags`, which can hide real drift. | Does not hide those fields by default. Changes remain visible in the Terraform plan unless a consuming root intentionally handles a specific exception. |
| Lifecycle separation | Mixes many concerns directly into the app resource and encourages a large all-in-one module. | Keeps only the core Function App lifecycle here. Separate modules own private endpoints, diagnostics, slots, RBAC, storage child objects, custom domains, and monitoring. |
| Reusability | Requires teams to pass many raw provider attributes and often add custom stitching around the module. | Provides a broad but predictable core module that can be composed with companion modules for app-specific needs. |

## Design Intent

The module owns the Function App itself:

- Windows or Linux Function App resource
- Service plan attachment
- Storage connection mode
- Managed identity
- App settings and connection strings
- Site configuration
- Runtime stack
- Backup configuration
- Sticky settings
- Built-in App Service authentication v2
- Secure resource-level defaults

The module intentionally does not own every surrounding platform concern. Those concerns have separate lifecycles and should be composed by the application root or pattern module.

Use companion modules for:

- `app-service-plan`
- `app-service-vnet-integration`
- `private-endpoint`
- `diagnostic-settings`
- `monitor-metric-alert`
- `function-app-slot`
- `role-assignments`
- `storage-account`
- `storage-container`
- `storage-queue`
- `storage-share`
- `key-vault`
- `key-vault-secret`

## Why This Matters

The goal is not to create a giant Function App module that magically creates every dependency. That would make lifecycle boundaries unclear and increase blast radius.

The goal is to create a complete and secure core module that application teams can reuse across many use cases, while still allowing separate teams or separate release cycles to manage networking, diagnostics, access, slots, storage objects, and secrets independently.

## Recommended Consumption Pattern

Application roots or workload pattern modules should resolve shared enterprise resources first, then pass explicit IDs and settings into this module.

```hcl
module "function_app" {
  source  = "app.terraform.io/compeer/compeer-function-app/azurerm"
  version = "2.0.0"

  name                = var.function_app.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  os_type             = "Windows"
  service_plan_id     = module.app_service_plan.id

  storage = {
    account_name          = module.storage_account.name
    uses_managed_identity = true
  }

  identity = {
    type         = "UserAssigned"
    identity_ids = [module.workload_identity.id]
  }

  site_config = {
    always_on              = true
    vnet_route_all_enabled = true
    application_stack = {
      dotnet_version              = "v8.0"
      use_dotnet_isolated_runtime = true
    }
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "dotnet-isolated"
  }

  tags = var.tags
}
```

Then compose separate lifecycle modules as needed:

```hcl
module "function_private_endpoint" {
  source  = "app.terraform.io/compeer/compeer-private-endpoint/azurerm"
  version = "2.0.0"

  name                = "${var.function_app.name}-pe"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection = {
    name                           = "${var.function_app.name}-psc"
    private_connection_resource_id = module.function_app.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group = {
    name                 = "default"
    private_dns_zone_ids = [var.azurewebsites_private_dns_zone_id]
  }

  tags = var.tags
}
```

## Summary

This module improves on the reviewed configuration by making the Function App reusable, secure by default, easier to validate, and easier to compose. It reduces custom stitching without collapsing every surrounding resource into a single mixed-lifecycle module.
