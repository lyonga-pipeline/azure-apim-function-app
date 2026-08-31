variable "subnet_id" {
  description = "ID of the subnet to associate. Changing this forces a new association."
  type        = string
}

variable "route_table_id" {
  description = "ID of the route table to associate to the subnet."
  type        = string
}
