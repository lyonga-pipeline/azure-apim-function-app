variable "product_id" { type = string }
variable "api_management_name" { type = string }
variable "resource_group_name" { type = string }
variable "display_name" { type = string }
variable "approval_required" {
  type    = bool
  default = false
}
variable "published" {
  type    = bool
  default = true
}
variable "subscription_required" {
  type    = bool
  default = true
}
variable "subscriptions_limit" {
  type    = number
  default = null
}
variable "terms" {
  type    = string
  default = null
}
variable "description" {
  type    = string
  default = null
}
