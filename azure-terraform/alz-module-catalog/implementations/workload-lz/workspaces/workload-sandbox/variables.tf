variable "enabled" {
  description = "Deploy only after replacing every synthetic client value and receiving approval."
  type        = bool
  default     = false
}
variable "deployment_approved" {
  description = "Explicit approval gate, not a substitute for reviewing the Terraform plan."
  type        = bool
  default     = false
}
variable "subscription_id" { type = string }
variable "tenant_id" { type = string }
variable "private_dns_subscription_id" { type = string }
variable "environment" {
  type    = string
  default = "sandbox"
}
variable "platform" {
  description = "Approved public platform output values. No new LAW, hub, DNS zones or Defender pricing."
  type        = any
}
variable "spoke" {
  description = "IPAM, naming, tags and authorization inputs. Common to the capability variants."
  type        = any
}
variable "key_vault" {
  type    = any
  default = {}
}
variable "diagnostics" {
  type    = any
  default = {}
}
variable "operations" {
  type    = any
  default = {}
}
variable "monitoring" {
  type    = any
  default = {}
}
variable "storage_accounts" {
  type    = any
  default = {}
}
variable "backup" {
  type    = any
  default = null
}
