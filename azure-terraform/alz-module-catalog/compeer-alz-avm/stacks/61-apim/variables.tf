variable "subscription_id" { type = string }
variable "location" {
  type    = string
  default = "centralus"
}
variable "resource_group_name" { type = string }
variable "publisher_email" { type = string }
variable "publisher_name" {
  type    = string
  default = "Compeer"
}
variable "sku_name" {
  type    = string
  default = "Premium_1"
}
variable "private_endpoint_subnet_id" { type = string }
variable "private_dns_zone_ids" {
  type    = set(string)
  default = []
}
variable "log_analytics_workspace_id" { type = string }
variable "enable_telemetry" {
  type    = bool
  default = true
}
variable "tags" {
  type    = map(string)
  default = {}
}
