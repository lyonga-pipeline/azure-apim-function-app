variable "storage_account_id" { type = string }
variable "key_vault_key_id" { type = string }
variable "user_assigned_identity_id" {
  type    = string
  default = null
}
variable "federated_identity_client_id" {
  type    = string
  default = null
}
variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}
