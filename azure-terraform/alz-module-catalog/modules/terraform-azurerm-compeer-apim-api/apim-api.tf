resource "azurerm_api_management_api" "api" {
  api_management_name = var.apim_name
  resource_group_name = var.resource_group_name
  name                = var.api_name
  revision            = var.revision
  api_type            = var.api_type
  display_name        = var.display_name
  path                = var.path
  protocols           = var.protocols
  description         = var.description
  dynamic "contact" {
    for_each = var.contact != null ? [var.contact] : []
    content {
      email = lookup(contact.value, "email", null)
      name  = lookup(contact.value, "name", null)
      url   = lookup(contact.value, "url", null)
    }
  }
  dynamic "import" {
    for_each = var.import != null ? [var.import] : []
    content {
      content_format = import.value.content_format
      content_value  = import.value.content_value
      dynamic "wsdl_selector" {
        for_each = import.value.wsdl_selector != null ? [import.value.wsdl_selector] : []
        content {
          service_name  = wsdl_selector.value.service_name
          endpoint_name = wsdl_selector.value.endpoint_name
        }
      }
    }
  }
  dynamic "license" {
    for_each = var.license != null ? [var.license] : []
    content {
      name = lookup(license.value, "name", null)
      url  = lookup(license.value, "url", null)
    }
  }
  dynamic "oauth2_authorization" {
    for_each = var.oauth2_authorization != null ? [var.oauth2_authorization] : []
    content {
      authorization_server_name = oauth2_authorization.value.authorization_server_name
      scope                     = lookup(oauth2_authorization.value, "scope", null)
    }
  }
  dynamic "openid_authentication" {
    for_each = var.openid_authentication != null ? [var.openid_authentication] : []
    content {
      openid_provider_name         = openid_authentication.value.openid_provider_name
      bearer_token_sending_methods = lookup(openid_authentication.value, "bearer_token_sending_methods", null)
    }
  }
  dynamic "subscription_key_parameter_names" {
    for_each = var.subscription_key_parameter_names != null ? [var.subscription_key_parameter_names] : []
    content {
      header = lookup(subscription_key_parameter_names.value, "header", null)
      query  = lookup(subscription_key_parameter_names.value, "query", null)
    }
  }
  service_url           = var.service_url
  subscription_required = var.subscription_required
  terms_of_service_url  = var.terms_of_service_url
  version               = var.api_version
  version_set_id        = var.version_set_id
  revision_description  = var.revision_description
  version_description   = var.version_description
  source_api_id         = var.source_api_id
}