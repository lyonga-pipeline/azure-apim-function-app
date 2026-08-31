variable "records" {
  description = "A records keyed by a stable logical key."
  type = map(object({
    name                = string
    zone_name           = string
    resource_group_name = string
    ttl                 = optional(number, 300)
    records             = list(string)
    tags                = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for r in values(var.records) : r.ttl >= 1 && r.ttl <= 2147483647 && length(r.records) > 0])
    error_message = "Each record needs ttl in 1..2147483647 and at least one IP."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}
