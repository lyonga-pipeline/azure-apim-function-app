variable "hostname" { type = string }
variable "app_service_slot_id" { type = string }
variable "ssl_state" {
  type    = string
  default = null

  validation {
    condition     = var.ssl_state == null || contains(["Disabled", "SniEnabled", "IpBasedEnabled"], var.ssl_state)
    error_message = "ssl_state must be Disabled, SniEnabled, or IpBasedEnabled when set."
  }
}
variable "thumbprint" {
  type    = string
  default = null
}
