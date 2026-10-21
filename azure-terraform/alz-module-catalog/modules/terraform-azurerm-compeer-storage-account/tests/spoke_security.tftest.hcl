mock_provider "azurerm" {}

variables {
  name                              = "stworkload001"
  resource_group_name               = "rg-workload-data"
  location                          = "centralus"
  account_replication_type          = "ZRS"
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
    delete_retention_days           = 30
    container_delete_retention_days = 30
  }
}

run "spoke_security_inputs_reach_the_storage_resource" {
  command = apply
  assert {
    condition = (
      azurerm_storage_account.account.account_replication_type == "ZRS" &&
      !azurerm_storage_account.account.public_network_access_enabled &&
      !azurerm_storage_account.account.allow_nested_items_to_be_public &&
      !azurerm_storage_account.account.shared_access_key_enabled &&
      azurerm_storage_account.account.min_tls_version == "TLS1_2" &&
      azurerm_storage_account.account.https_traffic_only_enabled &&
      azurerm_storage_account.account.infrastructure_encryption_enabled &&
      azurerm_storage_account.account.default_to_oauth_authentication &&
      !azurerm_storage_account.account.cross_tenant_replication_enabled &&
      azurerm_storage_account.account.network_rules[0].default_action == "Deny" &&
      azurerm_storage_account.account.network_rules[0].bypass == toset(["None"]) &&
      azurerm_storage_account.account.blob_properties[0].versioning_enabled &&
      azurerm_storage_account.account.blob_properties[0].change_feed_enabled &&
      azurerm_storage_account.account.blob_properties[0].delete_retention_policy[0].days == 30 &&
      azurerm_storage_account.account.blob_properties[0].container_delete_retention_policy[0].days == 30
    )
    error_message = "The catalog helper must wire the spoke's secure production inputs into its storage resource; this is not a live Azure acceptance check."
  }
}

run "nonproduction_recovery_inputs_reach_the_storage_resource" {
  command = plan
  variables {
    account_replication_type = "LRS"
    blob_properties = {
      versioning_enabled              = true
      change_feed_enabled             = true
      delete_retention_days           = 7
      container_delete_retention_days = 7
    }
  }
  assert {
    condition = (
      azurerm_storage_account.account.account_replication_type == "LRS" &&
      azurerm_storage_account.account.blob_properties[0].delete_retention_policy[0].days == 7 &&
      azurerm_storage_account.account.blob_properties[0].container_delete_retention_policy[0].days == 7 &&
      !azurerm_storage_account.account.public_network_access_enabled &&
      !azurerm_storage_account.account.shared_access_key_enabled
    )
    error_message = "The catalog helper must wire non-production recovery inputs without weakening private/keyless access."
  }
}
