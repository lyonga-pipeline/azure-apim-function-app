# ---- Identity: the "one thing per root" --------------------------------------

variable "region" {
  description = "Azure region long name (e.g. centralus). Mapped to the approved short code."
  type        = string

  validation {
    condition = contains([
      "centralus", "eastus", "eastus2", "westus", "westus2", "westus3",
      "southcentralus", "northcentralus", "westcentralus",
      "canadacentral", "canadaeast",
      "uksouth", "ukwest", "westeurope", "northeurope",
    ], lower(trimspace(var.region)))
    error_message = "region is not on the approved list. Add it to the module (region_codes) via a versioned change, not ad hoc."
  }
}

variable "environment" {
  description = "Environment token: dev, test, uat, prod, sandbox, np1, np2, np3, or shared. shared is reserved for cross-environment governance objects."
  type        = string

  validation {
    condition     = contains(["dev", "test", "uat", "prod", "sandbox", "np1", "np2", "np3", "shared"], lower(trimspace(var.environment)))
    error_message = "environment must be one of: dev, test, uat, prod, sandbox, np1, np2, np3, shared."
  }
}

variable "scope" {
  description = "platform (a platform-tier root: management, connectivity, ...) or workload (a workload landing zone)."
  type        = string
  default     = "platform"

  validation {
    condition     = contains(["platform", "workload"], lower(trimspace(var.scope)))
    error_message = "scope must be platform or workload."
  }
}

variable "component" {
  description = "Platform-root discriminator (management, connectivity, identity, hybrid, governance, policy, ...). Required when scope = platform for the resource-group and per-component names."
  type        = string
  default     = null
}

variable "domain" {
  description = "Workload domain (internal-apps, external-apps, ...). Required when scope = workload. Also the MG / private-DNS / policy node token."
  type        = string
  default     = null
}

variable "appcode" {
  description = "Optional finer workload discriminator (e.g. orders), 1-9 letters. See README."
  type        = string
  default     = null

  validation {
    condition     = var.appcode == null ? true : can(regex("^[a-zA-Z]{1,9}$", var.appcode))
    error_message = "appcode must be 1-9 letters only (no digits, hyphens, or underscores) - it becomes the leading token in workload resource names, several of which (Key Vault, storage account) have their own tight character budgets on top of it."
  }
}

variable "abbreviation" {
  description = "Optional approved short discriminator override for Key Vault/storage names. See README."
  type        = string
  default     = null

  validation {
    condition     = var.abbreviation == null ? true : can(regex("^[a-zA-Z][a-zA-Z0-9]{0,9}$", trimspace(var.abbreviation)))
    error_message = "abbreviation must be 1-10 alphanumeric characters and start with a letter."
  }
}

variable "key_vault_name_token" {
  description = "Final token for the singular Key Vault name. Defaults to vault."
  type        = string
  default     = "vault"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]+(?:-[a-zA-Z0-9]+)*$", trimspace(var.key_vault_name_token)))
    error_message = "key_vault_name_token must contain alphanumeric segments separated by single hyphens."
  }
}

# ---- Instance keys: one list per keyed resource type the root deploys --------

variable "key_vault_keys" {
  description = "Map keys of the Key Vaults this root deploys. Output: key_vault_names."
  type        = list(string)
  default     = []
}

variable "storage_account_keys" {
  description = "Map keys of the storage accounts this root deploys. Output: storage_account_names."
  type        = list(string)
  default     = []
}

variable "user_assigned_identity_keys" {
  description = "Map keys of the user-assigned identities this root deploys. Output: user_assigned_identity_names."
  type        = list(string)
  default     = []
}

variable "nsg_keys" {
  description = "Map keys of the network security groups this root deploys. Output: nsg_names."
  type        = list(string)
  default     = []
}

variable "route_table_keys" {
  description = "Map keys of the route tables this root deploys. Output: route_table_names."
  type        = list(string)
  default     = []
}

variable "public_ip_keys" {
  description = "Map keys of the public IPs this root deploys. Output: public_ip_names."
  type        = list(string)
  default     = []
}

variable "private_endpoint_keys" {
  description = "Map keys of the private endpoints this root deploys. Output: private_endpoint_names."
  type        = list(string)
  default     = []
}

variable "network_interface_keys" {
  description = "Map keys of the NICs this root deploys. Output: network_interface_names."
  type        = list(string)
  default     = []
}

variable "load_balancer_keys" {
  description = "Map keys of the load balancers this root deploys. Output: load_balancer_names."
  type        = list(string)
  default     = []
}

variable "virtual_machine_keys" {
  description = "VM naming tokens after the environment, for example srv-dhcp-02. Output: virtual_machine_names."
  type        = list(string)
  default     = []
}

variable "disk_keys" {
  description = "Map keys of the managed disks this root deploys. Output: disk_names."
  type        = list(string)
  default     = []
}

variable "recovery_services_vault_keys" {
  description = "Map keys of the Recovery Services vaults this root deploys. Output: recovery_services_vault_names."
  type        = list(string)
  default     = []
}

variable "function_app_keys" {
  description = "Function App instance numbers (1-99). Output: function_app_names using the approved azfn pattern."
  type        = list(string)
  default     = []
}

variable "subnet_keys" {
  description = "Map keys of NON-reserved subnets this root deploys. Output: subnet_names. Reserved subnet names (GatewaySubnet, ...) are an Azure constant - do not pass them."
  type        = list(string)
  default     = []
}

# ---- Options ----------------------------------------------------------------

variable "storage_uniqueness" {
  description = "Seed for a 4-hex-char suffix on storage-account names (they must be globally unique). Pass the subscription ID. Empty = deterministic name, no suffix."
  type        = string
  default     = ""
}

variable "instance" {
  description = "Instance number for the single-VM name rows (firewall_vm, domain_controller_vm, cloudflare_connector), rendered zero-padded."
  type        = number
  default     = 1

  validation {
    condition     = var.instance >= 1 && var.instance <= 99
    error_message = "instance must be between 1 and 99."
  }
}

# ---- Compatibility inputs ----------------------------------------------------

variable "purpose" {
  description = "DEPRECATED for new callers - prefer nsg_keys/subnet_keys/load_balancer_keys. Legacy single-token discriminator (subnet / nsg / policy-initiative / load_balancer). Still the only way to set `policy_initiative`, which has no keyed equivalent."
  type        = string
  default     = null
}

variable "destination" {
  description = "DEPRECATED for new callers - prefer route_table_keys. Legacy route-table destination token."
  type        = string
  default     = null
}

variable "resource" {
  description = "DEPRECATED for new callers - prefer public_ip_keys/network_interface_keys/private_endpoint_keys. Legacy public-IP / NIC / PE discriminator."
  type        = string
  default     = null
}

variable "name" {
  description = "Workload name for the workload-subscription name (sub-workload-<name>-<env>-<region>)."
  type        = string
  default     = null
}

variable "policy" {
  description = "Policy name token for a policy-assignment name."
  type        = string
  default     = null
}

variable "policy_scope" {
  description = "Scope token for a policy-assignment name (e.g. prod, connectivity)."
  type        = string
  default     = null
}

variable "entra_domain" {
  description = "Entra ID security-group domain token (e.g. PLT). Rendered UPPERCASE."
  type        = string
  default     = null
}

variable "entra_role" {
  description = "Entra ID security-group role token (e.g. Admins). Case preserved."
  type        = string
  default     = null
}
