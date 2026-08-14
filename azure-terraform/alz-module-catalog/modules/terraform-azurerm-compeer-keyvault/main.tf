/*
# Azure Key Vault

This module creates an Azure Key Vault, a service that allows the secure storage
and management of secrets, keys, and certificates. In order to create assets for
this vault, use the terraform-azurerm-compeer-keyvault-assets module.
*/

locals {
  rbac_authorization_enabled = coalesce(var.rbac_authorization_enabled, var.enable_rbac_authorization, true)
}
