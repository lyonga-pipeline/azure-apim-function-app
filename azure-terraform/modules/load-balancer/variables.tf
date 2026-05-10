variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "sku" {
  type    = string
  default = "Standard"
}
variable "edge_zone" {
  type    = string
  default = null
}
variable "frontend_ip_configurations" {
  type = map(object({
    subnet_id                     = optional(string)
    private_ip_address            = optional(string)
    private_ip_address_allocation = optional(string)
    public_ip_address_id          = optional(string)
    zones                         = optional(list(string))
  }))
}
variable "backend_address_pools" {
  type    = map(object({}))
  default = {}
}
variable "probes" {
  type = map(object({
    protocol            = string
    port                = number
    request_path        = optional(string)
    interval_in_seconds = optional(number, 5)
    number_of_probes    = optional(number, 2)
  }))
  default = {}
}
variable "rules" {
  type = map(object({
    protocol                       = string
    frontend_port                  = number
    backend_port                   = number
    frontend_ip_configuration_name = string
    backend_address_pool_names     = list(string)
    probe_name                     = optional(string)
    load_distribution              = optional(string, "Default")
    disable_outbound_snat          = optional(bool, false)
    idle_timeout_in_minutes        = optional(number, 4)
    enable_floating_ip             = optional(bool, false)
  }))
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
