resource "azurerm_api_management_backend" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  protocol            = var.protocol
  url                 = var.url
  description         = var.description
  resource_id         = var.resource_id
  title               = var.title

  dynamic "credentials" {
    for_each = var.credentials == null ? [] : [var.credentials]
    content {
      query       = try(credentials.value.query, null)
      header      = try(credentials.value.header, null)
      certificate = try(credentials.value.certificate, null)
      dynamic "authorization" {
        for_each = try(credentials.value.authorization, null) == null ? [] : [credentials.value.authorization]
        content {
          scheme    = authorization.value.scheme
          parameter = authorization.value.parameter
        }
      }
    }
  }

  dynamic "proxy" {
    for_each = var.proxy == null ? [] : [var.proxy]
    content {
      url      = proxy.value.url
      username = try(proxy.value.username, null)
      password = try(proxy.value.password, null)
    }
  }

  dynamic "tls" {
    for_each = var.tls == null ? [] : [var.tls]
    content {
      validate_certificate_chain = try(tls.value.validate_certificate_chain, true)
      validate_certificate_name  = try(tls.value.validate_certificate_name, true)
    }
  }
}
