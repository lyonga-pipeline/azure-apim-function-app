variable "storage_account_id" { type = string }
variable "tables" {
  type    = map(object({}))
  default = {}
}
