resource "azurerm_api_management" "apim" {
  name                          = var.apim_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  publisher_name                = var.publisher_name
  publisher_email               = var.publisher_email
  sku_name                      = var.sku_name
  gateway_disabled              = length(var.additional_location) > 0 ? var.gateway_disabled : null
  min_api_version               = var.min_api_version
  zones                         = var.zones
  notification_sender_email     = var.notification_sender_email
  public_ip_address_id          = var.public_ip_address_id
  public_network_access_enabled = var.public_network_access_enabled
  virtual_network_type          = var.virtual_network_type
  tags                          = var.tags
  dynamic "additional_location" {
    for_each = var.additional_location
    content {
      location             = additional_location.value.location
      capacity             = lookup(additional_location.value, "capacity", null)
      zones                = lookup(additional_location.value, "zones", null)
      public_ip_address_id = lookup(additional_location.value, "public_ip_address_id", null)
      gateway_disabled     = lookup(additional_location.value, "gateway_disabled", null)
      dynamic "virtual_network_configuration" {
        for_each = additional_location.value.virtual_network_configuration != null ? [additional_location.value.virtual_network_configuration] : []
        content {
          subnet_id = virtual_network_configuration.value.subnet_id
        }
      }
    }
  }
  dynamic "certificate" {
    for_each = var.certificate
    content {
      encoded_certificate  = certificate.value.encoded_certificate
      store_name           = certificate.value.store_name
      certificate_password = lookup(certificate.value, "certificate_password", null)
    }
  }
  dynamic "delegation" {
    for_each = var.delegation != null ? [var.delegation] : []
    content {
      subscriptions_enabled     = lookup(delegation.value, "subscriptions_enabled", null)
      user_registration_enabled = lookup(delegation.value, "user_registration_enabled", null)
      url                       = lookup(delegation.value, "url", null)
      validation_key            = lookup(delegation.value, "validation_key", null)
    }
  }
  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      type         = identity.value.type
      identity_ids = lookup(identity.value, "identity_ids", null)
    }
  }
  dynamic "hostname_configuration" {
    for_each = var.hostname_configuration != null ? [var.hostname_configuration] : []
    content {
      dynamic "management" {
        for_each = hostname_configuration.value.management != null ? hostname_configuration.value.management : []
        content {
          host_name                       = management.value.host_name
          key_vault_id                    = lookup(management.value, "key_vault_id", null)
          certificate                     = lookup(management.value, "certificate", null)
          certificate_password            = lookup(management.value, "certificate_password", null)
          negotiate_client_certificate    = lookup(management.value, "negotiate_client_certificate", null)
          ssl_keyvault_identity_client_id = lookup(management.value, "ssl_keyvault_identity_client_id", null)
        }
      }
      dynamic "portal" {
        for_each = hostname_configuration.value.portal != null ? hostname_configuration.value.portal : []
        content {
          host_name                       = portal.value.host_name
          key_vault_id                    = lookup(portal.value, "key_vault_id", null)
          certificate                     = lookup(portal.value, "certificate", null)
          certificate_password            = lookup(portal.value, "certificate_password", null)
          negotiate_client_certificate    = lookup(portal.value, "negotiate_client_certificate", null)
          ssl_keyvault_identity_client_id = lookup(portal.value, "ssl_keyvault_identity_client_id", null)
        }
      }
      dynamic "developer_portal" {
        for_each = hostname_configuration.value.developer_portal != null ? hostname_configuration.value.developer_portal : []
        content {
          host_name                       = developer_portal.value.host_name
          key_vault_id                    = lookup(developer_portal.value, "key_vault_id", null)
          certificate                     = lookup(developer_portal.value, "certificate", null)
          certificate_password            = lookup(developer_portal.value, "certificate_password", null)
          negotiate_client_certificate    = lookup(developer_portal.value, "negotiate_client_certificate", null)
          ssl_keyvault_identity_client_id = lookup(developer_portal.value, "ssl_keyvault_identity_client_id", null)
        }
      }
      dynamic "proxy" {
        for_each = hostname_configuration.value.proxy != null ? hostname_configuration.value.proxy : []
        content {
          host_name                       = proxy.value.host_name
          default_ssl_binding             = lookup(proxy.value, "default_ssl_binding", null)
          key_vault_id                    = lookup(proxy.value, "key_vault_id", null)
          certificate                     = lookup(proxy.value, "certificate", null)
          certificate_password            = lookup(proxy.value, "certificate_password", null)
          negotiate_client_certificate    = lookup(proxy.value, "negotiate_client_certificate", null)
          ssl_keyvault_identity_client_id = lookup(proxy.value, "ssl_keyvault_identity_client_id", null)
        }
      }
      dynamic "scm" {
        for_each = hostname_configuration.value.scm != null ? hostname_configuration.value.scm : []
        content {
          host_name                       = scm.value.host_name
          key_vault_id                    = lookup(scm.value, "key_vault_id", null)
          certificate                     = lookup(scm.value, "certificate", null)
          certificate_password            = lookup(scm.value, "certificate_password", null)
          negotiate_client_certificate    = lookup(scm.value, "negotiate_client_certificate", null)
          ssl_keyvault_identity_client_id = lookup(scm.value, "ssl_keyvault_identity_client_id", null)
        }
      }
    }
  }
  dynamic "policy" {
    for_each = var.policy != null ? [var.policy] : []
    content {
      xml_content = lookup(policy.value, "xml_content", null)
      xml_link    = lookup(policy.value, "xml_link", null)
    }
  }
  dynamic "protocols" {
    for_each = var.protocols != null ? [var.protocols] : []
    content {
      enable_http2 = lookup(proxy.value, "enable_http2", null)
    }
  }
  dynamic "security" {
    for_each = var.security != null ? [var.security] : []
    content {
      enable_backend_ssl30                                = lookup(proxy.value, "enable_backend_ssl30", false)
      enable_backend_tls10                                = lookup(proxy.value, "enable_backend_tls10", false)
      enable_backend_tls11                                = lookup(proxy.value, "enable_backend_tls11", false)
      enable_frontend_ssl30                               = lookup(proxy.value, "enable_frontend_ssl30", false)
      enable_frontend_tls10                               = lookup(proxy.value, "enable_frontend_tls10", false)
      enable_frontend_tls11                               = lookup(proxy.value, "enable_frontend_tls11", false)
      tls_ecdhe_ecdsa_with_aes128_cbc_sha_ciphers_enabled = lookup(proxy.value, "tls_ecdhe_ecdsa_with_aes128_cbc_sha_ciphers_enabled", false)
      tls_ecdhe_ecdsa_with_aes256_cbc_sha_ciphers_enabled = lookup(proxy.value, "tls_ecdhe_ecdsa_with_aes256_cbc_sha_ciphers_enabled", false)
      tls_ecdhe_rsa_with_aes128_cbc_sha_ciphers_enabled   = lookup(proxy.value, "tls_ecdhe_rsa_with_aes128_cbc_sha_ciphers_enabled", false)
      tls_ecdhe_rsa_with_aes256_cbc_sha_ciphers_enabled   = lookup(proxy.value, "tls_ecdhe_rsa_with_aes256_cbc_sha_ciphers_enabled", false)
      tls_rsa_with_aes128_cbc_sha256_ciphers_enabled      = lookup(proxy.value, "tls_rsa_with_aes128_cbc_sha256_ciphers_enabled", false)
      tls_rsa_with_aes128_cbc_sha_ciphers_enabled         = lookup(proxy.value, "tls_rsa_with_aes128_cbc_sha_ciphers_enabled", false)
      tls_rsa_with_aes128_gcm_sha256_ciphers_enabled      = lookup(proxy.value, "tls_rsa_with_aes128_gcm_sha256_ciphers_enabled", false)
      tls_rsa_with_aes256_gcm_sha384_ciphers_enabled      = lookup(proxy.value, "tls_rsa_with_aes256_gcm_sha384_ciphers_enabled", false)
      tls_rsa_with_aes256_cbc_sha256_ciphers_enabled      = lookup(proxy.value, "tls_rsa_with_aes256_cbc_sha256_ciphers_enabled", false)
      tls_rsa_with_aes256_cbc_sha_ciphers_enabled         = lookup(proxy.value, "tls_rsa_with_aes256_cbc_sha_ciphers_enabled", false)
      triple_des_ciphers_enabled                          = lookup(proxy.value, "triple_des_ciphers_enabled", false)
    }
  }
  dynamic "sign_in" {
    for_each = var.sign_in != null ? [var.sign_in] : []
    content {
      enabled = sign_in.value.enabled
    }
  }
  dynamic "sign_up" {
    for_each = var.sign_up != null ? [var.sign_up] : []
    content {
      enabled = sign_up.value.enabled
      dynamic "terms_of_service" {
        for_each = sign_up.value.terms_of_service != null ? [sign_up.value.terms_of_service] : []
        content {
          consent_required = terms_of_service.value.consent_required
          enabled          = terms_of_service.value.enabled
          text             = terms_of_service.value.text
        }
      }
    }
  }
  dynamic "tenant_access" {
    for_each = var.tenant_access != null ? [var.tenant_access] : []
    content {
      enabled = tenant_access.value.enabled
    }
  }
  dynamic "virtual_network_configuration" {
    for_each = var.virtual_network_configuration != null ? [var.virtual_network_configuration] : []
    content {
      subnet_id = virtual_network_configuration.value.subnet_id
    }
  }
}
