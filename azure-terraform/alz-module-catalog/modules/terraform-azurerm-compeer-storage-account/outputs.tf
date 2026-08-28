output "id" {
  description = "The storage account ID."
  value       = azurerm_storage_account.this.id
}

output "name" {
  description = "The storage account name."
  value       = azurerm_storage_account.this.name
}

output "resource_group_name" {
  description = "The resource group containing the storage account."
  value       = azurerm_storage_account.this.resource_group_name
}

output "location" {
  description = "The Azure region of the storage account."
  value       = azurerm_storage_account.this.location
}

output "primary_location" {
  description = "The primary storage location."
  value       = azurerm_storage_account.this.primary_location
}

output "secondary_location" {
  description = "The secondary storage location when geo-replication is enabled."
  value       = azurerm_storage_account.this.secondary_location
}

output "identity_principal_id" {
  description = "The system-assigned managed identity principal ID, when enabled."
  value       = try(azurerm_storage_account.this.identity[0].principal_id, null)
}

output "identity_tenant_id" {
  description = "The managed identity tenant ID, when enabled."
  value       = try(azurerm_storage_account.this.identity[0].tenant_id, null)
}

output "primary_blob_endpoint" {
  description = "The primary Blob endpoint."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_queue_endpoint" {
  description = "The primary Queue endpoint."
  value       = azurerm_storage_account.this.primary_queue_endpoint
}

output "primary_table_endpoint" {
  description = "The primary Table endpoint."
  value       = azurerm_storage_account.this.primary_table_endpoint
}

output "primary_file_endpoint" {
  description = "The primary File endpoint."
  value       = azurerm_storage_account.this.primary_file_endpoint
}

output "primary_dfs_endpoint" {
  description = "The primary DFS endpoint."
  value       = azurerm_storage_account.this.primary_dfs_endpoint
}

output "primary_web_endpoint" {
  description = "The primary static website endpoint."
  value       = azurerm_storage_account.this.primary_web_endpoint
}

output "primary_endpoints" {
  description = "Primary service endpoints keyed by service name."
  value = {
    blob  = azurerm_storage_account.this.primary_blob_endpoint
    queue = azurerm_storage_account.this.primary_queue_endpoint
    table = azurerm_storage_account.this.primary_table_endpoint
    file  = azurerm_storage_account.this.primary_file_endpoint
    dfs   = azurerm_storage_account.this.primary_dfs_endpoint
    web   = azurerm_storage_account.this.primary_web_endpoint
  }
}

output "primary_hosts" {
  description = "Primary service hostnames keyed by service name."
  value = {
    blob  = azurerm_storage_account.this.primary_blob_host
    queue = azurerm_storage_account.this.primary_queue_host
    table = azurerm_storage_account.this.primary_table_host
    file  = azurerm_storage_account.this.primary_file_host
    dfs   = azurerm_storage_account.this.primary_dfs_host
    web   = azurerm_storage_account.this.primary_web_host
  }
}

output "private_endpoint_ready_subresource_names" {
  description = "Common Private Endpoint subresource names exposed for composition by pattern modules."
  value       = ["blob", "dfs", "file", "queue", "table", "web"]
}
