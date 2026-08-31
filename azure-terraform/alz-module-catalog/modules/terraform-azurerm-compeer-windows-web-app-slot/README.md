# terraform-azurerm-compeer-windows-web-app-slot

A single deployment slot for an existing `azurerm_windows_web_app`. The parent app
is passed in by ID (`app_service_id`); this module does not create it.

Implemented fresh during the catalog hardening pass. Identical shape to
`terraform-azurerm-compeer-linux-web-app-slot` except `site_config.application_stack`
uses the Windows fields (`current_stack`, `dotnet_version`, `dotnet_core_version`,
`node_version`, `php_version`, `java_version`, `python`).

## Usage

```hcl
module "app_staging" {
  source         = "../terraform-azurerm-compeer-windows-web-app-slot"
  name           = "staging"
  app_service_id = module.app.id

  site_config = {
    always_on        = true
    application_stack = { current_stack = "dotnet", dotnet_version = "v8.0" }
  }

  tags = module.tags.tags
}
```

## Inputs / Outputs / Lifecycle

Same as `terraform-azurerm-compeer-linux-web-app-slot` (see that README). Outputs:
`id`, `name`, `default_hostname`, `identity_principal_id`. `name` and
`app_service_id` are ForceNew; everything else updates in place.

State exposure: none directly.

## Tests

`terraform test` (offline): secure defaults, site_config + identity wiring.
