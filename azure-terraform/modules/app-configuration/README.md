# App Configuration Module

Creates an Azure App Configuration store for centralized application settings and feature flags.

The baseline disables public network access and local auth by default, enables purge protection, and attaches a system-assigned managed identity.

This module is intended for HCP Terraform private registry publication as:

```hcl
source  = "app.terraform.io/<organization>/app-configuration/azurerm"
version = "1.1.0"
```

## Required Inputs

- `name`
- `resource_group_name`
- `location`

## Common Inputs

- `sku`
- `public_network_access_enabled`
- `local_auth_enabled`
- `tags`

## Outputs

- `id`
- `name`
- `endpoint`
- `identity`
