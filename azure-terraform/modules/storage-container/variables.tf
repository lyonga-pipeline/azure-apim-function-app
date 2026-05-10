variable "storage_account_name" { type = string }
variable "containers" {
  type = map(object({
    container_access_type = optional(string, "private")
    metadata              = optional(map(string))
  }))
  default = {}
}
