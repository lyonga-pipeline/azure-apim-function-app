variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "api_management_name" { type = string }
variable "protocol" { type = string }
variable "url" { type = string }
variable "description" {
  type    = string
  default = null
}
variable "resource_id" {
  type    = string
  default = null
}
variable "title" {
  type    = string
  default = null
}
variable "credentials" {
  type = object({
    query       = optional(map(string))
    header      = optional(map(string))
    certificate = optional(list(string))
    authorization = optional(object({
      scheme    = string
      parameter = string
    }))
  })
  default = null
}
variable "proxy" {
  type = object({
    url      = string
    username = optional(string)
    password = optional(string)
  })
  default = null
}
variable "tls" {
  type = object({
    validate_certificate_chain = optional(bool, true)
    validate_certificate_name  = optional(bool, true)
  })
  default = null
}
