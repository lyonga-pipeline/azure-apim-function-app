variable "subscription_id" { type = string }
variable "tenant_id" { type = string }
variable "location" { type = string }
variable "environment" {
  type = string
  validation {
    condition     = var.environment == "np3"
    error_message = "This root is only for np3."
  }
}
variable "application" { type = any }
variable "resource_group" { type = any }
variable "shared" { type = any }
variable "identity" { type = any }
variable "key_vault" { type = any }
variable "key_vault_secrets" {
  type    = any
  default = {}
}
variable "storage_account" { type = any }
variable "app_service_plan" { type = any }
variable "function_app" { type = any }
variable "diagnostics" { type = any }
variable "alerts" { type = any }
variable "additional_tags" {
  type    = map(string)
  default = {}
}
