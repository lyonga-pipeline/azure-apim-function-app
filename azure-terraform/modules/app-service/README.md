# App Service Module

Creates an enterprise baseline Azure App Service deployment:

- App Service Plan
- Linux or Windows Web App
- Optional regional VNet integration
- HTTPS-only, public network disabled by default, and publishing basic auth disabled
- System-assigned managed identity by default

This module is intended for HCP Terraform private registry publication as:

```hcl
source  = "app.terraform.io/<organization>/app-service/azurerm"
version = "1.1.0"
```

## Required Inputs

- `name`
- `resource_group_name`
- `location`

## Common Inputs

- `public_network_access_enabled`
- `virtual_network_subnet_id`
- `service_plan_sku_name`
- `os_type`
- `app_settings`
- `tags`

## Outputs

- `id`
- `name`
- `default_hostname`
- `service_plan_id`
- `identity`
- `vnet_integration_id`
