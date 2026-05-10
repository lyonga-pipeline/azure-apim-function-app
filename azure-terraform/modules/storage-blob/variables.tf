variable "storage_account_name" { type = string }
variable "blobs" {
  type = map(object({
    container_name = string
    type           = optional(string, "Block")
    source         = optional(string)
    size           = optional(number)
    content_type   = optional(string)
    metadata       = optional(map(string))
  }))
  default = {}
}
