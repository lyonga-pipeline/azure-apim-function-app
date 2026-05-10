resource "azurerm_api_management_api" "this" {
  name                  = var.name
  resource_group_name   = var.resource_group_name
  api_management_name   = var.api_management_name
  revision              = var.revision
  display_name          = var.display_name
  path                  = var.path
  protocols             = var.protocols
  service_url           = var.service_url
  subscription_required = var.subscription_required
  version               = var.api_version
  version_set_id        = var.version_set_id
  api_type              = var.api_type
  description           = var.description

  dynamic "import" {
    for_each = var.import == null ? [] : [var.import]
    content {
      content_format = import.value.content_format
      content_value  = import.value.content_value
      wsdl_selector {
        service_name  = try(import.value.wsdl_selector.service_name, null)
        endpoint_name = try(import.value.wsdl_selector.endpoint_name, null)
      }
    }
  }

  dynamic "subscription_key_parameter_names" {
    for_each = var.subscription_key_parameter_names == null ? [] : [var.subscription_key_parameter_names]
    content {
      header = try(subscription_key_parameter_names.value.header, null)
      query  = try(subscription_key_parameter_names.value.query, null)
    }
  }
}
