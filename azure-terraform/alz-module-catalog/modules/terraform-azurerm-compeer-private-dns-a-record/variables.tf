variable "records" {
  type = map(object({
    name                = string
    zone_name           = string
    resource_group_name = string
    ttl                 = optional(number, 300)
    records             = list(string)
    tags                = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
