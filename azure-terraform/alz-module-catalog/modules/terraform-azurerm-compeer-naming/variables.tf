# =============================================================================
# The naming module has ONE job: given a root's identity + the keys of the
# resources it deploys, return every name.
#
#   Identity  ->  scope (platform|workload) + component OR domain[/appcode]
#                 + region + environment
#   Instances ->  <resource>_keys = ["primary", "audit", ...]  per keyed type
#   Output    ->  <resource>_names = { primary = "...", audit = "..." }
#
# Pure utility: no providers, no resources. Any change to an ALREADY-PUBLISHED
# name is a BREAKING change - bump the module major version.
# =============================================================================

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
  description = "Environment token: prod | uat | test | dev | np | sandbox | shared."
  type        = string

  validation {
    condition     = contains(["prod", "uat", "test", "dev", "np", "sandbox", "shared"], lower(trimspace(var.environment)))
    error_message = "environment must be one of: prod, uat, test, dev, np, sandbox, shared."
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
  description = "Optional finer workload discriminator (e.g. orders). When set it becomes the leading token for workload resource names."
  type        = string
  default     = null
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
  description = "Map keys of the VMs this root deploys. Output: virtual_machine_names (key trailing digits -> instance number)."
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

# ---- Legacy single-token inputs (still used by MG / policy / Entra rows) -----

variable "purpose" {
  description = "Legacy single-token discriminator (subnet / nsg / policy-initiative). Prefer the *_keys inputs."
  type        = string
  default     = null
}

variable "destination" {
  description = "Legacy route-table destination token. Prefer route_table_keys."
  type        = string
  default     = null
}

variable "resource" {
  description = "Legacy public-IP / NIC / PE discriminator. Prefer the *_keys inputs."
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
