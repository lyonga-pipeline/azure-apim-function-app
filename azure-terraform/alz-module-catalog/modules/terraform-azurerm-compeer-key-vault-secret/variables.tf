variable "key_vault_id" {
  description = "Resource ID of the existing Key Vault."
  type        = string
}
variable "secrets" {
  type = map(object({
    value           = string
    content_type    = optional(string)
    not_before_date = optional(string)
    expiration_date = optional(string)
    tags            = optional(map(string), {})
  }))
  default   = {}
  sensitive = true
}
variable "tags" {
  description = "Tags applied to the resource."
  type        = map(string)
  default     = {}
}
