variable "associations" {
  type = map(object({
    subnet_id      = string
    nat_gateway_id = string
  }))
  default = {}
}
