/**
## Creating Azure Key Vault Managed HSM
*/
resource "azurerm_key_vault_managed_hardware_security_module" "managed_hsm" {
  name                                      = var.name
  resource_group_name                       = var.resource_group_name
  location                                  = var.location
  admin_object_ids                          = var.admin_object_ids
  sku_name                                  = var.sku_name
  tenant_id                                 = var.tenant_id
  purge_protection_enabled                  = var.purge_protection_enabled
  soft_delete_retention_days                = var.soft_delete_retention_days
  public_network_access_enabled             = var.public_network_access_enabled
  security_domain_key_vault_certificate_ids = length(var.security_domain_key_vault_certificate_ids) > 0 ? var.security_domain_key_vault_certificate_ids : null
  security_domain_quorum                    = var.security_domain_quorum
  dynamic "network_acls" {
    for_each = var.network_acls != null ? [var.network_acls] : []
    content {
      default_action = network_acls.value.default_action
      bypass         = network_acls.value.bypass
    }
  }
  tags = var.tags

  lifecycle {
    precondition {
      condition     = (length(var.security_domain_key_vault_certificate_ids) > 0) == (var.security_domain_quorum != null)
      error_message = "Set security_domain_key_vault_certificate_ids and security_domain_quorum together, or set neither."
    }
  }
}
