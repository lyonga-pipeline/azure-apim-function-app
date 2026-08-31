variable "subnet_id" {
  description = "ID of the subnet to associate. Changing this forces a new association."
  type        = string
}

variable "network_security_group_id" {
  description = "ID of the NSG to associate to the subnet."
  type        = string
}
