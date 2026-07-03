variable "storage_account_id" { type = string }
variable "containers" {
  type = map(object({
    container_access_type = optional(string, "private")
    metadata              = optional(map(string))
  }))
  default = {}
}
