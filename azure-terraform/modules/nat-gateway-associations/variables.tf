variable "nat_gateway_id" { type = string }
variable "public_ip_address_ids" {
  type    = list(string)
  default = []
}
variable "subnet_ids" {
  type    = list(string)
  default = []
}
