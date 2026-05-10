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
variable "virtual_network" { type = any }
variable "private_dns_zones" { type = any }
variable "private_dns_links" { type = any }
variable "private_dns_records" { type = any }
variable "gateway_public_ip" { type = any }
variable "key_vault" { type = any }
variable "key_vault_secrets" { type = any }
variable "key_vault_certificates" { type = any }
variable "key_vault_managed_hsm" { type = any }
variable "storage_account" { type = any }
variable "synapse_filesystem" { type = any }
variable "synapse_workspace" { type = any }
variable "synapse_workspace_aad_admin" { type = any }
variable "application_gateway" { type = any }
variable "apim_service" { type = any }
variable "apim_custom_domain" { type = any }
variable "apim_named_values" { type = any }
variable "apim_backend" { type = any }
variable "apim_api" { type = any }
variable "apim_policy" { type = any }
variable "apim_api_policy" { type = any }
variable "apim_product" { type = any }
variable "apim_product_apis" { type = any }
variable "apim_diagnostics" { type = any }
variable "synapse_diagnostics" { type = any }
variable "apim_key_vault_role_name" {
  type    = string
  default = "Key Vault Secrets User"
}
