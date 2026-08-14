locals {
  security_defaults = {
    enable_backend_ssl30  = false
    enable_backend_tls10  = false
    enable_backend_tls11  = false
    enable_frontend_ssl30 = false
    enable_frontend_tls10 = false
    enable_frontend_tls11 = false
  }
  effective_security  = merge(local.security_defaults, var.security == null ? {} : var.security)
  effective_protocols = merge({ enable_http2 = true }, var.protocols == null ? {} : var.protocols)
}

resource "azurerm_api_management" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  publisher_name                = var.publisher_name
  publisher_email               = var.publisher_email
  sku_name                      = var.sku_name
  public_network_access_enabled = var.public_network_access_enabled
  virtual_network_type          = var.virtual_network_type
  tags                          = var.tags

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  dynamic "virtual_network_configuration" {
    for_each = var.virtual_network_configuration == null ? [] : [var.virtual_network_configuration]
    content {
      subnet_id = virtual_network_configuration.value.subnet_id
    }
  }

  dynamic "security" {
    for_each = [local.effective_security]
    content {
      enable_backend_ssl30                                = try(security.value.enable_backend_ssl30, null)
      enable_backend_tls10                                = try(security.value.enable_backend_tls10, null)
      enable_backend_tls11                                = try(security.value.enable_backend_tls11, null)
      enable_frontend_ssl30                               = try(security.value.enable_frontend_ssl30, null)
      enable_frontend_tls10                               = try(security.value.enable_frontend_tls10, null)
      enable_frontend_tls11                               = try(security.value.enable_frontend_tls11, null)
      tls_ecdhe_ecdsa_with_aes128_cbc_sha_ciphers_enabled = try(security.value.tls_ecdhe_ecdsa_with_aes128_cbc_sha_ciphers_enabled, null)
    }
  }

  dynamic "protocols" {
    for_each = [local.effective_protocols]
    content {
      enable_http2 = try(protocols.value.enable_http2, null)
    }
  }

  dynamic "sign_in" {
    for_each = var.sign_in == null ? [] : [var.sign_in]
    content {
      enabled = sign_in.value.enabled
    }
  }

  dynamic "sign_up" {
    for_each = var.sign_up == null ? [] : [var.sign_up]
    content {
      enabled = sign_up.value.enabled
      dynamic "terms_of_service" {
        for_each = try(sign_up.value.terms_of_service, null) == null ? [] : [sign_up.value.terms_of_service]
        content {
          consent_required = try(terms_of_service.value.consent_required, false)
          enabled          = try(terms_of_service.value.enabled, false)
          text             = try(terms_of_service.value.text, null)
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition = (
        var.virtual_network_type == "None" ?
        var.virtual_network_configuration == null :
        var.virtual_network_configuration != null
      )
      error_message = "Set virtual_network_configuration when virtual_network_type is Internal or External, and omit it when virtual_network_type is None."
    }
  }
}
