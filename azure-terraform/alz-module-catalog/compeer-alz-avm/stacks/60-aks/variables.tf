variable "subscription_id" { type = string }
variable "location" {
  type    = string
  default = "centralus"
}
variable "resource_group_name" { type = string }
variable "node_subnet_id" { type = string }
variable "pod_cidr" { type = string }
variable "service_cidr" { type = string }
variable "dns_service_ip" { type = string }
variable "kubernetes_version" {
  type    = string
  default = null
}
variable "enable_telemetry" {
  type    = bool
  default = true
}
variable "tags" {
  type    = map(string)
  default = {}
}
