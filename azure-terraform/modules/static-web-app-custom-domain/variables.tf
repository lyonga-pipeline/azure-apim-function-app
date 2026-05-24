variable "static_web_app_id" { type = string }
variable "domain_name" { type = string }
variable "validation_type" {
  type = string

  validation {
    condition     = contains(["cname-delegation", "dns-txt-token"], var.validation_type)
    error_message = "validation_type must be cname-delegation or dns-txt-token."
  }
}
