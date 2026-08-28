/*
# Azure Key Vault

This module creates an Azure Key Vault, a service that allows the secure storage
and management of secrets, keys, and certificates. In order to create assets for
this vault, use the terraform-azurerm-compeer-keyvault-assets module.
*/

locals {
  rbac_authorization_enabled = coalesce(var.rbac_authorization_enabled, var.enable_rbac_authorization, true)
  tenant_id                  = coalesce(var.tenant_id, data.azurerm_client_config.current.tenant_id)

  access_policies = merge(
    {
      for policy in var.access_policies :
      join("|", compact([
        policy.tenant_id,
        policy.object_id,
        try(policy.application_id, null)
      ])) => policy
    },
    var.access_policies_by_key
  )
}
