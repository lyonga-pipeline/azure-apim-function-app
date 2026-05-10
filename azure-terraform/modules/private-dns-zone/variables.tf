variable "zones" {
  type = map(object({
    name                = string
    resource_group_name = string
    tags                = optional(map(string), {})
  }))
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
