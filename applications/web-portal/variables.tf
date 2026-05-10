variable "application_name" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "tenant_id" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
variable "resource_group" { type = any }
variable "log_analytics" { type = any }
variable "application_insights" { type = any }
variable "virtual_network" { type = any }
variable "private_dns_zones" { type = any }
variable "private_dns_links" { type = any }
variable "key_vault" { type = any }
variable "key_vault_keys" { type = any }
variable "key_vault_secrets" { type = any }
variable "storage_account" { type = any }
variable "storage_cmk" { type = any }
variable "storage_management_rules" { type = any }
variable "storage_containers" { type = any }
variable "storage_shares" { type = any }
variable "storage_blobs" { type = any }
variable "app_service_plan" { type = any }
variable "web_app" { type = any }
variable "web_app_slot" { type = any }
variable "web_app_key_vault_role_name" {
  type    = string
  default = "Key Vault Secrets User"
}
variable "web_app_storage_role_name" {
  type    = string
  default = "Storage Blob Data Contributor"
}
variable "storage_cmk_role_name" {
  type    = string
  default = "Key Vault Crypto Service Encryption User"
}
variable "web_app_private_endpoint" { type = any }
variable "key_vault_private_endpoint" { type = any }
variable "storage_blob_private_endpoint" { type = any }
variable "storage_file_private_endpoint" { type = any }
variable "web_app_diagnostics" { type = any }
variable "key_vault_diagnostics" { type = any }
variable "storage_diagnostics" { type = any }
