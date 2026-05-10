variable "storage_account_name" { type = string }
variable "tables" {
  type    = map(object({}))
  default = {}
}
