variable "location" {
  type    = string
  default = "centralus"
}

variable "enable_telemetry" {
  type    = bool
  default = true
}
variable "subscriptions" {
  type = map(object({
    alias_name          = string
    display_name        = string
    billing_scope       = string
    workload            = string
    management_group_id = string
    tags                = optional(map(string), {})
  }))
}
