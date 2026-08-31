variable "resource_group_name" {
  description = "Resource group. Changing this forces a new resource."
  type        = string
}
variable "data_factory_name" {
  type = string
}
variable "location" {
  description = "Azure region. Changing this forces a new resource."
  type        = string
}
variable "managed_virtual_network_enabled" {
  type    = bool
  default = false
}
variable "public_network_enabled" {
  type    = bool
  default = false
}
variable "github_configuration" {
  type    = object({ account_name = string, branch_name = string, git_url = string, repository_name = string, root_folder = string })
  default = null
}
variable "azure_devops_configuration" {
  type    = object({ account_name = string, branch_name = string, project_name = string, repository_name = string, root_folder = string, tenant_id = string })
  default = null
}
variable "global_parameters" {
  type    = map(object({ value = string, type = string }))
  default = {}
}
variable "tags" {
  description = "Tags applied to the resource."
  type        = map(string)
  default     = {}
}
