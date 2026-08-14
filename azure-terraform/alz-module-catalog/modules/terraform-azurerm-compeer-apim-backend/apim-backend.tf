resource "azurerm_api_management_backend" "apim_backend" {
  api_management_name = var.apim_name
  resource_group_name = var.resource_group_name
  name                = var.apim_backend_name
  protocol            = var.apim_backend_protocol
  url                 = var.apim_backend_url
  description         = var.apim_backend_description
  resource_id         = var.apim_backend_resource_id
  title               = var.apim_backend_title

  dynamic "credentials" {
    for_each = var.credentials != null ? [var.credentials] : []
    content {
      header = credentials.value.header
      query  = credentials.value.query
      dynamic "authorization" {
        for_each = lookup(credentials.value, "authorization", {})
        content {
          parameter = authorization.value.parameter
          scheme    = authorization.value.scheme
        }
      }
      certificate = lookup(credentials.value, "certificate", null)
    }
  }
  dynamic "proxy" {
    for_each = var.proxy != null ? [var.proxy] : []
    content {
      password = lookup(proxy.value, "password", null)
      url      = proxy.value.url
      username = proxy.value.username
    }
  }
  dynamic "service_fabric_cluster" {
    for_each = var.service_fabric_cluster != null ? [var.service_fabric_cluster] : []
    content {
      management_endpoints             = service_fabric_cluster.value.management_endpoints
      max_partition_resolution_retries = service_fabric_cluster.value.max_partition_resolution_retries
      client_certificate_thumbprint    = lookup(service_fabric_cluster.value, "client_certificate_thumbprint", null)
      client_certificate_id            = lookup(service_fabric_cluster.value, "client_certificate_id", null)
      server_certificate_thumbprints   = lookup(service_fabric_cluster.value, "server_certificate_thumbprints", null)
      dynamic "server_x509_name" {
        for_each = service_fabric_cluster.value.server_x509_name != null ? [service_fabric_cluster.value.server_x509_name] : []
        content {
          issuer_certificate_thumbprint = server_x509_name.value.issuer_certificate_thumbprint
          name                          = server_x509_name.value.name
        }
      }
    }
  }
  dynamic "tls" {
    for_each = var.tls != null ? [var.tls] : []
    content {
      validate_certificate_chain = lookup(tls.value, "validate_certificate_chain", null)
      validate_certificate_name  = lookup(tls.value, "validate_certificate_name", null)
    }
  }
}
