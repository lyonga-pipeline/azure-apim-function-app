resource "azurerm_api_management_custom_domain" "this" {
  api_management_id = var.api_management_id

  dynamic "gateway" {
    for_each = var.gateway
    content {
      host_name                       = gateway.key
      certificate                     = try(gateway.value.certificate, null)
      certificate_password            = try(gateway.value.certificate_password, null)
      default_ssl_binding             = try(gateway.value.default_ssl_binding, null)
      key_vault_certificate_id        = try(gateway.value.key_vault_certificate_id, null)
      negotiate_client_certificate    = try(gateway.value.negotiate_client_certificate, null)
      ssl_keyvault_identity_client_id = try(gateway.value.ssl_keyvault_identity_client_id, null)
    }
  }

  dynamic "developer_portal" {
    for_each = var.developer_portal
    content {
      host_name                       = developer_portal.key
      certificate                     = try(developer_portal.value.certificate, null)
      certificate_password            = try(developer_portal.value.certificate_password, null)
      key_vault_certificate_id        = try(developer_portal.value.key_vault_certificate_id, null)
      negotiate_client_certificate    = try(developer_portal.value.negotiate_client_certificate, null)
      ssl_keyvault_identity_client_id = try(developer_portal.value.ssl_keyvault_identity_client_id, null)
    }
  }

  dynamic "management" {
    for_each = var.management
    content {
      host_name                       = management.key
      certificate                     = try(management.value.certificate, null)
      certificate_password            = try(management.value.certificate_password, null)
      key_vault_certificate_id        = try(management.value.key_vault_certificate_id, null)
      negotiate_client_certificate    = try(management.value.negotiate_client_certificate, null)
      ssl_keyvault_identity_client_id = try(management.value.ssl_keyvault_identity_client_id, null)
    }
  }

  dynamic "portal" {
    for_each = var.portal
    content {
      host_name                       = portal.key
      certificate                     = try(portal.value.certificate, null)
      certificate_password            = try(portal.value.certificate_password, null)
      key_vault_certificate_id        = try(portal.value.key_vault_certificate_id, null)
      negotiate_client_certificate    = try(portal.value.negotiate_client_certificate, null)
      ssl_keyvault_identity_client_id = try(portal.value.ssl_keyvault_identity_client_id, null)
    }
  }

  dynamic "scm" {
    for_each = var.scm
    content {
      host_name                       = scm.key
      certificate                     = try(scm.value.certificate, null)
      certificate_password            = try(scm.value.certificate_password, null)
      key_vault_certificate_id        = try(scm.value.key_vault_certificate_id, null)
      negotiate_client_certificate    = try(scm.value.negotiate_client_certificate, null)
      ssl_keyvault_identity_client_id = try(scm.value.ssl_keyvault_identity_client_id, null)
    }
  }
}
