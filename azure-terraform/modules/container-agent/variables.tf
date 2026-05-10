variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "os_type" {
  type    = string
  default = "Linux"
}
variable "ip_address_type" {
  type    = string
  default = "Private"
}
variable "dns_name_label" {
  type    = string
  default = null
}
variable "subnet_ids" {
  type    = list(string)
  default = []
}
variable "restart_policy" {
  type    = string
  default = "Always"
}
variable "zones" {
  type    = list(string)
  default = []
}
variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null
}
variable "image_registry_credentials" {
  type = map(object({
    server   = string
    username = optional(string)
    password = optional(string)
  }))
  default = {}
}
variable "containers" {
  type = map(object({
    image  = string
    cpu    = number
    memory = number
    ports = optional(list(object({
      port     = number
      protocol = optional(string, "TCP")
    })), [])
    commands                     = optional(list(string))
    environment_variables        = optional(map(string))
    secure_environment_variables = optional(map(string))
    volumes = optional(map(object({
      mount_path           = string
      read_only            = optional(bool, false)
      share_name           = optional(string)
      storage_account_name = optional(string)
      storage_account_key  = optional(string)
      empty_dir            = optional(bool)
      git_repo = optional(object({
        url       = string
        directory = optional(string)
        revision  = optional(string)
      }))
      secret = optional(map(string))
    })), {})
  }))
}
variable "exposed_ports" {
  type = map(object({
    port     = number
    protocol = optional(string, "TCP")
  }))
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
