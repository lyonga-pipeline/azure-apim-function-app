variable "storage_account_id" { type = string }
variable "queues" {
  type = map(object({
    metadata = optional(map(string))
  }))
  default = {}
}
