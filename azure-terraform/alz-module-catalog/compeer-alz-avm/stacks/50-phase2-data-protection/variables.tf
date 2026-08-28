variable "subscription_id" { type = string }
variable "location" {
  type    = string
  default = "centralus"
}
variable "dr_location" {
  type    = string
  default = "eastus2"
}
variable "resource_group_name" { type = string }
variable "dr_resource_group_name" { type = string }
variable "key_vault_resource_id" { type = string }
variable "disk_encryption_key_id" { type = string }
variable "log_analytics_workspace_id" { type = string }
variable "enable_telemetry" {
  type    = bool
  default = true
}
variable "tags" {
  type    = map(string)
  default = {}
}
