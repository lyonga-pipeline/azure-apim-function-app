variable "zones" {
  description = "Private DNS zones keyed by a stable logical key."
  type = map(object({
    name                = string
    resource_group_name = string
    tags                = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for z in values(var.zones) : can(regex("^[A-Za-z0-9][A-Za-z0-9.-]+[A-Za-z0-9]$", z.name))])
    error_message = "Every zones[*].name must be a valid DNS zone name."
  }
}
variable "tags" {
  description = "Tags merged onto every zone."
  type        = map(string)
  default     = {}
}
