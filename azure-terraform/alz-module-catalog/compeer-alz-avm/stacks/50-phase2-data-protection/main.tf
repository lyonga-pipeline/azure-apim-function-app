locals {
  tags = merge({ ManagedBy = "Terraform", IaCSource = "AVM+CompeerHCP", Phase = "2" }, var.tags)
  lock = { kind = "CanNotDelete" }
}

module "disk_encryption_set" {
  source                = "Azure/avm-res-compute-diskencryptionset/azurerm"
  version               = "0.1.1"
  name                  = "cmp-cus-des"
  location              = var.location
  resource_group_name   = var.resource_group_name
  key_vault_key_id      = var.disk_encryption_key_id
  key_vault_resource_id = var.key_vault_resource_id
  managed_identities    = { system_assigned = true }
  lock                  = local.lock
  tags                  = local.tags
  enable_telemetry      = var.enable_telemetry
}

module "log_archive" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-storage-account/azurerm"
  version = "1.3.3"

  name                              = "cmpcuslogarchive"
  location                          = var.location
  resource_group_name               = var.resource_group_name
  account_kind                      = "StorageV2"
  account_tier                      = "Standard"
  account_replication_type          = "ZRS"
  min_tls_version                   = "TLS1_2"
  public_network_access_enabled     = false
  shared_access_key_enabled         = false
  allow_nested_items_to_be_public   = false
  default_to_oauth_authentication   = true
  infrastructure_encryption_enabled = true
  blob_properties = {
    versioning_enabled              = true
    change_feed_enabled             = true
    last_access_time_enabled        = true
    delete_retention_days           = 30
    container_delete_retention_days = 30
  }
  tags = local.tags
}

module "log_archive_diagnostics" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-diagnostic-settings/azurerm"
  version = "1.0.0"

  name                       = "cmp-cus-logarchive-law"
  target_resource_id         = module.log_archive.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  logs = {
    all = { category_group = "allLogs" }
  }
  metrics = {
    transaction = { category = "Transaction" }
  }
}

module "compute_gallery" {
  source              = "Azure/avm-res-compute-gallery/azurerm"
  version             = "0.2.1"
  name                = "cmp_cus_gallery"
  location            = var.location
  resource_group_name = var.resource_group_name
  description         = "Hardened Compeer golden images"
  sharing             = { permission = "Private" }
  lock                = local.lock
  tags                = local.tags
  enable_telemetry    = var.enable_telemetry
}

# PLT-07: secondary RSV for ASR control plane. Replicated-item definitions are
# workload-specific and remain input-driven/native because no separate AVM exists.
module "dr_recovery_services_vault" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-recovery-services-vault/azurerm"
  version = "1.0.0"

  name                = "cmp-dr-eus2-rsv"
  location            = var.dr_location
  resource_group_name = var.dr_resource_group_name
  sku                 = "Standard"
  storage_mode_type   = "ZoneRedundant"
  soft_delete_enabled = true
  tags                = local.tags
}

module "dr_recovery_services_vault_diagnostics" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-diagnostic-settings/azurerm"
  version = "1.0.0"

  name                       = "cmp-dr-eus2-rsv-law"
  target_resource_id         = module.dr_recovery_services_vault.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  logs = {
    all = { category_group = "allLogs" }
  }
  metrics = {
    all = { category = "AllMetrics" }
  }
}
