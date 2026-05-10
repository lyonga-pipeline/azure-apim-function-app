variable "storage_account_name" { type = string }
variable "queues" {
  type = map(object({
    metadata = optional(map(string))
  }))
  default = {}
}
