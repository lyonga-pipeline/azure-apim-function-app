# =============================================================================
# Inputs. `region` + `environment` are always required (almost every name uses
# them). Everything else is optional - a name whose tokens are not all supplied
# is returned as `null` so the consumer fails fast on a wrong reference rather
# than getting a malformed string.
# =============================================================================

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

variable "domain" {
  description = "Workload domain for MG / private DNS / policy names (e.g. internal-apps, security). Lowercased."
  type        = string
  default     = null
}

variable "purpose" {
  description = "Subnet / NSG / policy-initiative purpose token (e.g. hub, firewall, baseline). Lowercased."
  type        = string
  default     = null
}

variable "destination" {
  description = "Route table destination token (e.g. default, firewall, internet). Lowercased."
  type        = string
  default     = null
}

variable "resource" {
  description = "Public IP resource discriminator (e.g. fw, bastion, ergw). Lowercased."
  type        = string
  default     = null
}

variable "appcode" {
  description = "Application code for the Key Vault name (e.g. platform). Lowercased."
  type        = string
  default     = null
}

variable "name" {
  description = "Workload name for the workload-subscription name (e.g. apim). Lowercased."
  type        = string
  default     = null
}

variable "policy" {
  description = "Policy name token for a policy-assignment name (e.g. security). Lowercased."
  type        = string
  default     = null
}

variable "scope" {
  description = "Scope token for a policy-assignment name (e.g. prod, connectivity). Lowercased."
  type        = string
  default     = null
}

variable "instance" {
  description = "Instance number for firewall VMs / Cloudflare connectors, rendered zero-padded (fw-01)."
  type        = number
  default     = 1

  validation {
    condition     = var.instance >= 1 && var.instance <= 99
    error_message = "instance must be between 1 and 99."
  }
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
