variable "associations" {
  type = map(object({
    nat_gateway_id       = string
    public_ip_address_id = string
  }))
  default = {}
}
