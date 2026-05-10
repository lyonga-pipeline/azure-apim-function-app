variable "storage_account_name" { type = string }
variable "shares" {
  type = map(object({
    quota       = optional(number, 100)
    access_tier = optional(string)
    metadata    = optional(map(string))
  }))
  default = {}
}
