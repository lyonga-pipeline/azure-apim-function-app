variable "name" {
  description = "Name of the VM extension resource."
  type        = string
  default     = "domain-join"
}
variable "virtual_machine_id" {
  description = "Resource ID of the VM to domain-join. Changing this forces a new resource."
  type        = string
}
variable "domain_name" {
  description = "FQDN of the AD DS domain to join."
  type        = string
}
variable "ou_path" {
  description = "Optional LDAP OU path to place the computer object."
  type        = string
  default     = null
}
variable "domain_username" {
  description = "UPN or DOMAIN\\user with rights to join computers."
  type        = string
}
variable "domain_password" {
  description = "Password for domain_username. Stored in state unless protected_settings_from_key_vault is used."
  type        = string
  sensitive   = true
}
variable "restart" {
  description = "Restart the VM after joining."
  type        = bool
  default     = true
}
variable "join_options" {
  description = "JsonADDomainExtension join options bitmask (default 3 = join + create computer account)."
  type        = number
  default     = 3

  validation {
    condition     = var.join_options >= 0 && var.join_options <= 63
    error_message = "join_options must be a bitmask in the range 0-63."
  }
}
variable "type_handler_version" {
  description = "Extension type handler version."
  type        = string
  default     = "1.3"
}

variable "auto_upgrade_minor_version" {
  description = "Allow Azure to deploy newer minor versions for the selected extension handler version."
  type        = bool
  default     = true
}

variable "automatic_upgrade_enabled" {
  description = "Allow Azure to automatically upgrade the extension when the publisher releases a newer extension version."
  type        = bool
  default     = false
}

variable "failure_suppression_enabled" {
  description = "Suppress eligible extension failures. Operational failures such as inability to reach the VM are not suppressible."
  type        = bool
  default     = false
}

variable "provision_after_extensions" {
  description = "Extension names that must be provisioned before the domain join extension."
  type        = list(string)
  default     = []
}

variable "protected_settings_from_key_vault" {
  description = <<-EOT
    Optional Key Vault source for the complete protected-settings JSON document expected by JsonADDomainExtension.
    The secret value must contain the protected settings payload, for example: {"Password":"..."}.
    When set, inline domain_password is not sent to the extension protected_settings argument.
  EOT
  type = object({
    secret_url      = string
    source_vault_id = string
  })
  default = null
}

variable "tags" {
  description = "Optional tags assigned to the VM extension resource."
  type        = map(string)
  default     = {}
}

variable "timeouts" {
  description = "Optional custom Terraform operation timeouts for the VM extension. Omitted values retain provider defaults."
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = {}
}
