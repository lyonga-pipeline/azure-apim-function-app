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
variable "route_table" { type = any }
variable "nat_gateway" { type = any }
variable "nat_public_ip" { type = any }
variable "private_dns_zones" { type = any }
variable "private_dns_links" { type = any }
variable "key_vault" { type = any }
variable "key_vault_secrets" { type = any }
variable "storage_account" { type = any }
variable "storage_containers" { type = any }
variable "storage_queues" { type = any }
variable "storage_tables" { type = any }
variable "storage_shares" { type = any }
variable "app_service_plan" { type = any }
variable "function_app" { type = any }
variable "function_app_slot" { type = any }
variable "container_group" { type = any }
variable "eventgrid_topic" { type = any }
variable "eventgrid_subscription" { type = any }
variable "function_app_private_endpoint" { type = any }
variable "key_vault_private_endpoint" { type = any }
variable "function_app_key_vault_role_name" {
  type    = string
  default = "Key Vault Secrets User"
}
variable "function_app_storage_role_name" {
  type    = string
  default = "Storage Blob Data Contributor"
}
variable "function_app_diagnostics" { type = any }
variable "eventgrid_diagnostics" { type = any }
