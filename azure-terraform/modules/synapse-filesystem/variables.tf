variable "name" { type = string }
variable "storage_account_id" { type = string }
variable "owner" {
  type    = string
  default = null
}
variable "group" {
  type    = string
  default = null
}
variable "properties" {
  type    = map(string)
  default = {}
}
