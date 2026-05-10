variable "virtual_machine_id" { type = string }
variable "extensions" {
  type = map(object({
    publisher                   = string
    type                        = string
    type_handler_version        = string
    auto_upgrade_minor_version  = optional(bool, true)
    automatic_upgrade_enabled   = optional(bool)
    failure_suppression_enabled = optional(bool)
    settings                    = optional(any)
    protected_settings          = optional(any)
  }))
  default = {}
}
