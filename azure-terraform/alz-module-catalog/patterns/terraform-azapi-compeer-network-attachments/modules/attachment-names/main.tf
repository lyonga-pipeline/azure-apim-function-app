# Attachment names depend on existing VNet names, not on workload/environment tokens.
# These formulas preserve the parent naming module's public naming convention.
variable "vnet_peerings" {
  description = "Stable keys and the two already-approved VNet names."
  type        = map(object({ local_vnet = string, remote_vnet = string }))
  default     = {}
}

variable "private_dns_link_vnets" {
  description = "Existing VNet names requiring centrally owned DNS links."
  type        = list(string)
  default     = []
}

output "vnet_peering_names" {
  value = { for key, pair in var.vnet_peerings : key => "${lower(trimspace(pair.local_vnet))}-to-${lower(trimspace(pair.remote_vnet))}" }
  precondition {
    condition     = alltrue([for pair in values(var.vnet_peerings) : length("${trimspace(pair.local_vnet)}-to-${trimspace(pair.remote_vnet)}") <= 80])
    error_message = "Canonical peering names exceed 80 characters; use approved existing-name overrides."
  }
}

output "private_dns_link_names" {
  value = { for name in var.private_dns_link_vnets : name => "${lower(trimspace(name))}-link" }
  precondition {
    condition     = alltrue([for name in var.private_dns_link_vnets : length("${trimspace(name)}-link") <= 80])
    error_message = "Canonical DNS link names exceed 80 characters."
  }
}
