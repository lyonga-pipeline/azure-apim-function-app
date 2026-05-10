variable "resource_group_name" {
  type = string
}

variable "api_management_name" {
  type = string
}

variable "links" {
  type = map(object({
    product_id = string
    api_name   = string
  }))
  default = {}
}
