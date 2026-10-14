module "storage" {
  source                            = "../../modules/terraform-azurerm-compeer-storage-account"
  for_each                          = var.storage_accounts
  name                              = coalesce(each.value.name, module.naming.storage_account_names[each.key])
  resource_group_name               = module.resource_groups.group_names["data"]
  location                          = var.location
  account_replication_type          = local.storage_replication[each.key]
  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  public_network_access_enabled     = false
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = false
  default_to_oauth_authentication   = true
  infrastructure_encryption_enabled = true
  cross_tenant_replication_enabled  = false
  network_rules                     = { default_action = "Deny", bypass = ["None"] }
  blob_properties = {
    versioning_enabled              = true
    change_feed_enabled             = true
    delete_retention_days           = local.storage_retention[each.key]
    container_delete_retention_days = local.storage_retention[each.key]
  }
  tags       = module.tags.tags
  depends_on = [terraform_data.capability_contract]
}

module "storage_endpoints" {
  source              = "../../modules/terraform-azurerm-compeer-private-endpoint"
  for_each            = var.storage_accounts
  name                = "${local.workload_stem}-${each.key}-blob-pe"
  resource_group_name = module.resource_groups.group_names["data"]
  location            = var.location
  subnet_id           = local.subnet_ids["private_endpoints"]
  private_service_connections = [{
    name                           = "${each.key}-blob"
    is_manual_connection           = false
    private_connection_resource_id = module.storage[each.key].id
    subresource_names              = ["blob"]
  }]
  private_dns_zone_group = [{ name = "default", private_dns_zone_ids = [var.platform.storage_blob_private_dns_zone_id] }]
  tags                   = module.tags.tags
  depends_on             = [module.nsg_associations, module.route_associations, module.storage_dns_link]
}

module "storage_dns_link" {
  source    = "../../modules/terraform-azurerm-compeer-private-dns-vnet-link"
  providers = { azurerm = azurerm.dns }
  links = { for key in ["blob"] : key => {
    name                  = module.attachment_naming.private_dns_link_names[module.naming.workload_vnet]
    resource_group_name   = try(split("/", var.platform.storage_blob_private_dns_zone_id)[4], "")
    private_dns_zone_name = "privatelink.blob.core.windows.net"
    virtual_network_id    = module.network.id
    registration_enabled  = false
    tags                  = module.tags.tags
  } if var.manage_hub_attachment && length(var.storage_accounts) > 0 }
  tags       = module.tags.tags
  depends_on = [terraform_data.capability_contract, module.peering]
}

module "storage_access" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"
  assignments = { for key, account in var.storage_accounts : key => {
    scope                            = module.storage[key].id
    principal_id                     = module.workload_identity.principal_id
    principal_type                   = "ServicePrincipal"
    role_definition_name             = "Storage Blob Data Contributor"
    skip_service_principal_aad_check = true
  } if account.grant_workload_blob_access }
}

module "storage_metrics" {
  source                     = "../../modules/terraform-azurerm-compeer-diagnostic-settings"
  for_each                   = var.storage_accounts
  name                       = "diag-${module.storage[each.key].name}-law"
  target_resource_id         = module.storage[each.key].id
  log_analytics_workspace_id = var.platform.log_analytics_workspace_id
  metrics                    = { all = { category = "AllMetrics" } }
}

module "storage_blob_diagnostics" {
  source                     = "../../modules/terraform-azurerm-compeer-diagnostic-settings"
  for_each                   = var.storage_accounts
  name                       = "diag-${module.storage[each.key].name}-blob-law"
  target_resource_id         = "${module.storage[each.key].id}/blobServices/default"
  log_analytics_workspace_id = var.platform.log_analytics_workspace_id
  logs = {
    read   = { category = "StorageRead" }
    write  = { category = "StorageWrite" }
    delete = { category = "StorageDelete" }
  }
  metrics = { transaction = { category = "Transaction" } }
}
