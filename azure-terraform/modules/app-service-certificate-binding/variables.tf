variable "hostname_binding_id" { type = string }
variable "certificate_id" { type = string }
variable "ssl_state" {
  type    = string
  default = "SniEnabled"

  validation {
    condition     = contains(["SniEnabled", "IpBasedEnabled"], var.ssl_state)
    error_message = "ssl_state must be SniEnabled or IpBasedEnabled."
  }
}
