variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "allocation_method" {
  type    = string
  default = "Static"
}

variable "sku" {
  type    = string
  default = "Standard"
}

variable "sku_tier" {
  type    = string
  default = "Regional"
}

variable "ip_version" {
  type    = string
  default = "IPv4"
}

variable "domain_name_label" {
  type    = string
  default = null
}

variable "idle_timeout_in_minutes" {
  type    = number
  default = 4
}

variable "public_ip_prefix_id" {
  type    = string
  default = null
}

variable "reverse_fqdn" {
  type    = string
  default = null
}

variable "zones" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
