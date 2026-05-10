variable "name" {
  type    = string
  default = "domain-join"
}
variable "virtual_machine_id" { type = string }
variable "domain_name" { type = string }
variable "ou_path" {
  type    = string
  default = null
}
variable "domain_username" { type = string }
variable "domain_password" {
  type      = string
  sensitive = true
}
variable "restart" {
  type    = bool
  default = true
}
variable "join_options" {
  type    = number
  default = 3
}
variable "type_handler_version" {
  type    = string
  default = "1.3"
}
