resource "azurerm_static_web_app" "this" {
  name                               = var.name
  resource_group_name                = var.resource_group_name
  location                           = var.location
  sku_tier                           = var.sku_tier
  sku_size                           = var.sku_size
  public_network_access_enabled      = var.public_network_access_enabled
  preview_environments_enabled       = var.preview_environments_enabled
  configuration_file_changes_enabled = var.configuration_file_changes_enabled
  repository_url                     = var.repository_url
  repository_branch                  = var.repository_branch
  repository_token                   = var.repository_token
  app_settings                       = var.app_settings
  tags                               = var.tags

  dynamic "basic_auth" {
    for_each = var.basic_auth == null ? [] : [var.basic_auth]
    content {
      environments = basic_auth.value.environments
      password     = basic_auth.value.password
    }
  }

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }
}
