variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "api_management_name" { type = string }
variable "display_name" { type = string }
variable "path" { type = string }
variable "revision" {
  type    = string
  default = "1"
}
variable "protocols" {
  type    = list(string)
  default = ["https"]
}
variable "service_url" {
  type    = string
  default = null
}
variable "subscription_required" {
  type    = bool
  default = true
}
variable "api_version" {
  type    = string
  default = null
}
variable "version_set_id" {
  type    = string
  default = null
}
variable "api_type" {
  type    = string
  default = "http"
}
variable "description" {
  type    = string
  default = null
}
variable "import" {
  type = object({
    content_format = string
    content_value  = string
    wsdl_selector = optional(object({
      service_name  = optional(string)
      endpoint_name = optional(string)
    }), {})
  })
  default = null
}
variable "subscription_key_parameter_names" {
  type = object({
    header = optional(string)
    query  = optional(string)
  })
  default = null
}
