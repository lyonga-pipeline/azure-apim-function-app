variable "subscription_id" { type = string }
variable "location" {
  type    = string
  default = "centralus"
}
variable "resource_group_name" { type = string }
variable "name" { type = string }
variable "private_endpoint_subnet_id" { type = string }
variable "private_dns_zone_ids" {
  type    = set(string)
  default = []
}
variable "log_analytics_workspace_id" { type = string }
variable "entra_admin_login" { type = string }
variable "entra_admin_object_id" { type = string }
variable "enable_telemetry" {
  type    = bool
  default = true
}
variable "tags" {
  type    = map(string)
  default = {}
}
