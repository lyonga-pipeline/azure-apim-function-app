locals {
  rbac_authorization_enabled = coalesce(var.rbac_authorization_enabled, var.enable_rbac_authorization, true)
}

resource "azurerm_key_vault" "this" {
  name                            = var.name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tenant_id                       = var.tenant_id
  sku_name                        = lower(var.sku_name)
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  soft_delete_retention_days      = var.soft_delete_retention_days
  purge_protection_enabled        = var.purge_protection_enabled
  rbac_authorization_enabled      = local.rbac_authorization_enabled
  public_network_access_enabled   = var.public_network_access_enabled
  tags                            = var.tags

  dynamic "access_policy" {
    for_each = local.rbac_authorization_enabled ? [] : var.access_policies
    content {
      tenant_id               = access_policy.value.tenant_id
      object_id               = access_policy.value.object_id
      application_id          = try(access_policy.value.application_id, null)
      key_permissions         = try(access_policy.value.key_permissions, [])
      secret_permissions      = try(access_policy.value.secret_permissions, [])
      certificate_permissions = try(access_policy.value.certificate_permissions, [])
      storage_permissions     = try(access_policy.value.storage_permissions, [])
    }
  }

  dynamic "network_acls" {
    for_each = var.network_acls == null ? [] : [var.network_acls]
    content {
      bypass                     = network_acls.value.bypass
      default_action             = network_acls.value.default_action
      ip_rules                   = try(network_acls.value.ip_rules, [])
      virtual_network_subnet_ids = try(network_acls.value.virtual_network_subnet_ids, [])
    }
  }

  dynamic "contact" {
    for_each = var.contacts
    content {
      email = contact.value.email
      name  = try(contact.value.name, null)
      phone = try(contact.value.phone, null)
    }
  }

  timeouts {
    create = try(var.timeouts.create, null)
    read   = try(var.timeouts.read, null)
    update = try(var.timeouts.update, null)
    delete = try(var.timeouts.delete, null)
  }
}
