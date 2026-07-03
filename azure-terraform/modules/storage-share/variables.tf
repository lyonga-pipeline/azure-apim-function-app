variable "storage_account_id" { type = string }
variable "shares" {
  type = map(object({
    quota       = optional(number, 100)
    access_tier = optional(string)
    metadata    = optional(map(string))
  }))
  default = {}
}
