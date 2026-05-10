variable "server_id" { type = string }
variable "databases" {
  type = map(object({
    sku_name                       = optional(string, "GP_S_Gen5_2")
    max_size_gb                    = optional(number, 32)
    zone_redundant                 = optional(bool, false)
    read_scale                     = optional(bool, false)
    collation                      = optional(string)
    license_type                   = optional(string)
    enclave_type                   = optional(string)
    ledger_enabled                 = optional(bool, false)
    elastic_pool_id                = optional(string)
    maintenance_configuration_name = optional(string)
    tags                           = optional(map(string), {})
  }))
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
